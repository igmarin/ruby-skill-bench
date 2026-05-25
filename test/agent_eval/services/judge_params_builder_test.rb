# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class JudgeParamsBuilderTest < Minitest::Test
      def setup
        @provider = Struct.new(:name, :runtime, :llm, :merged_config).new(
          'openai',
          'openai',
          'gpt-4',
          { api_key: 'test-key', model: 'gpt-4' }
        )
      end

      def test_call_builds_judge_params
        config = { api_key: 'test-key', model: 'gpt-4' }
        result = JudgeParamsBuilder.call(@provider, config)

        assert_equal 'test-key', result[:api_key]
        assert_equal 'gpt-4', result[:model]
        assert_equal :openai, result[:provider]
      end

      def test_call_uses_provider_llm_when_config_model_missing
        config = { api_key: 'test-key' }
        result = JudgeParamsBuilder.call(@provider, config)

        assert_equal 'test-key', result[:api_key]
        assert_equal 'gpt-4', result[:model]
        assert_equal :openai, result[:provider]
      end

      def test_call_returns_empty_hash_for_mock_provider
        mock_provider = Struct.new(:name, :runtime, :llm, :merged_config).new('mock', 'mock', 'mock', {})
        config = { api_key: 'test-key' }
        result = JudgeParamsBuilder.call(mock_provider, config)

        assert_equal({}, result)
      end

      def test_call_returns_empty_hash_when_config_nil
        result = JudgeParamsBuilder.call(@provider, nil)

        # When config is nil, it falls back to provider.merged_config
        assert_equal 'test-key', result[:api_key]
        assert_equal 'gpt-4', result[:model]
        assert_equal :openai, result[:provider]
      end

      def test_call_returns_empty_hash_on_error
        provider = Struct.new(:name, :runtime, :llm).new('openai', 'openai', 'gpt-4')
        provider.define_singleton_method(:merged_config) { raise StandardError, 'Config error' }

        result = JudgeParamsBuilder.call(provider, nil)

        assert_equal({}, result)
      end
    end
  end
end
