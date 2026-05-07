# frozen_string_literal: true

require 'test_helper'

module Evaluator
  module Clients
    module Providers
      class OpenCodeTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :opencode
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:opencode, 'test_opencode_key')
          end

          stub_request(:post, %r{api\.opencode\.ai.*chat/completions})
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from OpenCode', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          result = OpenCode.call(
            api_key: 'test_opencode_key',
            model: 'opencode-1',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
        ensure
          $stderr = old_stderr

          assert result[:success]
          assert_equal 'Hello from OpenCode', result[:response][:message]['content']
        end

        def test_call_returns_error_on_api_failure
          Config.setup do |config|
            config.set_provider_api_key(:opencode, 'test_opencode_key')
          end

          stub_request(:post, %r{api\.opencode\.ai.*chat/completions})
            .to_return(status: 401, body: 'Unauthorized')

          old_stderr = $stderr
          $stderr = StringIO.new
          result = OpenCode.call(
            api_key: 'test_opencode_key',
            model: 'opencode-1',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
        ensure
          $stderr = old_stderr

          refute result[:success]
        end

        def test_provider_name
          client = OpenCode.new(system_prompt: '', messages: [])

          assert_equal :opencode, client.provider_name
        end
      end
    end
  end
end
