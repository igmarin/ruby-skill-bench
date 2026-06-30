# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Commands
    class InitTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('skill_bench_init_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_run_creates_config_file
        Init.run(provider: :openai, force: false)

        assert_path_exists SkillBench::Config::CONFIG_FILENAME
      end

      def test_run_creates_valid_json
        Init.run(provider: :openai, force: false)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert config.key?(:provider)
        assert config.key?(:config)
        assert_equal 'openai', config[:provider]
        assert_equal 'gpt-4o', config[:config][:model]
      end

      def test_run_raises_when_file_exists_and_not_force
        File.write(SkillBench::Config::CONFIG_FILENAME, 'existing')

        assert_raises(RuntimeError) { Init.run(provider: :openai, force: false) }
      end

      def test_run_overwrites_when_force_true
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"invalid": true}')

        Init.run(provider: :openai, force: true)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content)

        refute_equal({ 'invalid' => true }, config)
        assert config.key?('provider')
      end

      def test_run_with_mock_provider_writes_minimal_config
        Init.run(provider: :mock, force: false)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'mock', config[:provider]
        assert_equal 30, config[:max_execution_time]
        refute config.key?(:config)
        refute config.key?(:api_key)
      end

      def test_config_for_provider_mock_omits_config_block
        assert_equal({ provider: :mock, max_execution_time: 30 }, Init.config_for_provider(:mock))
      end
    end
  end
end
