# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class ProviderConfigTest < Minitest::Test
      def setup
        Config.reset
      end

      def test_call_returns_standardized_config
        Config.setup do |config|
          config.set_provider_api_key(:openai, 'test_key')
        end

        result = ProviderConfig.call(provider: :openai, options: { model: 'gpt-4' })

        assert_equal 'test_key', result[:api_key]
        assert_equal 'gpt-4', result[:model]
        assert_equal 'Openai', result[:provider_name]
      end

      def test_call_uses_options_over_config
        Config.setup do |config|
          config.set_provider_api_key(:openai, 'config_key')
        end

        result = ProviderConfig.call(provider: :openai, options: { api_key: 'override_key' })

        assert_equal 'override_key', result[:api_key]
      end

      def test_call_returns_nil_for_missing_api_key
        original_api_key = ENV.fetch('OPENAI_API_KEY', nil)
        ENV.delete('OPENAI_API_KEY')
        Config.reset

        result = ProviderConfig.call(provider: :openai, options: {})

        assert_nil result[:api_key]
      ensure
        if original_api_key
          ENV['OPENAI_API_KEY'] = original_api_key
        else
          ENV.delete('OPENAI_API_KEY')
        end
      end

      def test_call_includes_provider_specific_extras
        Config.setup do |config|
          config.set_provider_api_key(:gemini, 'test_key')
          config.set_provider_project_id(:gemini, 'test-project')
          config.set_provider_location(:gemini, 'us-central1')
        end

        result = ProviderConfig.call(provider: :gemini, options: { model: 'gemini-pro' })

        assert_equal 'test_key', result[:api_key]
        assert_equal 'test-project', result[:project_id]
        assert_equal 'us-central1', result[:location]
      end

      def test_call_accepts_https_base_url_with_key
        result = ProviderConfig.call(
          provider: :openai,
          options: { api_key: 'key', base_url: 'https://api.example.com' }
        )

        assert_equal 'https://api.example.com', result[:base_url]
      end

      def test_call_rejects_cleartext_base_url_with_key
        error = assert_raises(BaseUrlValidator::InvalidBaseURLError) do
          ProviderConfig.call(
            provider: :openai,
            options: { api_key: 'key', base_url: 'http://evil.example.com' }
          )
        end

        assert_match(/cleartext http/i, error.message)
      end

      def test_call_accepts_loopback_http_base_url_with_key
        result = ProviderConfig.call(
          provider: :ollama,
          options: { api_key: 'key', base_url: 'http://localhost:11434' }
        )

        assert_equal 'http://localhost:11434', result[:base_url]
      end

      def test_call_rejects_relative_base_url
        assert_raises(BaseUrlValidator::InvalidBaseURLError) do
          ProviderConfig.call(
            provider: :openai,
            options: { api_key: 'key', base_url: '/v1/chat/completions' }
          )
        end
      end

      def test_call_opt_in_flag_permits_cleartext_base_url
        result = ProviderConfig.call(
          provider: :openai,
          options: {
            api_key: 'key',
            base_url: 'http://internal-proxy.example.com',
            allow_insecure_base_url: true
          }
        )

        assert_equal 'http://internal-proxy.example.com', result[:base_url]
      end

      def test_call_validates_azure_endpoint_as_transport_url
        assert_raises(BaseUrlValidator::InvalidBaseURLError) do
          ProviderConfig.call(
            provider: :azure,
            options: { api_key: 'key', endpoint: 'http://evil.example.com' }
          )
        end
      end
    end
  end
end
