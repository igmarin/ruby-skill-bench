# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class ResponseParserTest < Minitest::Test
      def test_parse_body_with_hash_response
        response = Struct.new(:body).new({ choices: [{ message: { content: 'hello' } }] })
        result = ResponseParser.parse_body(response)

        assert_equal 'hello', result[:choices][0][:message][:content]
      end

      def test_parse_body_with_json_string
        response = Struct.new(:body).new('{"choices":[{"message":{"content":"hello"}}]}')
        result = ResponseParser.parse_body(response)

        assert_equal 'hello', result[:choices][0][:message][:content]
      end

      def test_parse_body_with_invalid_json
        response = Struct.new(:body).new('not json')
        result = ResponseParser.parse_body(response)

        assert result[:error]
        assert_includes result[:error][:message], 'not json'
      end

      def test_valid_message_with_content
        message = { content: 'hello' }

        assert ResponseParser.valid_message?(message)
      end

      def test_valid_message_with_tool_calls
        message = { content: nil, tool_calls: [{ id: '1' }] }

        assert ResponseParser.valid_message?(message)
      end

      def test_invalid_message_nil
        refute ResponseParser.valid_message?(nil)
      end

      def test_invalid_message_empty
        message = { content: nil, tool_calls: nil }

        refute ResponseParser.valid_message?(message)
      end

      def test_invalid_message_content_nil_with_empty_tool_calls
        message = { content: nil, tool_calls: [] }

        refute ResponseParser.valid_message?(message)
      end

      def test_invalid_message_content_nil_with_no_tool_calls_key
        message = { content: nil }

        refute ResponseParser.valid_message?(message)
      end

      def test_valid_message_with_empty_string_content
        message = { content: '' }

        assert ResponseParser.valid_message?(message)
      end

      def test_valid_message_with_empty_string_content_and_tool_calls
        message = { content: '', tool_calls: [{ id: '1' }] }

        assert ResponseParser.valid_message?(message)
      end

      def test_extract_content_from_hash
        message = { content: 'hello' }

        assert_equal 'hello', ResponseParser.extract_content(message)
      end

      def test_extract_content_from_string
        assert_equal 'hello', ResponseParser.extract_content('hello')
      end

      def test_extract_tool_calls
        message = { tool_calls: [{ id: '1' }] }

        assert_equal [{ id: '1' }], ResponseParser.extract_tool_calls(message)
      end

      def test_extract_openai_message
        body = { choices: [{ message: { content: 'hello' } }] }
        result = ResponseParser.extract_openai_message(body)

        assert_equal 'hello', result[:content]
      end

      def test_extract_openai_message_with_empty_choices
        body = { choices: [] }

        assert_nil ResponseParser.extract_openai_message(body)
      end

      def test_extract_openai_usage
        body = { usage: { prompt_tokens: 10, completion_tokens: 20 } }
        result = ResponseParser.extract_openai_usage(body)

        assert_equal 10, result[:prompt_tokens]
        assert_equal 20, result[:completion_tokens]
      end

      def test_extract_openai_usage_empty
        body = {}
        result = ResponseParser.extract_openai_usage(body)

        assert_equal({}, result)
      end
    end
  end
end
