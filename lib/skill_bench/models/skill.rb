# frozen_string_literal: true

require 'pathname'

module SkillBench
  module Models
    # Represents a reusable skill for agent evaluation
    class Skill
      attr_reader :name, :path

      # Initialize a new Skill
      # @param name [String] Skill name
      # @param path [String] Path to skill directory
      def initialize(name:, path:)
        @name = name
        @path = path
      end

      # Discover skills from a directory recursively
      # @param base_path [String] Directory to search (default: "skills/")
      # @return [Array<SkillBench::Models::Skill>] Discovered skills
      def self.discover(base_path = 'skills/')
        return [] unless Dir.exist?(base_path)

        Dir.glob(File.join(base_path, '**', 'SKILL.md')).map do |skill_md_path|
          skill_dir = File.dirname(skill_md_path)
          new(name: File.basename(skill_dir), path: skill_dir)
        end
      end
    end
  end
end
