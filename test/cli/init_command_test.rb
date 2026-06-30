# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class InitCommandTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('cli_init_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_with_openai_provider
        exit_code = InitCommand.call(['--openai'])

        assert_equal 0, exit_code
        assert_path_exists SkillBench::Config::CONFIG_FILENAME
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'openai', config[:provider]
      end

      def test_call_with_gemini_provider
        exit_code = InitCommand.call(['--gemini'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'gemini', config[:provider]
        assert_equal 'us-central1', config[:config][:location]
      end

      def test_call_with_anthropic_provider
        exit_code = InitCommand.call(['--anthropic'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'anthropic', config[:provider]
      end

      def test_call_with_ollama_provider
        exit_code = InitCommand.call(['--ollama'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'ollama', config[:provider]
      end

      def test_call_with_azure_provider
        exit_code = InitCommand.call(['--azure'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'azure', config[:provider]
      end

      def test_call_with_groq_provider
        exit_code = InitCommand.call(['--groq'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'groq', config[:provider]
      end

      def test_call_with_deepseek_provider
        exit_code = InitCommand.call(['--deepseek'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'deepseek', config[:provider]
      end

      def test_call_with_opencode_provider
        exit_code = InitCommand.call(['--opencode'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'opencode', config[:provider]
      end

      def test_call_with_mock_flag_writes_minimal_offline_config
        exit_code = InitCommand.call(['--mock'])

        assert_equal 0, exit_code
        assert_path_exists SkillBench::Config::CONFIG_FILENAME
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'mock', config[:provider]
        assert_equal 30, config[:max_execution_time]
        refute config.key?(:config)
        refute config.key?(:api_key)
      end

      def test_call_with_mock_and_force_overwrites_existing
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"old": true}')

        exit_code = InitCommand.call(['--mock', '--force'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'mock', config[:provider]
      end

      def test_call_without_provider_returns_error
        exit_code = InitCommand.call([])

        assert_equal 1, exit_code
        refute_path_exists SkillBench::Config::CONFIG_FILENAME
      end

      def test_call_with_force_overwrites_existing
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"old": true}')

        exit_code = InitCommand.call(['--openai', '--force'])

        assert_equal 0, exit_code
        config = JSON.parse(File.read(SkillBench::Config::CONFIG_FILENAME), symbolize_names: true)

        assert_equal 'openai', config[:provider]
      end

      def test_call_without_force_on_existing_returns_error
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"old": true}')

        exit_code = InitCommand.call(['--openai'])

        assert_equal 1, exit_code
        assert_equal '{"old": true}', File.read(SkillBench::Config::CONFIG_FILENAME)
      end
    end
  end
end
