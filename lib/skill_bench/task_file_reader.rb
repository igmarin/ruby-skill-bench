# frozen_string_literal: true

require 'pathname'
require_relative 'error_logger'

module SkillBench
  # Reads task.md and criteria.json files for an evaluation task.
  # Returns structured responses following service object contract.
  class TaskFileReader
    # Reads the task and criteria files from the given evaluation path.
    #
    # @param full_eval_path [Pathname] The path to the evaluation directory.
    # @return [Hash] with :success [Boolean] and :response containing file contents or error.
    def self.call(full_eval_path)
      new(full_eval_path).call
    end

    # @param full_eval_path [Pathname] The path to the evaluation directory.
    def initialize(full_eval_path)
      @full_eval_path = full_eval_path
    end

    # Reads task.md and criteria.json files.
    #
    # @return [Hash] with :success [Boolean] and :response containing file contents or error.
    def call
      task_content = read_file('task.md')
      return task_content unless task_content[:success]

      criteria_content = read_file('criteria.json')
      return criteria_content unless criteria_content[:success]

      {
        success: true,
        response: {
          task: task_content[:response][:content],
          criteria: criteria_content[:response][:content]
        }
      }
    rescue StandardError => e
      Evaluator::ErrorLogger.log_error(e, 'TaskFileReader Error')
      { success: false, response: { error: { message: "Error reading task files: #{e.message}" } } }
    end

    private

    # Reads a single file from the evaluation path.
    #
    # @param filename [String] The name of the file to read.
    # @return [Hash] with :success [Boolean] and :response containing content or error.
    def read_file(filename)
      file_path = @full_eval_path.join(filename)
      unless file_path.exist?
        return {
          success: false,
          response: { error: { message: "File not found: #{file_path}" } }
        }
      end

      content = File.read(file_path)
      { success: true, response: { content: content } }
    rescue StandardError => e
      Evaluator::ErrorLogger.log_error(e, "TaskFileReader##{filename} Error")
      { success: false, response: { error: { message: "Error reading #{filename}: #{e.message}" } } }
    end
  end
end
