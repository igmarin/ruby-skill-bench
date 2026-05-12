# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module SkillBench
  module Clients
    module Providers
      # OpenRouter LLM client.
      # Uses OpenRouter's OpenAI-compatible API to access multiple model providers.
      # Inherits common logic from BaseClient.
      class OpenRouter < BaseClient
        SkillBench::Clients::ProviderRegistry.register(:openrouter, self)

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :openrouter
        end

        protected

        # Returns the base URL for OpenRouter API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://openrouter.ai'
        end

        # Returns the request path for chat completions.
        #
        # @return [String]
        def request_path
          @request_path_config || '/api/v1/chat/completions'
        end
      end
    end
  end
end
