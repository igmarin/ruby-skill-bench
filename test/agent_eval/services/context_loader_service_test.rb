# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ContextLoaderServiceTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('context_loader_test')
        @skill_dir = File.join(@tmp_dir, 'test-skill')
        FileUtils.mkpath(@skill_dir)
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_loads_skill_context_from_skill_md
        File.write(File.join(@skill_dir, 'SKILL.md'), 'Test skill content')

        skill = Models::Skill.new(name: 'test-skill', path: @skill_dir)
        result = ContextLoaderService.call([skill])

        assert_equal 'Test skill content', result
      end

      def test_call_combines_multiple_skill_contexts
        skill_dir2 = File.join(@tmp_dir, 'test-skill-2')
        FileUtils.mkpath(skill_dir2)
        File.write(File.join(@skill_dir, 'SKILL.md'), 'Skill 1 content')
        File.write(File.join(skill_dir2, 'SKILL.md'), 'Skill 2 content')

        skill1 = Models::Skill.new(name: 'test-skill', path: @skill_dir)
        skill2 = Models::Skill.new(name: 'test-skill-2', path: skill_dir2)
        result = ContextLoaderService.call([skill1, skill2])

        assert_includes result, 'Skill 1 content'
        assert_includes result, 'Skill 2 content'
        assert_includes result, '=' * 40
      end

      def test_call_returns_empty_string_when_no_skills
        result = ContextLoaderService.call([])

        assert_equal '', result
      end

      def test_call_returns_empty_string_when_skills_nil
        result = ContextLoaderService.call(nil)

        assert_equal '', result
      end

      def test_call_returns_empty_string_when_skill_md_missing
        skill = Models::Skill.new(name: 'test-skill', path: @skill_dir)
        result = ContextLoaderService.call([skill])

        assert_equal '', result
      end

      def test_call_excludes_empty_contexts
        skill_dir2 = File.join(@tmp_dir, 'test-skill-2')
        FileUtils.mkpath(skill_dir2)
        File.write(File.join(@skill_dir, 'SKILL.md'), 'Valid content')

        skill1 = Models::Skill.new(name: 'test-skill', path: @skill_dir)
        skill2 = Models::Skill.new(name: 'test-skill-2', path: skill_dir2)
        result = ContextLoaderService.call([skill1, skill2])

        assert_equal 'Valid content', result
      end
    end
  end
end
