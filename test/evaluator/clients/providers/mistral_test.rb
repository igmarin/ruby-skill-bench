# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    module Providers
      class MistralTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :mistral
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:mistral, 'test_mistral_key')
          end

          stub_request(:post, %r{api\.mistral\.ai/v1/chat/completions})
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from Mistral', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          result = Mistral.call(
            api_key: 'test_mistral_key',
            model: 'mistral-large-latest',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
        ensure
          $stderr = old_stderr

          assert result[:success]
          assert_equal 'Hello from Mistral', result[:response][:message]['content']
        end

        def test_call_sends_request_to_mistral_endpoint_with_bearer_auth
          Config.setup do |config|
            config.set_provider_api_key(:mistral, 'test_mistral_key')
          end

          stub = stub_request(:post, 'https://api.mistral.ai/v1/chat/completions')
                 .with(
                   headers: { 'Authorization' => 'Bearer test_mistral_key' },
                   body: hash_including('model' => 'mistral-large-latest')
                 )
                 .to_return(
                   status: 200,
                   body: { choices: [{ message: { content: 'ok', role: 'assistant' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' }
                 )

          old_stderr = $stderr
          $stderr = StringIO.new
          Mistral.call(
            api_key: 'test_mistral_key',
            model: 'mistral-large-latest',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
        ensure
          $stderr = old_stderr

          assert_requested(stub)
        end

        def test_call_returns_error_on_api_failure
          Config.setup do |config|
            config.set_provider_api_key(:mistral, 'test_mistral_key')
          end

          stub_request(:post, %r{api\.mistral\.ai/v1/chat/completions})
            .to_return(status: 400, body: 'Bad Request')

          old_stderr = $stderr
          $stderr = StringIO.new
          result = Mistral.call(
            api_key: 'test_mistral_key',
            model: 'mistral-large-latest',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
        ensure
          $stderr = old_stderr

          refute result[:success]
        end

        def test_provider_name
          client = Mistral.new(system_prompt: '', messages: [])

          assert_equal :mistral, client.provider_name
        end
      end
    end
  end
end
