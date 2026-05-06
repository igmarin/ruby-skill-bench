# frozen_string_literal: true

require_relative '../base_client'

module Evaluator
  module Clients
    module Providers
      # Null Object implementation for unsupported LLM providers.
      # Extends BaseClient for interface consistency.
      class NullClient < BaseClient
        protected

        # Always returns an empty string for the base URL.
        #
        # @return [String]
        def base_url
          ''
        end

        # Always returns an empty string for the request path.
        #
        # @return [String]
        def request_path
          ''
        end

        # Standardized error response for unsupported providers.
        #
        # @return [Hash]
        def config_error
          provider = Evaluator::Config.current_llm_provider
          { success: false, response: { error: { message: "Unsupported or unconfigured LLM provider: '#{provider}'" } } }
        end

        # NullClient is never valid - always returns config error.
        # @return [false]
        def valid_config?
          false
        end
      end
    end
  end
end
