# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Commands
    class InitProviderTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('skill_bench_init_provider_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_run_with_gemini_provider_generates_single_provider_config
        Init.run(provider: :gemini)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'gemini', config[:provider]
        assert config.key?(:max_execution_time)
        assert config.key?(:config)
        assert_nil config[:config][:api_key]
        assert_equal 'gemini-1.5-flash-latest', config[:config][:model]
        assert_equal 'us-central1', config[:config][:location]
        assert_nil config[:config][:project_id]
      end

      def test_run_with_openai_provider_generates_single_provider_config
        Init.run(provider: :openai)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'openai', config[:provider]
        assert_nil config[:config][:api_key]
        assert_equal 'gpt-4o', config[:config][:model]
        refute config[:config].key?(:location)
        refute config[:config].key?(:project_id)
      end

      def test_run_with_anthropic_provider_generates_single_provider_config
        Init.run(provider: :anthropic)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'anthropic', config[:provider]
        assert_nil config[:config][:api_key]
        assert_equal 'claude-opus-4-7', config[:config][:model]
      end

      def test_run_with_ollama_provider_generates_single_provider_config
        Init.run(provider: :ollama)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'ollama', config[:provider]
        assert_nil config[:config][:api_key]
        assert_equal 'qwen:7b', config[:config][:model]
        assert_nil config[:config][:base_url]
      end

      def test_run_with_azure_provider_generates_single_provider_config
        Init.run(provider: :azure)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'azure', config[:provider]
        assert_nil config[:config][:api_key]
        assert_equal 'gpt-4', config[:config][:model]
        assert_nil config[:config][:endpoint]
        assert_nil config[:config][:api_version]
      end

      def test_run_with_groq_provider_generates_single_provider_config
        Init.run(provider: :groq)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'groq', config[:provider]
        assert_nil config[:config][:api_key]
        assert_equal 'llama-3.3-70b-versatile', config[:config][:model]
      end

      def test_run_with_deepseek_provider_generates_single_provider_config
        Init.run(provider: :deepseek)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'deepseek', config[:provider]
        assert_nil config[:config][:api_key]
        assert_equal 'deepseek-chat', config[:config][:model]
      end

      def test_run_raises_on_unknown_provider
        assert_raises(ArgumentError) do
          Init.run(provider: :unknown)
        end
      end

      def test_run_with_force_overwrites_existing_config
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"old": true}')

        Init.run(provider: :openai, force: true)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert_equal 'openai', config[:provider]
      end

      def test_run_raises_when_file_exists_and_not_force
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"old": true}')

        assert_raises(RuntimeError) { Init.run(provider: :openai) }
      end
    end
  end
end
