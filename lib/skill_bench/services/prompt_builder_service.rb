# frozen_string_literal: true

require 'pathname'
require_relative '../execution/context_hydrator'
require_relative '../execution/source_path_resolver'

module SkillBench
  module Services
    # Builds system prompts for baseline and context agent runs.
    class PromptBuilderService
      # Builds the baseline system prompt (no skill context).
      #
      # @return [String] The baseline system prompt
      def self.build_baseline
        new.build_baseline
      end

      # Builds the context-aware system prompt based on eval metadata.
      #
      # For `skill_bundle_xml` context mode, combines SKILL.md with source code
      # via ContextHydrator. Falls back to SKILL.md-only if source is unavailable.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param skills [Array<SkillBench::Models::Skill>] Resolved skills
      # @param skill_context [String] The combined skill context from SKILL.md files
      # @return [String] The context system prompt
      def self.build_context(evaluation, skills, skill_context)
        new.build_context(evaluation, skills, skill_context)
      end

      # Builds the baseline system prompt (no skill context).
      #
      # @return [String] The baseline system prompt
      def build_baseline
        <<~PROMPT
          You are an expert Ruby on Rails developer. Your job is to read the task,
          modify the codebase using the tools provided to meet the requirements,
          and then explain what you did.
        PROMPT
      end

      # Builds the context-aware system prompt based on eval metadata.
      #
      # For `skill_bundle_xml` context mode, combines SKILL.md with source code
      # via ContextHydrator. Falls back to SKILL.md-only if source is unavailable.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param _skills [Array<SkillBench::Models::Skill>] Resolved skills (unused in current implementation)
      # @param skill_context [String] The combined skill context from SKILL.md files
      # @return [String] The context system prompt
      def build_context(evaluation, _skills, skill_context)
        return skill_context unless evaluation.metadata['context_mode'] == 'skill_bundle_xml'

        source_path = resolve_source_path(evaluation)
        return skill_context unless source_path

        xml_result = Execution::ContextHydrator.call(source_path: source_path, base_path: Pathname.new(Dir.pwd))
        hydrator_response = xml_result[:response]
        xml_context = hydrator_response[:context]
        return skill_context unless xml_result[:success] && !xml_context.empty?

        <<~PROMPT
          You are an expert Ruby on Rails developer.
          You have access to a skill file and source code wrapped in <agent_context> tags.
          Use the skill instructions and the provided source code to solve the task.

          ## Skill Instructions
          #{skill_context}

          ## Source Code
          #{xml_context}
        PROMPT
      end

      private

      # Resolves the source path for context hydration.
      #
      # Tries the eval's `source/` subdirectory first, then falls back to
      # SourcePathResolver inference.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @return [String, nil] The resolved source path, or nil if not found
      def resolve_source_path(evaluation)
        eval_path = evaluation.path
        eval_source = File.join(eval_path, 'source')
        return eval_source if Dir.exist?(eval_source)

        sources = SkillBench::Config.skill_sources || {}
        inferred = Execution::SourcePathResolver.call(
          eval_folder_path: eval_path.to_s,
          skill_sources: sources
        )
        inferred if inferred && Dir.exist?(inferred)
      end
    end
  end
end
