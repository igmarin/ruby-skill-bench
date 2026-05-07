# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class AzureOpenAIToolUseTest < Minitest::Test
      def setup
        Config.reset
        Config.current_llm_provider = :azure
        Config.setup do |config|
          config.set_provider_api_key(:azure, 'test_azure_key')
          config.set_provider_endpoint(:azure, 'https://test-azure.openai.azure.com')
          config.set_provider_model(:azure, 'gpt-4')
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

        stub_request(:post, "https://test-azure.openai.azure.com/openai/deployments/gpt-4/chat/completions?api-version=#{Evaluator::Clients::Providers::AzureOpenAI::DEFAULT_API_VERSION}")
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

        result = Providers::AzureOpenAI.call(
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
