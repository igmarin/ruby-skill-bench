# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module SkillBench
  module Clients
    module Providers
      # xAI (Grok) LLM client.
      # Uses xAI's OpenAI-compatible chat completions API with bearer-token auth.
      class Xai < BaseClient
        SkillBench::Clients::ProviderRegistry.register(:xai, self)

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :xai
        end

        protected

        # Returns the base URL for the xAI API.
        #
        # The version segment lives in {#request_path} so Faraday does not drop
        # it (an absolute request path replaces any path component of the
        # connection base URL).
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.x.ai'
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
