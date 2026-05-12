# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    module Providers
      class OpenRouterTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :openrouter
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:openrouter, 'test_openrouter_key')
          end

          stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from OpenRouter', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          begin
            result = OpenRouter.call(
              api_key: 'test_openrouter_key',
              model: 'anthropic/claude-3.5-sonnet',
              system_prompt: 'System',
              messages: [{ role: 'user', content: 'Hi' }]
            )
          ensure
            $stderr = old_stderr
          end

          assert result[:success]
          assert_equal 'Hello from OpenRouter', result[:response][:message]['content']
        end

        def test_call_returns_error_on_missing_api_key
          Config.setup do |config|
            config.set_provider_api_key(:openrouter, nil)
          end

          result = OpenRouter.call(
            api_key: nil,
            system_prompt: 'System',
            messages: []
          )

          refute result[:success]
          assert_equal 'API Key not set for Openrouter', result[:response][:error][:message]
        end

        def test_call_returns_error_on_api_failure
          Config.setup do |config|
            config.set_provider_api_key(:openrouter, 'test_openrouter_key')
          end

          stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
            .to_return(status: 401, body: 'Unauthorized')

          old_stderr = $stderr
          $stderr = StringIO.new
          begin
            result = OpenRouter.call(
              api_key: 'test_openrouter_key',
              model: 'anthropic/claude-3.5-sonnet',
              system_prompt: 'System',
              messages: [{ role: 'user', content: 'Hi' }]
            )
          ensure
            $stderr = old_stderr
          end

          refute result[:success]
          assert_match(/API Request failed: 401 - Unauthorized/, result[:response][:error][:message])
        end

        def test_provider_name
          client = OpenRouter.new(system_prompt: '', messages: [])

          assert_equal :openrouter, client.provider_name
        end

        def test_base_url
          client = OpenRouter.new(system_prompt: '', messages: [])

          assert_equal 'https://openrouter.ai', client.send(:base_url)
        end

        def test_request_path
          client = OpenRouter.new(system_prompt: '', messages: [])

          assert_equal '/api/v1/chat/completions', client.send(:request_path)
        end
      end
    end
  end
end
