# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Models
    class SkillTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('skill_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_discover_finds_skills_in_flat_directory
        FileUtils.mkdir_p('skills/alpha')
        File.write('skills/alpha/SKILL.md', '# Alpha')
        FileUtils.mkdir_p('skills/beta')
        File.write('skills/beta/SKILL.md', '# Beta')

        skills = Skill.discover('skills/')

        assert_equal 2, skills.size
        assert_equal %w[alpha beta], skills.map(&:name).sort
      end

      def test_discover_finds_skills_in_nested_directories
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')
        FileUtils.mkdir_p('skills/api/api-rest-collection')
        File.write('skills/api/api-rest-collection/SKILL.md', '# REST Collection')
        FileUtils.mkdir_p('skills/rails/rails-graphql-best-practices')
        File.write('skills/rails/rails-graphql-best-practices/SKILL.md', '# GraphQL')

        skills = Skill.discover('skills/')

        assert_equal 3, skills.size
        names = skills.map(&:name).sort
        assert_includes names, 'ruby-api-client-integration'
        assert_includes names, 'api-rest-collection'
        assert_includes names, 'rails-graphql-best-practices'
      end

      def test_discover_ignores_directories_without_skill_md
        FileUtils.mkdir_p('skills/valid')
        File.write('skills/valid/SKILL.md', '# Valid')
        FileUtils.mkdir_p('skills/invalid')

        skills = Skill.discover('skills/')

        assert_equal 1, skills.size
        assert_equal 'valid', skills.first.name
      end

      def test_discover_returns_empty_array_when_no_skills_directory
        skills = Skill.discover('nonexistent/')

        assert_equal [], skills
      end

      def test_discover_returns_correct_paths_for_nested_skills
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skills = Skill.discover('skills/')

        assert_equal 1, skills.size
        assert_equal 'ruby-api-client-integration', skills.first.name
        assert_match(/skills\/api\/ruby-api-client-integration$/, skills.first.path)
      end
    end
  end
end
