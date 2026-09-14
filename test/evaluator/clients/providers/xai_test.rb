# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    module Providers
      class XaiTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :xai
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:xai, 'test_xai_key')
          end

          stub_request(:post, 'https://api.x.ai/v1/chat/completions')
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from Grok', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          begin
            result = Xai.call(
              api_key: 'test_xai_key',
              model: 'grok-4',
              system_prompt: 'System',
              messages: [{ role: 'user', content: 'Hi' }]
            )
          ensure
            $stderr = old_stderr
          end

          assert result[:success]
          assert_equal 'Hello from Grok', result[:response][:message]['content']
        end

        def test_call_sends_request_to_xai_endpoint_with_bearer_auth
          Config.setup do |config|
            config.set_provider_api_key(:xai, 'test_xai_key')
          end

          stub = stub_request(:post, 'https://api.x.ai/v1/chat/completions')
                 .with(
                   headers: { 'Authorization' => 'Bearer test_xai_key' },
                   body: hash_including('model' => 'grok-4')
                 )
                 .to_return(
                   status: 200,
                   body: { choices: [{ message: { content: 'ok', role: 'assistant' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' }
                 )

          old_stderr = $stderr
          $stderr = StringIO.new
          begin
            Xai.call(
              api_key: 'test_xai_key',
              model: 'grok-4',
              system_prompt: 'System',
              messages: [{ role: 'user', content: 'Hi' }]
            )
          ensure
            $stderr = old_stderr
          end

          assert_requested stub
        end

        def test_call_returns_error_on_missing_api_key
          Config.setup do |config|
            config.set_provider_api_key(:xai, nil)
          end

          result = Xai.call(
            api_key: nil,
            system_prompt: 'System',
            messages: []
          )

          refute result[:success]
          assert_equal 'API Key not set for Xai', result[:response][:error][:message]
        end

        def test_provider_name
          client = Xai.new(system_prompt: '', messages: [])

          assert_equal :xai, client.provider_name
        end

        def test_base_url
          client = Xai.new(system_prompt: '', messages: [])

          assert_equal 'https://api.x.ai', client.send(:base_url)
        end

        def test_request_path
          client = Xai.new(system_prompt: '', messages: [])

          assert_equal '/v1/chat/completions', client.send(:request_path)
        end

        def test_schema_default_model_is_grok4
          assert_equal 'grok-4', ProviderSchemas.for(:xai)[:model]
        end
      end
    end
  end
end
