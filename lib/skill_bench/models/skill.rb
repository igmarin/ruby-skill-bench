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

      # Discover skills from a directory
      # @param base_path [String] Directory to search (default: "skills/")
      # @return [Array<SkillBench::Models::Skill>] Discovered skills
      def self.discover(base_path = 'skills/')
        return [] unless Dir.exist?(base_path)

        Pathname.new(base_path).children.select(&:directory?).filter_map do |dir|
          skill_md = dir.join('SKILL.md')
          next unless skill_md.exist?

          new(name: dir.basename.to_s, path: dir.to_s)
        end
      end
    end
  end
end
