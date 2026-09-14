# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class Config
    class EnvOverridesTest < Minitest::Test
      def test_returns_nested_provider_overrides_for_present_env_values
        result = EnvOverrides.call(
          env: {
            'OPENAI_API_KEY' => 'openai-key',
            'GEMINI_API_KEY' => 'gemini-key',
            'GEMINI_LOCATION' => 'us-east1',
            'GEMINI_PROJECT_ID' => 'gemini-project'
          }
        )

        assert result[:success]
        assert_equal(
          {
            openai: { api_key: 'openai-key' },
            gemini: {
              api_key: 'gemini-key',
              location: 'us-east1',
              project_id: 'gemini-project'
            }
          },
          result[:response][:overrides]
        )
      end

      def test_omits_absent_env_values
        result = EnvOverrides.call(env: {})

        assert result[:success]
        assert_equal({}, result[:response][:overrides])
      end

      def test_maps_bedrock_bearer_token_and_region
        result = EnvOverrides.call(
          env: {
            'AWS_BEARER_TOKEN_BEDROCK' => 'bedrock-token',
            'SKILL_BENCH_BEDROCK_REGION' => 'eu-west-1',
            'SKILL_BENCH_BEDROCK_MODEL' => 'amazon.nova-lite-v1:0'
          }
        )

        assert result[:success]
        assert_equal(
          { bedrock: { api_key: 'bedrock-token', location: 'eu-west-1', model: 'amazon.nova-lite-v1:0' } },
          result[:response][:overrides]
        )
      end

      def test_maps_xai_api_key_from_prefixed_and_native_env
        result = EnvOverrides.call(
          env: {
            'SKILL_BENCH_XAI_API_KEY' => 'prefixed-key',
            'XAI_API_KEY' => 'native-key',
            'SKILL_BENCH_XAI_MODEL' => 'grok-4'
          }
        )

        assert result[:success]
        assert_equal(
          { xai: { api_key: 'native-key', model: 'grok-4' } },
          result[:response][:overrides]
        )
      end
    end
  end
end
