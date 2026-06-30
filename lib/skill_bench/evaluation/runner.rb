# frozen_string_literal: true

require 'parallel'

module SkillBench
  module Evaluation
    # Orchestrates the evaluation pipeline.
    #
    # Coordinates blind judging of baseline and context agent outputs,
    # then computes deltas and determines the final verdict.
    class Runner
      # Runs the evaluation pipeline.
      #
      # @param task [String] The task description.
      # @param criteria [SkillBench::Criteria] The eval criteria.
      # @param skill_context [String] The skill context XML.
      # @param baseline_output [String] The baseline agent output.
      # @param context_output [String] The context agent output.
      # @param judge_params [Hash] Provider config passed to the Judge as client_params (api_key, model, provider).
      # @return [Hash] Service response with report or error.
      def self.call(task:, criteria:, skill_context:, baseline_output:, context_output:, judge_params: {})
        new(task:, criteria:, skill_context:, baseline_output:, context_output:, judge_params:).call
      end

      # @param task [String] The task description.
      # @param criteria [SkillBench::Criteria] The eval criteria.
      # @param skill_context [String] The skill context XML.
      # @param baseline_output [String] The baseline agent output.
      # @param context_output [String] The context agent output.
      # @param judge_params [Hash] Provider config passed to the Judge as client_params.
      def initialize(task:, criteria:, skill_context:, baseline_output:, context_output:, judge_params: {})
        @task = task
        @criteria = criteria
        @skill_context = skill_context
        @baseline_output = baseline_output
        @context_output = context_output
        @judge_params = judge_params.is_a?(Hash) ? judge_params : {}
      end

      # Orchestrates judging and delta computation.
      #
      # @return [Hash] Service response with report or error.
      def call
        baseline_judge, context_judge = run_judges_concurrently
        return baseline_judge unless baseline_judge[:success]
        return context_judge unless context_judge[:success]

        compute_deltas(baseline_judge, context_judge)
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Evaluation::Runner Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      attr_reader :task, :criteria, :skill_context, :baseline_output, :context_output, :judge_params

      # Judges the baseline and context outputs concurrently.
      #
      # The two runs are independent blind evaluations that share no mutable
      # state, so they execute on separate threads (the LLM round-trip is
      # I/O-bound and releases the GIL). +Parallel.map+ preserves input order,
      # so the baseline result is always first and the context result second;
      # callers still apply the sequential failure precedence afterwards.
      #
      # @return [Array(Hash, Hash)] Baseline and context judge results, in order.
      def run_judges_concurrently
        runs = [
          -> { judge_run(baseline_output, nil) },
          -> { judge_run(context_output, skill_context) }
        ]
        Parallel.map(runs, in_threads: runs.size, &:call)
      end

      def judge_run(output, context)
        prompt_result = Judge::Prompt.call(
          task: task,
          criteria: criteria,
          skill_context: context,
          agent_output: output
        )
        return prompt_result unless prompt_result[:success]

        Judge::Judge.call(prompt: prompt_result[:response][:prompt], client_params: judge_params)
      end

      def compute_deltas(baseline_judge, context_judge)
        baseline_dims = baseline_judge[:response][:judge_response].dimensions
        context_dims = context_judge[:response][:judge_response].dimensions

        delta_result = DeltaReport.call(baseline: baseline_dims, context: context_dims, criteria: criteria)
        return delta_result unless delta_result[:success]

        { success: true, response: { report: delta_result[:response][:delta_report] } }
      end
    end
  end
end
