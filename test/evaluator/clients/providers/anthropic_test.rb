# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    # rubocop:disable Metrics/ClassLength
    class AnthropicTest < Minitest::Test
      def setup
        Config.reset
        Config.current_llm_provider = :anthropic
      end

      def test_call_returns_message_content_on_success
        # Arrange
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(
            status: 200,
            body: {
              id: 'msg_123',
              role: 'assistant',
              content: [{ type: 'text', text: 'Hello from Claude' }],
              model: 'claude-3-sonnet-20240229'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Act
        result = Providers::Anthropic.call(
          api_key: 'test_key',
          system_prompt: 'System',
          messages: [{ role: 'user', content: 'Hi' }]
        )

        # Assert
        assert result[:success]
        assert_equal 'Hello from Claude', result[:response][:message]['content']
        assert_equal 'assistant', result[:response][:message]['role']
      end

      def test_call_handles_tool_use_response
        # Arrange
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(
            status: 200,
            body: {
              id: 'msg_123',
              role: 'assistant',
              content: [
                { type: 'text', text: 'Thinking...' },
                {
                  type: 'tool_use',
                  id: 'toolu_123',
                  name: 'read_file',
                  input: { path: 'test.txt' }
                }
              ],
              model: 'claude-3-sonnet-20240229'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Act
        result = Providers::Anthropic.call(
          api_key: 'test_key',
          system_prompt: 'System',
          messages: [{ role: 'user', content: 'Read test.txt' }],
          tools: [{
            type: 'function',
            function: {
              name: 'read_file',
              parameters: { properties: { path: { type: 'string' } } }
            }
          }]
        )

        # Assert
        assert result[:success]
        message = result[:response][:message]

        assert_equal 'Thinking...', message['content']
        assert_equal 1, message['tool_calls'].size
        tool_call = message['tool_calls'].first

        assert_equal 'read_file', tool_call['function']['name']
        assert_equal 'toolu_123', tool_call['id']
      end

      def test_call_handles_tool_use_arguments
        # Arrange
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(
            status: 200,
            body: {
              content: [{ type: 'tool_use', id: 't1', name: 'f', input: { a: 1 } }]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Act
        result = Providers::Anthropic.call(
          api_key: 'k', system_prompt: 'S', messages: [],
          tools: [{ type: 'function', function: { name: 'f', parameters: {} } }]
        )

        # Assert
        tool_call = result[:response][:message]['tool_calls'].first

        assert_equal({ 'a' => 1 }, JSON.parse(tool_call['function']['arguments']))
      end

      def test_request_body_translates_tools
        client = Providers::Anthropic.new(
          system_prompt: 'System',
          messages: [],
          api_key: 'key',
          tools: [{
            type: 'function',
            function: {
              name: 'test_tool',
              description: 'Test Tool',
              parameters: {
                type: 'object',
                properties: { arg: { type: 'string' } },
                required: ['arg']
              }
            }
          }]
        )

        body = client.send(:request_body)

        assert_equal 1, body[:tools].size
        tool = body[:tools].first

        assert_equal 'test_tool', tool[:name]
        assert_equal 'Test Tool', tool[:description]
        assert_equal({
                       type: 'object',
                       properties: { arg: { type: 'string' } },
                       required: ['arg']
                     }, tool[:input_schema])
      end

      def test_request_body_translates_user_and_assistant_messages
        client = Providers::Anthropic.new(
          system_prompt: 'System',
          messages: [
            { role: 'user', content: 'Call tool' },
            {
              role: 'assistant',
              content: 'Thinking',
              tool_calls: [{
                'id' => 'tc_1',
                'function' => { 'name' => 't', 'arguments' => '{}' }
              }]
            }
          ],
          api_key: 'key'
        )

        messages = client.send(:request_body)[:messages]

        assert_equal 'user', messages[0][:role]
        assert_equal 'Call tool', messages[0][:content]
        assert_equal 'assistant', messages[1][:role]
        assert_equal 'tool_use', messages[1][:content].find { |c| c[:type] == 'tool_use' }[:type]
        assert_equal 'text', messages[1][:content].find { |c| c[:type] == 'text' }[:type]
      end

      def test_request_body_translates_tool_result_messages
        client = Providers::Anthropic.new(
          system_prompt: 'System',
          messages: [
            { role: 'tool', tool_call_id: 'tc_1', content: 'result' }
          ],
          api_key: 'key'
        )

        messages = client.send(:request_body)[:messages]
        content = messages[0][:content]

        assert_equal 'user', messages[0][:role]
        assert_equal 'tool_result', content[0][:type]
        assert_equal 'tc_1', content[0][:tool_use_id]
        assert_equal 'result', content[0][:content]
      end

      def test_valid_config_missing_api_key
        client = Providers::Anthropic.new(
          system_prompt: 'System',
          messages: [],
          api_key: nil
        )

        refute client.send(:valid_config?)
        result = client.send(:config_error)

        assert_equal 'API Key not set for Anthropic', result[:response][:error][:message]
      end

      def test_call_with_malformed_response
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(
            status: 200,
            body: { id: 'msg_123', role: 'assistant', content: 'not_an_array' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Providers::Anthropic.call(
          api_key: 'test_key',
          system_prompt: 'System',
          messages: [{ role: 'user', content: 'Hi' }]
        )

        assert result[:success]
        message = result[:response][:message]

        assert_equal 'assistant', message['role']
        assert_equal '', message['content']
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
