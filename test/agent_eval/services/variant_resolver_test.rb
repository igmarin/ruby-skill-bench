# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class VariantResolverTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('variant_resolver_test')
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_resolves_path_variant
        variant = { type: :path, path: '/path/to/skill' }
        result = VariantResolver.call(variant, 'test-skill')

        assert_equal ['/path/to/skill'], result
      end

      def test_call_resolves_pack_variant_with_manifest
        manifest_path = File.join(@tmp_dir, 'registry.json')
        File.write(manifest_path, {
          'packs' => {
            'test-pack' => {
              'source' => 'test-repo',
              'tile' => 'tile.json'
            }
          }
        }.to_json)

        skill_path = File.join(@tmp_dir, 'test-skill')
        FileUtils.mkpath(skill_path)
        File.write(File.join(skill_path, 'SKILL.md'), 'Pack skill')

        resolver_mock = mock
        resolver_mock.stubs(:resolve_skill).with('test-pack', 'test-skill').returns(skill_path)
        Registry::PackResolver.stubs(:new).with(manifest_path).returns(resolver_mock)

        variant = { type: :pack, name: 'test-pack' }
        result = VariantResolver.call(variant, 'test-skill', manifest_path: manifest_path)

        assert_equal 1, result.length
        assert_equal skill_path, result.first
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

        resolver_mock = mock
        resolver_mock.stubs(:resolve_skill).with('test-pack', 'nonexistent').returns(nil)
        Registry::PackResolver.stubs(:new).with(manifest_path).returns(resolver_mock)

        variant = { type: :pack, name: 'test-pack' }

        assert_raises(ArgumentError, "Skill 'nonexistent' not found in pack 'test-pack'") do
          VariantResolver.call(variant, 'nonexistent', manifest_path: manifest_path)
        end
      end
    end
  end
end
