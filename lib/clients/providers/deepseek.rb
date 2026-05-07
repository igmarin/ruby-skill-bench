# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # DeepSeek-specific LLM client.
      # Uses OpenAI-compatible chat completions API.
      class DeepSeek < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:deepseek, self)

        def provider_name
          :deepseek
        end

        protected

        # Returns the base URL for DeepSeek API.
        #
        # @return [String]
        def base_url
          @base_url_config || 'https://api.deepseek.com'
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
