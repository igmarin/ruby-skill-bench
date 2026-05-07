# frozen_string_literal: true

require 'test_helper'

module Evaluator
  module Clients
    module Providers
      class DeepSeekTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :deepseek
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:deepseek, 'test_deepseek_key')
          end

          stub_request(:post, %r{api\.deepseek\.com.*chat/completions})
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from DeepSeek', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          result = DeepSeek.call(
            api_key: 'test_deepseek_key',
            model: 'deepseek-chat',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
          $stderr = old_stderr

          assert result[:success]
          assert_equal 'Hello from DeepSeek', result[:response][:message]['content']
        end

        def test_call_returns_error_on_api_failure
          Config.setup do |config|
            config.set_provider_api_key(:deepseek, 'test_deepseek_key')
          end

          stub_request(:post, %r{api\.deepseek\.com.*chat/completions})
            .to_return(status: 400, body: 'Bad Request')

          old_stderr = $stderr
          $stderr = StringIO.new
          result = DeepSeek.call(
            api_key: 'test_deepseek_key',
            model: 'deepseek-chat',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
          $stderr = old_stderr

          refute result[:success]
        end

        def test_provider_name
          client = DeepSeek.new(system_prompt: '', messages: [])

          assert_equal :deepseek, client.provider_name
        end
      end
    end
  end
end
