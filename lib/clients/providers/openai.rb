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

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :openai
        end

        protected

        # Returns the base URL for OpenAI API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.openai.com'
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
