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
        assert_match(%r{skills/my-skill$}, skill.path)
      end

      def test_resolve_by_name_finds_nested_skill
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skill = SkillResolver.call('ruby-api-client-integration')

        assert_equal 'ruby-api-client-integration', skill.name
        assert_match(%r{skills/api/ruby-api-client-integration$}, skill.path)
      end

      def test_resolve_by_path_finds_nested_skill
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skill = SkillResolver.call('skills/api/ruby-api-client-integration')

        assert_equal 'ruby-api-client-integration', skill.name
        assert_match(%r{skills/api/ruby-api-client-integration$}, skill.path)
      end

      def test_resolve_by_path_with_skill_md_suffix
        FileUtils.mkdir_p('skills/api/ruby-api-client-integration')
        File.write('skills/api/ruby-api-client-integration/SKILL.md', '# API Client')

        skill = SkillResolver.call('skills/api/ruby-api-client-integration/SKILL.md')

        assert_equal 'ruby-api-client-integration', skill.name
        assert_match(%r{skills/api/ruby-api-client-integration$}, skill.path)
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

      def test_resolve_by_path_rejects_absolute_paths_outside_cwd
        # Create a skill outside the temp project directory
        outside_dir = Dir.mktmpdir('outside_skill')
        FileUtils.mkdir_p(File.join(outside_dir, 'malicious-skill'))
        File.write(File.join(outside_dir, 'malicious-skill/SKILL.md'), '# Malicious')

        assert_raises(ArgumentError) do
          SkillResolver.call(File.join(outside_dir, 'malicious-skill'))
        end
      ensure
        FileUtils.rm_rf(outside_dir)
      end

      def test_resolve_by_path_rejects_traversal_outside_cwd
        # Create a skill in the parent directory of the temp project
        parent_skill = File.join(@tmp_dir, '..', 'parent-skill')
        FileUtils.mkdir_p(parent_skill)
        File.write(File.join(parent_skill, 'SKILL.md'), '# Parent Skill')

        assert_raises(ArgumentError) do
          SkillResolver.call('../parent-skill')
        end
      ensure
        FileUtils.rm_rf(parent_skill)
      end

      def test_resolve_by_path_allows_paths_within_cwd
        FileUtils.mkdir_p('skills/allowed-skill')
        File.write('skills/allowed-skill/SKILL.md', '# Allowed')

        skill = SkillResolver.call('skills/allowed-skill')

        assert_equal 'allowed-skill', skill.name
      end

      def test_resolve_by_path_rejects_sibling_directory_prefix
        # Create a skill in a sibling directory whose name starts with the CWD name
        # e.g., if CWD is /tmp/project, /tmp/project2/skill should NOT match
        parent_dir = File.dirname(@tmp_dir)
        sibling_dir = File.join(parent_dir, "#{File.basename(@tmp_dir)}-sibling", 'evil-skill')
        FileUtils.mkdir_p(sibling_dir)
        File.write(File.join(sibling_dir, 'SKILL.md'), '# Evil')

        # The path uses a relative reference that resolves to the sibling
        relative_to_sibling = File.join('..', "#{File.basename(@tmp_dir)}-sibling", 'evil-skill')

        assert_raises(ArgumentError) do
          SkillResolver.call(relative_to_sibling)
        end
      ensure
        FileUtils.rm_rf(File.join(parent_dir, "#{File.basename(@tmp_dir)}-sibling"))
      end
    end
  end
end
