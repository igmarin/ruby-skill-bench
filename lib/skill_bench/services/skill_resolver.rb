# frozen_string_literal: true

require_relative '../models/skill'

module SkillBench
  module Services
    # Resolves a skill identifier to a Skill model instance.
    # Supports both direct paths (containing '/') and skill names (searched recursively).
    class SkillResolver
      # Resolves a skill identifier to a Skill instance.
      #
      # @param identifier [String] Skill path or name
      # @param base_path [String] Base directory for skill discovery (default: 'skills/')
      # @return [SkillBench::Models::Skill] The resolved skill
      # @raise [ArgumentError] if skill not found
      def self.call(identifier, base_path = 'skills/')
        new(identifier, base_path).call
      end

      # @param identifier [String] Skill path or name
      # @param base_path [String] Base directory for skill discovery
      def initialize(identifier, base_path = 'skills/')
        @identifier = identifier
        @base_path = base_path
      end

      # Resolves the skill identifier.
      #
      # @return [SkillBench::Models::Skill] The resolved skill
      # @raise [ArgumentError] if skill not found
      def call
        return resolve_by_path if identifier.include?('/')

        resolve_by_name
      end

      private

      attr_reader :identifier, :base_path

      # Resolves a skill by direct file path.
      #
      # @return [SkillBench::Models::Skill] The resolved skill
      # @raise [ArgumentError] if skill file not found at path or path escapes project boundary
      def resolve_by_path
        normalized_path = identifier.end_with?('SKILL.md') ? File.dirname(identifier) : identifier
        absolute_path = File.expand_path(normalized_path)
        cwd = File.expand_path(Dir.pwd)
        cwd_with_sep = cwd + File::SEPARATOR

        allowed = absolute_path == cwd || absolute_path.start_with?(cwd_with_sep)
        unless allowed
          sources = SkillBench::Config.skill_sources
          if sources.is_a?(Hash)
            sources.each_value do |source_path|
              abs_src = File.expand_path(source_path)
              if absolute_path == abs_src || absolute_path.start_with?(abs_src + File::SEPARATOR)
                allowed = true
                break
              end
            end
          end
        end

        raise(ArgumentError, "Skill path escapes project boundary: #{identifier}") unless allowed

        skill_md = File.join(normalized_path, 'SKILL.md')

        return Models::Skill.new(name: File.basename(normalized_path), path: normalized_path) if File.exist?(skill_md)

        raise(ArgumentError, "Skill not found: #{identifier}")
      end

      def resolve_by_name
        skills = discover_all_skills
        matches = skills.select { |skill| skill.name == identifier }

        validate_matches!(matches)

        matches.first
      end

      def discover_all_skills
        skills = Models::Skill.discover(base_path)

        sources = SkillBench::Config.skill_sources
        if sources.is_a?(Hash)
          sources.each_value do |source_path|
            skills += Models::Skill.discover(source_path) if Dir.exist?(source_path)
          end
        end

        skills
      end

      def validate_matches!(matches)
        if matches.empty?
          raise(ArgumentError, "Skill not found: #{identifier}")
        elsif matches.size > 1
          matches.uniq! { |m| File.expand_path(m.path) }
          raise(ArgumentError, "Multiple skills found with name '#{identifier}': #{matches.map(&:path).join(', ')}") if matches.size > 1
        end
      end
    end
  end
end
