# frozen_string_literal: true

require 'securerandom'

module SkillBench
  module Judge
    # Builds structured prompts for the LLM judge.
    #
    # Assembles task description, evaluation criteria, skill context,
    # and agent output into a single prompt for blind scoring. Untrusted
    # content (task, skill context, and agent output) is wrapped in per-run
    # random sentinel fences and stripped of that sentinel, so embedded text
    # cannot forge a boundary and inject instructions into the judge.
    class Prompt
      # Byte length of the per-run sentinel; SecureRandom.hex yields 2x hex chars.
      SENTINEL_BYTES = 16

      # Builds the judge prompt.
      #
      # @param task [String] The task description from task.md.
      # @param criteria [SkillBench::Criteria] The eval criteria with dimensions.
      # @param skill_context [String, nil] XML-wrapped skill context (nil for baseline runs).
      # @param agent_output [String] Git diff and agent summary.
      # @return [Hash] Service response with prompt or error.
      def self.call(task:, criteria:, skill_context:, agent_output:)
        new(task:, criteria:, skill_context:, agent_output:).call
      end

      # @param task [String] The task description.
      # @param criteria [SkillBench::Criteria] The eval criteria.
      # @param skill_context [String, nil] The skill context XML (nil for baseline runs).
      # @param agent_output [String] The agent output.
      def initialize(task:, criteria:, skill_context:, agent_output:)
        @task = task
        @criteria = criteria
        @skill_context = skill_context
        @agent_output = agent_output
        @sentinel = SecureRandom.hex(SENTINEL_BYTES)
      end

      # Assembles and returns the judge prompt.
      #
      # @return [Hash] Service response with prompt or error.
      def call
        return missing_task_result if task.nil? || task.strip.empty?
        return missing_criteria_result if criteria.nil?
        return missing_agent_output_result if agent_output.nil? || agent_output.to_s.strip.empty?
        return missing_skill_context_result unless valid_skill_context?

        prompt = assemble_prompt
        { success: true, response: { prompt: prompt } }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Judge::Prompt Build Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      attr_reader :task, :criteria, :skill_context, :agent_output, :sentinel

      def missing_task_result
        { success: false, response: { error: { message: 'Task is required' } } }
      end

      def missing_criteria_result
        { success: false, response: { error: { message: 'Criteria is required' } } }
      end

      def missing_agent_output_result
        { success: false, response: { error: { message: 'Agent output is required' } } }
      end

      def missing_skill_context_result
        { success: false, response: { error: { message: 'Skill context is required' } } }
      end

      def valid_skill_context?
        return true if skill_context.nil?

        skill_context.is_a?(String) && !skill_context.strip.empty?
      end

      def assemble_prompt
        sections = [
          task_section,
          criteria_section,
          skill_context_section,
          agent_output_section,
          instructions_section
        ].compact

        sections.join("\n\n")
      end

      def task_section
        "## Task\n\n#{fence('TASK', task)}"
      end

      def criteria_section
        lines = ['## Criteria']
        lines << "\nContext: #{criteria.context}"
        lines << "\nDimensions:"

        criteria.dimensions.each do |dim|
          lines << "- #{dim.name}: max_score=#{dim.max_score}, description=#{dim.description}"
        end

        lines.join("\n")
      end

      def skill_context_section
        return nil if skill_context.nil?

        "## Skill Context\n\n#{fence('SKILL_CONTEXT', skill_context)}"
      end

      def agent_output_section
        "## Agent Output\n\n#{fence('AGENT_OUTPUT', agent_output)}"
      end

      # Wraps untrusted content in a per-run sentinel fence it cannot forge.
      #
      # The closing marker carries a random per-run sentinel and that sentinel
      # is stripped from the content, so embedded text can neither reproduce the
      # boundary nor inject instructions outside its section.
      #
      # @param label [String] The fence label, e.g. "AGENT_OUTPUT".
      # @param content [String] The untrusted content to wrap.
      # @return [String] The fenced, neutralized content.
      def fence(label, content)
        [
          "<<#{label} #{sentinel}>>",
          neutralize(content),
          "<<END_#{label} #{sentinel}>>"
        ].join("\n")
      end

      # Removes every occurrence of the run sentinel from untrusted content.
      #
      # @param content [String] The untrusted content.
      # @return [String] The content with the sentinel stripped out.
      def neutralize(content)
        content.to_s.gsub(sentinel, '')
      end

      def instructions_section
        <<~INSTRUCTIONS
          ## Instructions

          Score each dimension independently. Return JSON with:
          - "dimensions": object mapping each dimension name to { "score": number, "max_score": number, "reasoning": string }
          - "overall_reasoning": string summarizing the evaluation
        INSTRUCTIONS
      end
    end
  end
end
