# frozen_string_literal: true

require 'test_helper'

module Evaluator
  module Clients
    class GeminiToolUseTest < Minitest::Test
      def setup
        Config.reset
        Config.current_llm_provider = :gemini
        Config.setup do |config|
          config.set_provider_api_key(:gemini, 'test_gemini_key')
          config.set_provider_project_id(:gemini, 'test-project')
          config.set_provider_location(:gemini, 'us-central1')
          config.set_provider_model(:gemini, 'test-model')
        end
      end

      def test_call_with_tools_returns_tool_calls
        tools = [
          {
            type: 'function',
            function: {
              name: 'get_weather',
              description: 'Get the weather',
              parameters: {
                type: 'object',
                properties: {
                  location: { type: 'string' }
                },
                required: ['location']
              }
            }
          }
        ]

        tool_call = {
          id: 'call_123',
          type: 'function',
          function: {
            name: 'get_weather',
            arguments: '{"location":"London"}'
          }
        }

        stub_request(:post, 'https://us-central1-aiplatform.googleapis.com/v1/projects/test-project/locations/us-central1/endpoints/openapi/chat/completions')
          .with(body: hash_including(tools: tools))
          .to_return(
            status: 200,
            body: {
              choices: [
                {
                  message: {
                    role: 'assistant',
                    content: nil,
                    tool_calls: [tool_call]
                  }
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Providers::Gemini.call(
          system_prompt: 'System',
          messages: [{ role: 'user', content: 'What is the weather in London?' }],
          tools: tools
        )

        assert result[:success]
        message = result[:response][:message]

        assert_equal 'assistant', message['role']
        assert_nil message['content']
        assert_equal 1, message['tool_calls'].length
        assert_equal 'get_weather', message['tool_calls'].first['function']['name']
      end
    end
  end
end
