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

        protected

        # @return [String]
        def base_url
          'https://api.anthropic.com'
        end

        # @return [String]
        def request_path
          '/v1/messages'
        end

        # @return [Hash]
        def request_headers
          {
            'x-api-key' => @api_key,
            'anthropic-version' => '2023-06-01',
            'Content-Type' => 'application/json'
          }
        end

        # @return [Hash]
        def request_body
          body = {
            model: @model,
            max_tokens: 4096,
            system: @system_prompt,
            messages: @messages
          }
          body[:tools] = @tools if @tools && !@tools.empty?
          body
        end

        # @return [Boolean]
        def valid_config?
          !@api_key.to_s.strip.empty? && !@model.to_s.strip.empty?
        end

        # @return [Hash]
        def config_error
          missing = []
          missing << 'ANTHROPIC_API_KEY' if @api_key.to_s.strip.empty?
          missing << 'model' if @model.to_s.strip.empty?
          message = if missing.length > 1
                      "#{missing[0...-1].join(', ')}, and #{missing[-1]} not set for Anthropic"
                    else
                      "#{missing.first} not set for Anthropic"
                    end
          { success: false, response: { error: { message: message } } }
        end

        private

        # Extracts the message from Anthropic's response format.
        # Iterates over content blocks to find the first text block.
        #
        # @param body [Hash] The parsed JSON response body.
        # @return [Hash, nil] the text content or nil if not found
        def extract_message(body)
          content = body['content']
          return nil unless content.is_a?(Array)

          # :reek:disable DuplicateMethodCall
          text_block = content.find { |block| block.is_a?(Hash) && block['type'] == 'text' && block.key?('text') }
          text_block&.dig('text')
        end
      end
    end
  end
end
