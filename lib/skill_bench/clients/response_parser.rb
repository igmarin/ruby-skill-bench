# frozen_string_literal: true

require 'json'

module SkillBench
  module Clients
    # Parses LLM provider responses and extracts messages and usage data.
    # Handles JSON parsing, message extraction, and validation.
    class ResponseParser
      # Parses the response body into a Hash.
      #
      # @param response [Faraday::Response] The HTTP response
      # @return [Hash] Parsed response body
      def self.parse_body(response)
        return response.body if response.body.is_a?(Hash)
        return { error: { message: response.body.to_s } } if response.body.is_a?(Array)

        JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError
        { error: { message: response.body.to_s } }
      end

      # Strips markdown code fences from a string if present.
      #
      # @param text [String] The text to clean
      # @return [String] Cleaned text
      def self.strip_markdown_fences(text)
        return text unless text.is_a?(String)

        if text.start_with?('```')
          lines = text.each_line.to_a
          lines.shift if lines.first&.strip&.start_with?('```')
          lines.pop if lines.last&.strip == '```'
          lines.join.strip
        else
          text
        end
      end

      # Checks if a message is valid (has content or tool calls).
      #
      # @param message [Hash, String, nil] The message to validate
      # @return [Boolean] True if the message is valid
      def self.valid_message?(message)
        return false if message.nil?

        content = extract_content(message)
        tool_calls = extract_tool_calls(message)

        !content.nil? || !Array(tool_calls).empty?
      end

      # Extracts the content from a message.
      #
      # @param message [Hash, String] The message
      # @return [String, nil] The content or nil
      def self.extract_content(message)
        return message unless message.is_a?(Hash)

        message[:content] || message['content']
      end

      # Extracts tool calls from a message.
      #
      # @param message [Hash] The message
      # @return [Array, nil] The tool calls or nil
      def self.extract_tool_calls(message)
        return nil unless message.is_a?(Hash)

        message[:tool_calls] || message['tool_calls']
      end

      # Extracts the message from an OpenAI-compatible response body.
      #
      # @param body [Hash] The parsed response body
      # @return [Hash, nil] The message or nil
      def self.extract_openai_message(body)
        choices = body[:choices] || body['choices']
        return nil unless choices&.any?

        choices.first[:message] || choices.first['message']
      end

      # Extracts usage data from an OpenAI-compatible response.
      #
      # @param body [Hash] The parsed response body
      # @return [Hash] Usage data
      def self.extract_openai_usage(body)
        body[:usage] || body['usage'] || {}
      end
    end
  end
end
