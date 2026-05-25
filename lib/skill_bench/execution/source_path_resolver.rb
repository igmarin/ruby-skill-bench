# frozen_string_literal: true

require 'pathname'

module SkillBench
  module Execution
    # Resolves the source skill or workflow path for a given evaluation target.
    class SourcePathResolver
      # Resolves the source path using either an explicit override or the eval directory convention.
      #
      # @param eval_folder_path [String] Relative path to the eval directory.
      # @param skill_path [String, nil] Optional explicit override for the source directory.
      # @param skill_sources [Hash] Optional skill source name → directory path mapping for fallback.
      #   When provided and local resolution does not yield an existing path, each source is checked.
      # @return [String, nil] The resolved source path relative to the evaluator repo root, or nil if unmappable.
      # @example Infer a skill source path (NEW format):
      #   SkillBench::Execution::SourcePathResolver.call(
      #     eval_folder_path: 'evals/skills/rails-code-review/review-order'
      #   )
      #   # => "skills/rails-code-review"
      # @example Infer a skill source path (OLD format, returns category):
      #   SkillBench::Execution::SourcePathResolver.call(
      #     eval_folder_path: 'evals/skills/code-quality/rails-code-review/review-order'
      #   )
      #   # => "skills/code-quality/rails-code-review"
      def self.call(eval_folder_path:, skill_path: nil, skill_sources: {})
        return skill_path if skill_path && !skill_path.empty?

        segments = Pathname.new(eval_folder_path.to_s).each_filename.to_a

        local = resolve_skills_path(segments) || resolve_workflows_path(segments)

        unless local.nil? || skill_sources.empty?
          skill_name = extract_skill_name(segments)
          return local unless skill_name
          return local if skill_exists_at?(local)

          skill_sources.each_value do |source_path|
            candidate = find_skill_in_source(source_path, skill_name)
            return candidate if candidate
          end
        end

        local
      end

      # Extracts the skill name from the eval path segments.
      #
      # @param segments [Array<String>] Path segments
      # @return [String, nil] Skill name or nil
      def self.extract_skill_name(segments)
        index = segments.rindex('skills')
        return nil unless index

        remaining = segments[(index + 1)..]
        return nil if remaining.empty?

        remaining[0]
      end

      # Finds a skill directory within a source path by name.
      #
      # @param source_path [String] Root directory containing skill categories
      # @param skill_name [String] Name of the skill to find
      # @return [String, nil] Path to the skill directory or nil
      def self.find_skill_in_source(source_path, skill_name)
        return nil unless source_path && Dir.exist?(source_path)

        Dir.glob(File.join(source_path, '*')).each do |entry|
          next unless Dir.exist?(entry)

          candidate = File.join(entry, skill_name)
          return candidate if Dir.exist?(candidate) && File.exist?(File.join(candidate, 'SKILL.md'))
        end

        nil
      end

      private_class_method def self.resolve_skills_path(segments)
        return nil unless (index = segments.rindex('skills'))

        remaining = segments[(index + 1)..]
        resolve_old_format_skills(remaining) || resolve_new_format_skills(remaining)
      end

      private_class_method def self.resolve_old_format_skills(remaining)
        return nil unless remaining.size >= 3

        category = remaining[0]
        skill_name = remaining[1]
        "skills/#{category}/#{skill_name}"
      end

      private_class_method def self.resolve_new_format_skills(remaining)
        return nil unless remaining.size >= 1

        skill_name = remaining[0]
        "skills/#{skill_name}"
      end

      private_class_method def self.resolve_workflows_path(segments)
        return nil unless (index = segments.rindex('workflows'))

        workflow_name = segments[index + 1]
        "workflows/#{workflow_name}" if workflow_name
      end

      private_class_method def self.skill_exists_at?(path)
        return false unless path

        full_path = path.end_with?('SKILL.md') ? path : File.join(path, 'SKILL.md')
        File.exist?(full_path)
      end
    end
  end
end
