# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    module Providers
      class BedrockTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :bedrock
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:bedrock, 'test_bedrock_key')
            config.set_provider_location(:bedrock, 'us-west-2')
          end

          stub_request(:post, 'https://bedrock-runtime.us-west-2.amazonaws.com/openai/v1/chat/completions')
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from Bedrock', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          begin
            result = Bedrock.call(
              api_key: 'test_bedrock_key',
              model: 'amazon.nova-lite-v1:0',
              location: 'us-west-2',
              system_prompt: 'System',
              messages: [{ role: 'user', content: 'Hi' }]
            )
          ensure
            $stderr = old_stderr
          end

          assert result[:success]
          assert_equal 'Hello from Bedrock', result[:response][:message]['content']
        end

        def test_call_sends_bearer_auth_to_openai_compatible_path
          Config.setup do |config|
            config.set_provider_api_key(:bedrock, 'test_bedrock_key')
          end

          stub = stub_request(:post, 'https://bedrock-runtime.us-east-1.amazonaws.com/openai/v1/chat/completions')
                 .with(
                   headers: { 'Authorization' => 'Bearer test_bedrock_key' },
                   body: hash_including('model' => 'amazon.nova-lite-v1:0')
                 )
                 .to_return(
                   status: 200,
                   body: { choices: [{ message: { content: 'ok', role: 'assistant' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' }
                 )

          old_stderr = $stderr
          $stderr = StringIO.new
          begin
            Bedrock.call(
              api_key: 'test_bedrock_key',
              model: 'amazon.nova-lite-v1:0',
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
            config.set_provider_api_key(:bedrock, nil)
          end

          result = Bedrock.call(api_key: nil, system_prompt: 'System', messages: [])

          refute result[:success]
          assert_equal 'API Key not set for Bedrock', result[:response][:error][:message]
        end

        def test_provider_name
          client = Bedrock.new(system_prompt: '', messages: [])

          assert_equal :bedrock, client.provider_name
        end

        def test_default_region_is_us_east1
          client = Bedrock.new(system_prompt: '', messages: [])

          assert_equal 'https://bedrock-runtime.us-east-1.amazonaws.com', client.send(:base_url)
        end

        def test_request_path
          client = Bedrock.new(system_prompt: '', messages: [])

          assert_equal '/openai/v1/chat/completions', client.send(:request_path)
        end

        def test_schema_default_model
          assert_equal 'amazon.nova-lite-v1:0', ProviderSchemas.for(:bedrock)[:model]
        end
      end
    end
  end
end
