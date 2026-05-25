# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class SkillResolverServiceTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('skill_resolver_service_test')
        @skill_dir = File.join(@tmp_dir, 'skills', 'test-skill')
        FileUtils.mkpath(@skill_dir)
        File.write(File.join(@skill_dir, 'SKILL.md'), 'Test skill')
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_resolves_skills_by_name
        result = SkillResolverService.call(['test-skill'])

        assert_equal 1, result.length
        assert_equal 'test-skill', result.first.name
      end

      def test_call_resolves_multiple_skills
        skill_dir2 = File.join(@tmp_dir, 'skills', 'test-skill-2')
        FileUtils.mkpath(skill_dir2)
        File.write(File.join(skill_dir2, 'SKILL.md'), 'Test skill 2')

        result = SkillResolverService.call(%w[test-skill test-skill-2])

        assert_equal 2, result.length
        assert_equal 'test-skill', result[0].name
        assert_equal 'test-skill-2', result[1].name
      end

      def test_call_raises_when_skill_not_found
        assert_raises(ArgumentError) do
          SkillResolverService.call(['nonexistent'])
        end
      end

      def test_call_with_pack_resolves_from_registry
        manifest_path = File.join(@tmp_dir, 'registry.json')
        File.write(manifest_path, {
          'packs' => {
            'test-pack' => {
              'source' => 'test-repo',
              'tile' => 'tile.json'
            }
          }
        }.to_json)

        # Create repo in a location PackResolver will find (relative to tmp_dir)
        repo_path = File.join(@tmp_dir, '..', 'test-repo')
        FileUtils.mkpath(repo_path)
        tile_path = File.join(repo_path, 'tile.json')
        File.write(tile_path, {
          'skills' => {
            'test-skill' => { 'path' => 'skills/test-skill' }
          }
        }.to_json)

        skill_path = File.join(repo_path, 'skills', 'test-skill')
        FileUtils.mkpath(skill_path)
        File.write(File.join(skill_path, 'SKILL.md'), 'Pack skill')

        result = SkillResolverService.call(['test-skill'], pack: 'test-pack', registry_manifest: manifest_path)

        assert_equal 1, result.length
        assert_equal 'test-skill', result.first.name

        FileUtils.rm_rf(repo_path)
      end

      def test_call_raises_when_pack_skill_not_found
        manifest_path = File.join(@tmp_dir, 'registry.json')
        File.write(manifest_path, {
          'packs' => {
            'test-pack' => {
              'source' => 'test-repo',
              'tile' => 'tile.json'
            }
          }
        }.to_json)

        tile_path = File.join(@tmp_dir, 'test-repo', 'tile.json')
        FileUtils.mkpath(File.dirname(tile_path))
        File.write(tile_path, { 'skills' => {} }.to_json)

        assert_raises(ArgumentError) do
          SkillResolverService.call(['nonexistent'], pack: 'test-pack', registry_manifest: manifest_path)
        end
      end

      def test_call_raises_when_registry_manifest_not_found
        assert_raises(ArgumentError) do
          SkillResolverService.call(['test-skill'], pack: 'test-pack', registry_manifest: 'nonexistent.json')
        end
      end
    end
  end
end
