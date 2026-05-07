# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # Anthropic Claude-specific LLM client.
      # Uses the Messages API endpoint with Claude models.
      class Anthropic < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:anthropic, self)

        VERSION = '2023-06-01'

        def provider_name
          :anthropic
        end

        protected

        # Returns the base URL for Anthropic API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.anthropic.com'
        end

        # Returns the request path for the Messages API.
        #
        # @return [String]
        def request_path
          @request_path_config || '/v1/messages'
        end

        # Returns the headers required for Anthropic API.
        #
        # @return [Hash]
        def request_headers
          {
            'x-api-key' => @api_key,
            'anthropic-version' => VERSION,
            'Content-Type' => 'application/json'
          }
        end

        # Standardizes the request body for Anthropic's Messages API.
        #
        # @return [Hash]
        def request_body
          body = {
            model: @model,
            max_tokens: 4096,
            system: @system_prompt,
            messages: translate_messages(@messages)
          }
          body[:tools] = self.class.translate_tools(@tools) if @tools&.any?
          body
        end

        private

        def extract_message(body)
          content_blocks = body[:content] || body['content']
          return { 'role' => 'assistant', 'content' => '' } unless content_blocks.is_a?(Array)

          grouped = content_blocks.group_by { |block| (block[:type] || block['type']).to_s }
          text_block = grouped['text']&.first
          tool_use_blocks = grouped['tool_use'] || []

          message = {
            'role' => 'assistant',
            'content' => (text_block&.dig(:text) || text_block&.dig('text')) || ''
          }

          if tool_use_blocks.any?
            message['tool_calls'] = tool_use_blocks.map do |block|
              {
                'id' => block[:id] || block['id'],
                'type' => 'function',
                'function' => {
                  'name' => block[:name] || block['name'],
                  'arguments' => (block[:input] || block['input']).to_json
                }
              }
            end
          end

          message
        end

        # Extracts token usage from Anthropic's response.
        #
        # @param body [Hash]
        # @return [Hash]
        def extract_usage(body)
          usage = body[:usage] || body['usage'] || {}
          input = usage[:input_tokens] || usage['input_tokens'] || 0
          output = usage[:output_tokens] || usage['output_tokens'] || 0
          {
            prompt_tokens: input,
            completion_tokens: output,
            total_tokens: input + output
          }
        end

        # Translates a list of messages to Anthropic's expected format.
        # Handles user, assistant, and tool result message types.
        #
        # @param messages [Array<Hash>] List of standardized messages.
        # @return [Array<Hash>] List of messages formatted for Anthropic.
        def translate_messages(messages)
          messages.map { |msg| translate_single_message(msg) }
        end

        # :reek:FeatureEnvy
        # Translates a single message to Anthropic format.
        def translate_single_message(msg)
          klass = self.class
          role = (msg[:role] || msg['role']).to_s
          case role
          when 'assistant' then klass.translate_assistant_message(msg)
          when 'tool'      then klass.translate_tool_message(msg)
          else
            { role: role, content: msg[:content] || msg['content'] }
          end
        end

        class << self
          # Translates standard tool definitions to Anthropic tool format.
          #
          # @param tools [Array<Hash>] List of tool definitions.
          # @return [Array<Hash>] Translated tools for Anthropic.
          def translate_tools(tools)
            tools.map do |tool|
              {
                name: tool.dig(:function, :name) || tool.dig('function', 'name'),
                description: tool.dig(:function, :description) || tool.dig('function', 'description'),
                input_schema: tool.dig(:function, :parameters) || tool.dig('function', 'parameters')
              }
            end
          end

          # Translates assistant message with tool calls to Anthropic format.
          #
          # @param msg [Hash] The assistant message.
          # @return [Hash] Translated message for Anthropic.
          def translate_assistant_message(msg)
            content = []
            text = msg[:content] || msg['content']
            content << { type: 'text', text: text } if text && !text.empty?

            (msg[:tool_calls] || msg['tool_calls'])&.each do |tool_call|
              content << build_tool_use_block(tool_call)
            end

            { role: 'assistant', content: content }
          end

          # Translates tool result message to Anthropic format.
          #
          # @param msg [Hash] The tool result message.
          # @return [Hash] Translated message for Anthropic.
          def translate_tool_message(msg)
            {
              role: 'user',
              content: [
                {
                  type: 'tool_result',
                  tool_use_id: msg[:tool_call_id] || msg['tool_call_id'],
                  content: msg[:content] || msg['content']
                }
              ]
            }
          end

          private

          def build_tool_use_block(tool_call)
            {
              type: 'tool_use',
              id: tool_call[:id] || tool_call['id'],
              name: tool_call.dig(:function, :name) || tool_call.dig('function', 'name'),
              input: parse_tool_arguments(tool_call.dig(:function, :arguments) || tool_call.dig('function', 'arguments'))
            }
          end

          def parse_tool_arguments(args_raw)
            return nil if args_raw.nil?
            return args_raw if args_raw.is_a?(Hash)
            return nil unless args_raw.is_a?(String)

            JSON.parse(args_raw)
          rescue JSON::ParserError
            nil
          end
        end
      end
    end
  end
end
