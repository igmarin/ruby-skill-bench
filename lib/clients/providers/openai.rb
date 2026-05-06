# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # OpenAI-specific LLM client.
      # Inherits common logic from BaseClient.
      class OpenAI < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:openai, self)

        protected

        # Returns the base URL for OpenAI API.
        #
        # @return [String]
        def base_url
          'https://api.openai.com'
        end

        # Returns the request path for chat completions.
        #
        # @return [String]
        def request_path
          '/v1/chat/completions'
        end

        # Standardized error response when configuration is missing.
        #
        # @return [Hash]
        def config_error
          { success: false, response: { error: { message: 'OPENAI_API_KEY is not set in config for OpenAI' } } }
        end
      end
    end
  end
end
