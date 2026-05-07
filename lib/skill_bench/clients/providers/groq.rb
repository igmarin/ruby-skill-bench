# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # Groq-specific LLM client.
      # Uses OpenAI-compatible chat completions API.
      class Groq < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:groq, self)

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :groq
        end

        protected

        # Returns the base URL for Groq API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.groq.com/openai/v1'
        end

        # Returns the request path for chat completions.
        #
        # @return [String]
        def request_path
          @request_path_config || '/chat/completions'
        end
      end
    end
  end
end
