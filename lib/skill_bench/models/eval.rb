# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative '../criteria'

module SkillBench
  module Models
    # Represents an evaluation scenario
    class Eval
      attr_reader :name, :path, :task, :criteria, :source_code, :metadata

      # @param name [String] Eval name
      # @param path [String] Path to eval directory
      # @param task [String] Task description from task.md
      # @param criteria [Hash] Criteria from criteria.json
      # @param source_code [String] Source code to evaluate
      # @param metadata [Hash] Metadata from metadata.json
      def initialize(name:, path:, task: '', criteria: {}, source_code: '', metadata: {})
        @name = name
        @path = path
        @task = task
        @criteria = criteria
        @source_code = source_code
        @metadata = metadata
      end

      # Load an eval from a directory
      # @param dir_path [String] Path to eval directory
      # @return [SkillBench::Models::Eval] Loaded eval instance
      # @raise [Errno::ENOENT] if eval directory does not exist
      def self.load(dir_path)
        path = Pathname.new(dir_path)
        raise Errno::ENOENT, "Eval directory not found: #{dir_path}" unless path.exist?

        name = path.basename.to_s
        task = load_task(path)
        criteria = load_criteria(path)
        metadata = load_metadata(path)

        new(name: name, path: dir_path, task: task, criteria: criteria, metadata: metadata)
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
      # @return [SkillBench::Criteria] Parsed criteria or empty criteria if file doesn't exist
      # @raise [RuntimeError] if JSON is malformed or criteria validation fails
      def self.load_criteria(path)
        criteria_json = path.join('criteria.json')
        return SkillBench::Criteria.empty unless criteria_json.exist?

        result = SkillBench::Criteria.call(path: criteria_json.to_s)
        response = result[:response]
        return response[:criteria] if result[:success]

        raise "Failed to load criteria: #{response[:error][:message]}"
      end

      # Load metadata from metadata.json
      # @param path [Pathname] Path to eval directory
      # @return [Hash] Parsed metadata or empty hash if file doesn't exist
      # @raise [JSON::ParserError] if JSON is malformed
      def self.load_metadata(path)
        metadata_file = path.join('metadata.json')
        return {} unless metadata_file.exist?

        JSON.parse(File.read(metadata_file))
      end

      private_class_method :load_task, :load_criteria, :load_metadata
    end
  end
end
