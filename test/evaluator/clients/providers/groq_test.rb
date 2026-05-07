# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    module Providers
      class GroqTest < Minitest::Test
        def setup
          Config.reset
          Config.current_llm_provider = :groq
        end

        def test_call_returns_message_content_on_success
          Config.setup do |config|
            config.set_provider_api_key(:groq, 'test_groq_key')
          end

          stub_request(:post, %r{api\.groq\.com.*chat/completions})
            .to_return(
              status: 200,
              body: { choices: [{ message: { content: 'Hello from Groq', role: 'assistant' } }] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          old_stderr = $stderr
          $stderr = StringIO.new
          result = Groq.call(
            api_key: 'test_groq_key',
            model: 'llama-3.1',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
          $stderr = old_stderr

          assert result[:success]
          assert_equal 'Hello from Groq', result[:response][:message]['content']
        end

        def test_call_returns_error_on_api_failure
          Config.setup do |config|
            config.set_provider_api_key(:groq, 'test_groq_key')
          end

          stub_request(:post, %r{api\.groq\.com.*chat/completions})
            .to_return(status: 401, body: 'Unauthorized')

          old_stderr = $stderr
          $stderr = StringIO.new
          result = Groq.call(
            api_key: 'test_groq_key',
            model: 'llama-3.1',
            system_prompt: 'System',
            messages: [{ role: 'user', content: 'Hi' }]
          )
          $stderr = old_stderr

          refute result[:success]
        end

        def test_provider_name
          client = Groq.new(system_prompt: '', messages: [])

          assert_equal :groq, client.provider_name
        end
      end
    end
  end
end
