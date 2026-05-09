# frozen_string_literal: true

module SkillBench
  # Orchestrates the evaluation pipeline.
  #
  # Coordinates blind judging of baseline and context agent outputs,
  # then computes deltas and determines the final verdict.
  class EvaluationRunner
    # Runs the evaluation pipeline.
    #
    # @param task [String] The task description.
    # @param criteria [SkillBench::Criteria] The eval criteria.
    # @param skill_context [String] The skill context XML.
    # @param baseline_output [String] The baseline agent output.
    # @param context_output [String] The context agent output.
    # @return [Hash] Service response with report or error.
    def self.call(task:, criteria:, skill_context:, baseline_output:, context_output:)
      new(task:, criteria:, skill_context:, baseline_output:, context_output:).call
    end

    # @param task [String] The task description.
    # @param criteria [SkillBench::Criteria] The eval criteria.
    # @param skill_context [String] The skill context XML.
    # @param baseline_output [String] The baseline agent output.
    # @param context_output [String] The context agent output.
    def initialize(task:, criteria:, skill_context:, baseline_output:, context_output:)
      @task = task
      @criteria = criteria
      @skill_context = skill_context
      @baseline_output = baseline_output
      @context_output = context_output
    end

    # Orchestrates judging and delta computation.
    #
    # @return [Hash] Service response with report or error.
    def call
      baseline_judge = judge_run(baseline_output, '')
      return baseline_judge unless baseline_judge[:success]

      context_judge = judge_run(context_output, skill_context)
      return context_judge unless context_judge[:success]

      compute_deltas(baseline_judge, context_judge)
    rescue StandardError => e
      SkillBench::ErrorLogger.log_error(e, 'EvaluationRunner Error')
      { success: false, response: { error: { message: e.message } } }
    end

    private

    attr_reader :task, :criteria, :skill_context, :baseline_output, :context_output

    def judge_run(output, context)
      prompt_result = JudgePrompt.call(
        task: task,
        criteria: criteria,
        skill_context: context,
        agent_output: output
      )
      return prompt_result unless prompt_result[:success]

      Judge.call(prompt: prompt_result[:response][:prompt])
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
