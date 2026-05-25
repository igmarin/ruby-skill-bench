# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative '../models/eval'
require_relative '../models/skill'
require_relative '../models/config'
require_relative '../models/provider'
require_relative '../clients/all'
require_relative 'skill_resolver'
require_relative '../trend_tracker'
require_relative '../execution/sandbox'
require_relative '../execution/context_hydrator'
require_relative '../execution/source_path_resolver'
require_relative '../registry/pack_resolver'
require_relative '../agent/react_agent'

module SkillBench
  module Services
    # Orchestrates the execution of an eval with baseline and context runs.
    class RunnerService
      # Stand-in provider when no LLM config is available.
      MOCK_PROVIDER = Struct.new(:name, :runtime, :llm, :merged_config)
      private_constant :MOCK_PROVIDER

      # Default registry manifest path relative to the current working directory.
      DEFAULT_REGISTRY_MANIFEST = '../agent-mcp-runtime/registry.json'
      private_constant :DEFAULT_REGISTRY_MANIFEST

      # Runs an eval with the given parameters.
      #
      # @param eval_name [String] Name or path of the eval to run
      # @param skill_names [Array<String>] Names of the skills to use
      # @param pack [String, nil] Optional pack name for registry-based skill resolution
      # @param registry_manifest [String, nil] Optional path to registry.json manifest
      # @return [Hash] Result from EvaluationRunner
      def self.call(eval_name:, skill_names:, pack: nil, registry_manifest: nil)
        new(
          eval_name: eval_name,
          skill_names: skill_names,
          pack: pack,
          registry_manifest: registry_manifest
        ).call
      end

      # @param eval_name [String] Name or path of the eval
      # @param skill_names [Array<String>] Names of the skills
      # @param pack [String, nil] Optional pack name
      # @param registry_manifest [String, nil] Optional registry.json path
      def initialize(eval_name:, skill_names:, pack: nil, registry_manifest: nil)
        @eval_name = eval_name
        @skill_names = skill_names
        @pack = pack
        @registry_manifest = registry_manifest
      end

      # Executes the eval: resolves entities, runs baseline and context, evaluates.
      #
      # @return [Hash] Evaluation result with deltas and verdict.
      # @raise [Errno::ENOENT] when the eval directory does not exist.
      # @raise [ArgumentError] when a skill cannot be resolved.
      def call
        evaluation = resolve_eval
        skills = resolve_skills
        provider = resolve_provider

        config_result = resolve_provider_config(provider)
        return config_error_result(config_result[:error], evaluation, provider) unless config_result[:success]

        config = config_result[:config]
        baseline_prompt = build_baseline_system_prompt

        baseline_output = spawn_agent(evaluation, baseline_prompt, provider, config)
        return agent_error_result(baseline_output, 'baseline', evaluation, provider) if baseline_output[:status] == :error

        skill_context = load_combined_skill_context(skills)
        return empty_context_error_result(evaluation, provider) if skill_context.strip.empty?

        context_prompt = build_context_system_prompt(evaluation, skills)
        context_output = spawn_agent(evaluation, context_prompt, provider, config)
        return agent_error_result(context_output, 'context', evaluation, provider) if context_output[:status] == :error

        criteria = evaluation.criteria

        judge_params = build_judge_params(provider, config)

        result = Evaluation::Runner.call(
          task: evaluation.task,
          criteria: criteria,
          skill_context: skill_context,
          baseline_output: format_output(baseline_output),
          context_output: format_output(context_output),
          judge_params: judge_params
        )

        return enrich_error_result(result, evaluation, provider) unless result[:success]

        trend_result = record_and_compute_trend(result)
        return enrich_error_result(trend_result, evaluation, provider) unless trend_result[:success]

        {
          success: true,
          eval_name: eval_name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name,
          response: result[:response].merge(
            trend: trend_result[:trend],
            baseline_iterations: baseline_output[:iterations] || [],
            context_iterations: context_output[:iterations] || []
          )
        }
      end

      private

      attr_reader :eval_name, :skill_names, :pack, :registry_manifest

      def resolve_eval
        eval_path = eval_name.include?('/') ? eval_name : "evals/#{eval_name}"
        SkillBench::Models::Eval.load(eval_path)
      end

      def resolve_skills
        return @resolve_skills if defined?(@resolve_skills)

        @resolve_skills = if pack && !pack.empty?
                            resolve_pack_skills
                          else
                            skill_names.map { |name| Services::SkillResolver.call(name) }
                          end
      end

      def resolve_pack_skills
        manifest_path = registry_manifest || DEFAULT_REGISTRY_MANIFEST
        manifest_absolute = File.expand_path(manifest_path, Dir.pwd)

        raise ArgumentError, "Registry manifest not found: #{manifest_path}" unless File.exist?(manifest_absolute)

        resolver = Registry::PackResolver.new(manifest_absolute)

        skill_names.map do |skill_name|
          path = resolver.resolve_skill(pack, skill_name)
          raise ArgumentError, "Skill '#{skill_name}' not found in pack '#{pack}'" unless path

          Models::Skill.new(name: skill_name, path: path)
        end
      end

      def resolve_provider_config(provider)
        { success: true, config: provider.merged_config }
      rescue ArgumentError => e
        { success: false, error: e }
      end

      # Safely calls merged_config, returning nil on any error.
      #
      # @param provider [Object] The provider to query.
      # @return [Hash, nil] The merged config or nil.
      def safe_merged_config(provider)
        provider.merged_config
      rescue StandardError
        nil
      end

      def resolve_provider
        config = SkillBench::Models::Config.load
        provider = config.to_provider
        return provider if provider

        warn 'Config load failed, using mock provider'
        MOCK_PROVIDER.new('mock', 'mock', 'mock', {})
      end

      # Spawns the LLM agent with the given system prompt.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run.
      # @param system_prompt [String] The system prompt for the agent.
      # @param provider [Object] The resolved provider.
      # @param config [Hash, nil] Provider config.
      # @return [Hash] Agent response with result, status, runtime, usage, raw_response, iterations.
      def spawn_agent(evaluation, system_prompt, provider, config)
        return { result: 'mock result', status: :success, iterations: [] } if provider.name == 'mock'

        client_params = build_client_params(provider, config)

        max_iterations = config&.[](:max_iterations) || config&.[]('max_iterations') || 25

        Execution::Sandbox.run(evaluation.path) do |sandbox|
          agent_result = Agent::ReactAgent.call(
            system_prompt: system_prompt,
            initial_prompt: evaluation.task,
            working_dir: sandbox.path,
            container_id: sandbox.container_id,
            client_params: client_params,
            max_iterations: max_iterations
          )

          status = agent_result[:success] ? :success : :error
          final_answer = agent_result.dig(:response, :content) || ''
          diff = Execution::Sandbox.capture_diff(sandbox.path)
          iterations = agent_result.dig(:response, :iterations) || []

          output = [final_answer, diff].reject(&:empty?).join("\n\n")

          {
            result: output,
            status: status,
            runtime: provider.runtime,
            usage: {},
            raw_response: agent_result,
            iterations: iterations
          }
        end
      end

      # Builds client parameters for the ReactAgent.
      #
      # @param provider [Object] The resolved provider.
      # @param config [Hash, nil] Provider config.
      # @return [Hash] Client parameters.
      def build_client_params(provider, config)
        config ||= safe_merged_config(provider)
        return {} unless config

        params = config.dup
        params[:model] ||= provider.llm
        params[:provider] = provider.runtime.to_sym
        params
      rescue StandardError
        {}
      end

      # Builds the baseline system prompt (no skill context).
      #
      # @return [String] The baseline system prompt.
      def build_baseline_system_prompt
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
      # @param evaluation [SkillBench::Models::Eval] The eval being run.
      # @param skills [Array<SkillBench::Models::Skill>] Resolved skills.
      # @return [String] The context system prompt.
      def build_context_system_prompt(evaluation, skills)
        skill_md_content = load_combined_skill_context(skills)
        return skill_md_content unless evaluation.metadata['context_mode'] == 'skill_bundle_xml'

        source_path = resolve_source_path(evaluation)
        return skill_md_content unless source_path

        xml_result = Execution::ContextHydrator.call(source_path: source_path, base_path: Pathname.new(Dir.pwd))
        hydrator_response = xml_result[:response]
        xml_context = hydrator_response[:context]
        return skill_md_content unless xml_result[:success] && !xml_context.empty?

        <<~PROMPT
          You are an expert Ruby on Rails developer.
          You have access to a skill file and source code wrapped in <agent_context> tags.
          Use the skill instructions and the provided source code to solve the task.

          ## Skill Instructions
          #{skill_md_content}

          ## Source Code
          #{xml_context}
        PROMPT
      end

      # Resolves the source path for context hydration.
      #
      # Tries the eval's `source/` subdirectory first, then falls back to
      # SourcePathResolver inference.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run.
      # @return [String, nil] The resolved source path, or nil if not found.
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

      # Returns an error result when skill context is empty.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run.
      # @param provider [Object] The resolved provider.
      # @return [Hash] Error result with metadata.
      def empty_context_error_result(evaluation, provider)
        {
          success: false,
          response: {
            error: {
              message: 'Skill context is empty. Ensure SKILL.md exists and has content.'
            }
          },
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        }
      end

      def load_combined_skill_context(skills)
        return '' if skills.nil? || skills.empty?

        contexts = skills.map { |skill| load_skill_context(skill) }
        contexts.reject(&:empty?).join("\n\n#{'=' * 40}\n\n")
      end

      def load_skill_context(skill)
        skill_md = File.join(skill.path, 'SKILL.md')
        File.exist?(skill_md) ? File.read(skill_md) : ''
      end

      def build_judge_params(provider, config)
        return {} if provider.name == 'mock'

        config ||= safe_merged_config(provider)
        return {} unless config

        {
          api_key: config[:api_key],
          model: config[:model] || provider.llm,
          provider: provider.runtime.to_sym
        }
      rescue StandardError
        {}
      end

      def format_output(agent_result)
        agent_result[:result].to_s
      end

      def agent_error_result(result, phase, evaluation, provider)
        raw = result[:raw_response]
        error_msg = raw&.dig(:response, :error, :message) || raw&.dig(:error, :message) || 'unknown error'
        {
          success: false,
          response: {
            error: {
              message: "#{phase.capitalize} agent failed: #{error_msg}"
            }
          },
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        }
      end

      def config_error_result(error, evaluation, provider)
        {
          success: false,
          response: {
            error: {
              message: "Configuration error: #{error.message}"
            }
          },
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        }
      end

      def enrich_error_result(result, evaluation, provider)
        result.merge(
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        )
      end

      def record_and_compute_trend(result)
        tracker = TrendTracker.new
        enriched = result.merge(eval_name: eval_name, skill_names: skill_names)
        trend = tracker.trend_for(enriched)
        record_result = tracker.record(enriched)

        record_success = record_result.is_a?(Hash) && record_result[:success]
        unless record_success
          message = if record_result.is_a?(Hash)
                      record_result.dig(:response, :error, :message) ||
                        record_result.dig(:error, :message) ||
                        'Unknown error'
                    else
                      'Unexpected record response'
                    end
          SkillBench::ErrorLogger.log_error(
            StandardError.new(message),
            "Trend tracking record failed for eval #{eval_name}"
          )
          return {
            success: false,
            response: {
              error: {
                message: "Trend tracking record failed: #{message}",
                record_result: record_result
              }
            }
          }
        end
        { success: true, trend: trend }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Trend tracking failed')
        { success: false, response: { error: { message: e.message } } }
      end
    end
  end
end
