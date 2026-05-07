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

        def provider_name
          :groq
        end

        protected

        # Returns the base URL for Groq API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.groq.com/openai'
        end

        # Returns the request path for chat completions.
        #
        # @return [String]
        def request_path
          @request_path_config || '/v1/chat/completions'
        end
      end
    end
  end
end
