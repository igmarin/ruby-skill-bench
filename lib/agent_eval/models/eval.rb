# frozen_string_literal: true

require "json"
require "pathname"

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
      def initialize(name:, path:, task: "", criteria: {}, source_code: "")
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
        task = path.join("task.md").exist? ? File.read(path.join("task.md")) : ""
        criteria = path.join("criteria.json").exist? ? JSON.parse(File.read(path.join("criteria.json")), symbolize_names: true) : {}
        source_code = ""

        new(name: name, path: dir_path, task: task, criteria: criteria, source_code: source_code)
      end
    end
  end
end
