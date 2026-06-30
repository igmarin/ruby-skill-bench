# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module SkillBench
  module Clients
    module Providers
      # Mistral (la Plateforme) LLM client.
      # Uses Mistral's OpenAI-compatible chat completions API with bearer-token auth.
      #
      # NOTE: AWS Bedrock access to Mistral models (which requires SigV4 request
      # signing rather than a static bearer token) is intentionally not handled
      # here and is left as a follow-up.
      class Mistral < BaseClient
        SkillBench::Clients::ProviderRegistry.register(:mistral, self)

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :mistral
        end

        protected

        # Returns the base URL for the Mistral API.
        #
        # The Mistral API base is https://api.mistral.ai/v1; the version segment
        # lives in {#request_path} so Faraday does not drop it (an absolute
        # request path replaces any path component of the connection base URL).
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.mistral.ai'
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
