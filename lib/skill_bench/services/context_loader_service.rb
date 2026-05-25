# frozen_string_literal: true

module SkillBench
  module Services
    # Loads and combines skill context from SKILL.md files.
    class ContextLoaderService
      # Loads and combines skill context from SKILL.md files.
      #
      # @param skills [Array<SkillBench::Models::Skill>] The skills to load context from
      # @return [String] The combined skill context
      def self.call(skills)
        new(skills).call
      end

      # @param skills [Array<SkillBench::Models::Skill>] The skills to load context from
      def initialize(skills)
        @skills = skills
      end

      # Loads and combines skill context from SKILL.md files.
      #
      # @return [String] The combined skill context
      def call
        return '' if @skills.nil? || @skills.empty?

        contexts = @skills.map { |skill| load_skill_context(skill) }
        contexts.reject(&:empty?).join("\n\n#{'=' * 40}\n\n")
      end

      private

      # Loads the skill context from a single skill's SKILL.md file.
      #
      # @param skill [SkillBench::Models::Skill] The skill to load context from
      # @return [String] The skill context or empty string if not found
      def load_skill_context(skill)
        skill_md = File.join(skill.path, 'SKILL.md')
        File.exist?(skill_md) ? File.read(skill_md) : ''
      end
    end
  end
end
