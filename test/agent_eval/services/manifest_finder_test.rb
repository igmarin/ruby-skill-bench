# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/skill_bench/services/manifest_finder'

module SkillBench
  module Services
    class ManifestFinderTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('manifest_finder_test')
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_returns_default_path_when_exists
        manifest_path = File.join(@tmp_dir, 'agent-mcp-runtime', 'registry.json')
        FileUtils.mkpath(File.dirname(manifest_path))
        File.write(manifest_path, '{}')

        result = ManifestFinder.call(path: manifest_path)

        assert_equal manifest_path, result
      end

      def test_call_uses_custom_path
        custom_path = File.join(@tmp_dir, 'custom.json')
        File.write(custom_path, '{}')

        result = ManifestFinder.call(path: custom_path)

        assert_equal custom_path, result
      end

      def test_call_raises_when_default_not_found
        Dir.chdir(@tmp_dir) do
          assert_raises(ArgumentError, 'Registry manifest not found') do
            ManifestFinder.call
          end
        end
      end

      def test_call_raises_when_custom_not_found
        custom_path = File.join(@tmp_dir, 'nonexistent.json')

        assert_raises(ArgumentError, 'Registry manifest not found') do
          ManifestFinder.call(path: custom_path)
        end
      end
    end
  end
end
