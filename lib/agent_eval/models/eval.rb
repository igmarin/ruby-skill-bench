# frozen_string_literal: true

require 'json'
require 'pathname'

module AgentEval
  module Models
    # Represents an evaluation scenario
    class Eval
      attr_reader :name, :path, :task, :criteria, :source_code

      # @param name [String] Eval name
      # @param path [String] Path to eval directory
      # @param task [String] Task description from task.md
      # @param criteria [Hash] Criteria from criteria.json
      # @param source_code [String] Source code to evaluate
      def initialize(name:, path:, task: '', criteria: {}, source_code: '')
        @name = name
        @path = path
        @task = task
        @criteria = criteria
        @source_code = source_code
      end

      # Load an eval from a directory
      # @param dir_path [String] Path to eval directory
      # @return [AgentEval::Models::Eval] Loaded eval instance
      # @raise [Errno::ENOENT] if eval directory does not exist
      def self.load(dir_path)
        path = Pathname.new(dir_path)
        raise Errno::ENOENT, "Eval directory not found: #{dir_path}" unless path.exist?

        name = path.basename.to_s
        task = load_task(path)
        criteria = load_criteria(path)
        source_code = ''

        new(name: name, path: dir_path, task: task, criteria: criteria, source_code: source_code)
      end

      # Load task description from task.md
      # @param path [Pathname] Path to eval directory
      # @return [String] Task description or empty string if file doesn't exist
      def self.load_task(path)
        task_md = path.join('task.md')
        task_md.exist? ? File.read(task_md) : ''
      end

      # Load evaluation criteria from criteria.json
      # @param path [Pathname] Path to eval directory
      # @return [Hash] Parsed criteria or empty hash if file doesn't exist
      # @raise [RuntimeError] if JSON is malformed
      def self.load_criteria(path)
        criteria_json = path.join('criteria.json')
        return {} unless criteria_json.exist?

        begin
          JSON.parse(File.read(criteria_json), symbolize_names: true)
        rescue JSON::ParserError => e
          raise "Invalid JSON in #{criteria_json}: #{e.message}"
        end
      end

      private_class_method :load_task, :load_criteria
    end
  end
end
