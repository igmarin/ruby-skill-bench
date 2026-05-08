# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class SkillResolverTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('skill_resolver_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_resolve_by_name_finds_flat_skill
        FileUtils.mkdir_p('skills/my-skill')
        File.write('skills/my-skill/SKILL.md', '# My Skill')

        skill = SkillResolver.call('my-skill')

        assert_equal 'my-skill', skill.name
        assert_match(/skills\/my-skill$/, skill.path)
      end

      def test_resolve_by_name_finds_nested_skill
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skill = SkillResolver.call('ruby-api-client-integration')

        assert_equal 'ruby-api-client-integration', skill.name
        assert_match(/skills\/api\/ruby-api-client-integration$/, skill.path)
      end

      def test_resolve_by_path_finds_nested_skill
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skill = SkillResolver.call('skills/api/ruby-api-client-integration')

        assert_equal 'ruby-api-client-integration', skill.name
        assert_match(/skills\/api\/ruby-api-client-integration$/, skill.path)
      end

      def test_resolve_by_path_with_skill_md_suffix
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skill = SkillResolver.call('skills/api/ruby-api-client-integration/SKILL.md')

        assert_equal 'ruby-api-client-integration', skill.name
        assert_match(/skills\/api\/ruby-api-client-integration$/, skill.path)
      end

      def test_resolve_raises_when_skill_not_found_by_name
        assert_raises(ArgumentError) do
          SkillResolver.call('nonexistent-skill')
        end
      end

      def test_resolve_raises_when_skill_not_found_by_path
        assert_raises(ArgumentError) do
          SkillResolver.call('skills/nonexistent/path')
        end
      end
    end
  end
end
