# frozen_string_literal: true

require_relative 'task_file_reader'
require_relative '../context_hydrator'
require_relative '../react_agent'
require_relative 'sandbox'
require_relative 'judge'
require_relative 'agent_runner'
require_relative 'source_path_resolver'

module Evaluator
  # Evaluates a single task by running baseline and context-hydrated evaluations.
  # Orchestrates AgentRunner calls and Judge scoring.
  class TaskEvaluator
    SEPARATOR = '================================================='

    # Evaluates a single task.
    #
    # @param full_eval_path [Pathname] The path to the evaluation directory.
    # @param base_path [Pathname] The base path for relative file resolution.
    # @param skill_path [String, nil] Optional override for the source directory.
    # @param client_params [Hash] Parameters to pass to the LLM client.
    # @return [Hash] The result of the task evaluation.
    def self.call(full_eval_path:, base_path:, skill_path: nil, client_params: {})
      new(full_eval_path:, base_path:, skill_path:, client_params:).call
    end

    # @param full_eval_path [Pathname] The path to the evaluation directory.
    # @param base_path [Pathname] The base path for relative file resolution.
    # @param skill_path [String, nil] Optional override for the source directory.
    # @param client_params [Hash] Parameters to pass to the LLM client.
    def initialize(full_eval_path:, base_path:, skill_path:, client_params:)
      @full_eval_path = full_eval_path
      @base_path = base_path
      @skill_path = skill_path
      @client_params = client_params
    end

    # Executes the task evaluation.
    #
    # @return [Hash] The result of the task evaluation.
    def call
      relative_path = @full_eval_path.relative_path_from(@base_path)
      relative_path_str = relative_path.to_s

      files_result = TaskFileReader.call(@full_eval_path)
      return files_result unless files_result[:success]

      files_response = files_result[:response]
      task_content = files_response[:task]
      criteria_content = files_response[:criteria]

      source_path = SourcePathResolver.call(
        eval_folder_path: relative_path_str,
        skill_path: @skill_path
      )

      baseline_result, baseline_code_diff = AgentRunner.call(
        mode: :baseline,
        full_eval_path: @full_eval_path,
        task_content: task_content,
        client_params: @client_params
      )

      context_result, context_code_diff = if source_path
                                            AgentRunner.call(
                                              mode: :context,
                                              full_eval_path: @full_eval_path,
                                              task_content: task_content,
                                              client_params: @client_params,
                                              source_path: source_path,
                                              base_path: @base_path
                                            )
                                          else
                                            { success: false, response: { error: { message: 'No source path inferred' } } }
                                          end

      judge_score = if source_path
                      Judge.call(task_content, criteria_content, baseline_code_diff, context_code_diff, @client_params)
                    else
                      { success: false, response: { error: { message: 'No source path - judge skipped' } } }
                    end

      # Propagate Judge failures
      return judge_score unless judge_score[:success]

      {
        path: relative_path_str,
        baseline: baseline_result,
        baseline_diff: baseline_code_diff,
        with_context: context_result,
        context_diff: context_code_diff,
        judge_score: judge_score
      }
    rescue StandardError => e
      { success: false, response: { error: { message: "Error evaluating task: #{e.message}" } } }
    end
  end
end
