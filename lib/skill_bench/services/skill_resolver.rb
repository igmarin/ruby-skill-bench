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
      # @raise [ArgumentError] if skill file not found at path
      def resolve_by_path
        normalized_path = identifier.end_with?('SKILL.md') ? File.dirname(identifier) : identifier
        skill_md = File.join(normalized_path, 'SKILL.md')

        return Models::Skill.new(name: File.basename(normalized_path), path: normalized_path) if File.exist?(skill_md)

        raise(ArgumentError, "Skill not found: #{identifier}")
      end

      # Resolves a skill by name using recursive discovery.
      #
      # @return [SkillBench::Models::Skill] The resolved skill
      # @raise [ArgumentError] if no skill with matching name found
      def resolve_by_name
        skills = Models::Skill.discover(base_path)
        skills.find { |skill| skill.name == identifier } || raise(ArgumentError, "Skill not found: #{identifier}")
      end
    end
  end
end
