# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # OpenCode-specific LLM client.
      class OpenCode < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:opencode, self)

        def provider_name
          :opencode
        end

        protected

        # Returns the base URL for OpenCode API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.opencode.ai'
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
