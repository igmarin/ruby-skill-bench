# frozen_string_literal: true

require 'test_helper'

module Evaluator
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
    end
  end
end
