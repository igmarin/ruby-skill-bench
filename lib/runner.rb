# frozen_string_literal: true

require 'pathname'
require 'parallel'
require_relative 'evaluator/task_evaluator'

module Evaluator
  # Orchestrates the entire evaluation process.
  # Compares how an AI coding agent performs with and without contextual skills.
  class Runner
    # Initiates a full evaluation run.
    #
    # @param params [Hash] The configuration for the evaluation.
    # @option params [String] :eval_folder_path The path to the evaluation directory containing task and criteria.
    # @option params [String] :skill_path Optional override for the source directory being tested.
    # @option params [String, Pathname] :base_path (optional) The base path for relative file resolution.
    # @option params [Hash] :client_params (optional) Parameters to pass to the LLM client.
    # @return [Hash] A result hash with :success and :response payload containing the judge scores and diffs.
    # @raise [ArgumentError] If the eval path does not match a supported source-path convention.
    def self.call(params)
      new(params).call
    end

    # @param params [Hash] The configuration for the evaluation.
    def initialize(params)
      @eval_folder_path = params[:eval_folder_path]
      @skill_path = params[:skill_path]
      @base_path = params[:base_path] || Pathname.new(Dir.pwd)
      @client_params = params[:client_params] || {}
    end

    # Executes the baseline and context-hydrated evaluations, then scores them.
    #
    # @return [Hash] The final evaluation result.
    def call
      full_path = @base_path.join(@eval_folder_path)

      return { success: false, response: { error: { message: "Evaluation path #{full_path} does not exist" } } } unless full_path.exist?

      task_dirs = self.class.discover_task_dirs(full_path)
      if task_dirs.empty?
        return { success: false,
                 response: { error: { message: "No task.md found in #{full_path} or its subdirectories" } } }
      end

      results = Parallel.map(task_dirs, in_threads: 4) do |task_dir|
        task_result = TaskEvaluator.call(
          full_eval_path: task_dir,
          base_path: @base_path,
          skill_path: @skill_path,
          client_params: @client_params
        )
        # Normalize to uniform envelope
        if task_result.key?(:success)
          task_result
        else
          { success: true, response: task_result }
        end
      end

      overall_success = results.all? { |task_result| task_result[:success] }

      {
        success: overall_success,
        response: {
          source_path: @skill_path || 'multiple (batch run)',
          tasks: results
        }
      }
    rescue StandardError => e
      { success: false, response: { error: { message: e.message } } }
    end

    # Finds all directories containing a task.md file starting from the root_path.
    #
    # @param root_path [Pathname] The root directory to search.
    # @return [Array<Pathname>] A list of task directory paths.
    def self.discover_task_dirs(root_path)
      if File.exist?(root_path.join('task.md'))
        [root_path]
      else
        Dir.glob(root_path.join('**/task.md')).map { |f| Pathname.new(f).parent }.uniq.sort
      end
    end
  end
end
