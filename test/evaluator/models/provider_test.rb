# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Models
    class ProviderTest < Minitest::Test
      def setup
        @original_env = ENV.to_h
        ENV.clear
      end

      def teardown
        ENV.clear
        ENV.update(@original_env)
      end

      def test_merged_config_uses_config_value_when_no_env_var
        provider = Provider.new(name: 'openai', runtime: 'openai', llm: 'openai',
                                config: { api_key: 'config-key', model: 'gpt-4' })

        config = provider.merged_config

        assert_equal 'config-key', config[:api_key]
        assert_equal 'gpt-4', config[:model]
      end

      def test_merged_config_prefers_prefixed_env_var
        ENV['SKILL_BENCH_OPENAI_API_KEY'] = 'prefixed-key'
        provider = Provider.new(name: 'openai', runtime: 'openai', llm: 'openai',
                                config: { api_key: 'config-key' })

        config = provider.merged_config

        assert_equal 'prefixed-key', config[:api_key]
      end

      def test_merged_config_falls_back_to_legacy_env_var
        ENV['OPENAI_API_KEY'] = 'legacy-key'
        provider = Provider.new(name: 'openai', runtime: 'openai', llm: 'openai', config: {})

        config = provider.merged_config

        assert_equal 'legacy-key', config[:api_key]
      end

      def test_merged_config_prefers_prefixed_over_legacy
        ENV['SKILL_BENCH_OPENAI_API_KEY'] = 'prefixed-key'
        ENV['OPENAI_API_KEY'] = 'legacy-key'
        provider = Provider.new(name: 'openai', runtime: 'openai', llm: 'openai', config: {})

        config = provider.merged_config

        assert_equal 'prefixed-key', config[:api_key]
      end

      def test_merged_config_resolves_base_url_from_env
        ENV['SKILL_BENCH_OPENCODE_BASE_URL'] = 'https://custom.example.com'
        provider = Provider.new(name: 'opencode', runtime: 'opencode', llm: 'opencode',
                                config: { api_key: 'key' })

        config = provider.merged_config

        assert_equal 'https://custom.example.com', config[:base_url]
      end

      def test_merged_config_raises_when_api_key_missing
        provider = Provider.new(name: 'openai', runtime: 'openai', llm: 'openai', config: {})

        error = assert_raises(ArgumentError) { provider.merged_config }
        assert_includes error.message, 'API key not found'
        assert_includes error.message, 'SKILL_BENCH_OPENAI_API_KEY'
      end

      def test_merged_config_raises_for_invalid_provider
        provider = Provider.new(name: 'invalid', runtime: 'invalid', llm: 'invalid', config: {})

        error = assert_raises(ArgumentError) { provider.merged_config }
        assert_includes error.message, 'Invalid provider name'
      end

      private

      def with_env(vars)
        vars.each { |k, v| ENV[k] = v }
        yield
      ensure
        vars.each_key { |k| ENV.delete(k) }
      end
    end
  end
end
