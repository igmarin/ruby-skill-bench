# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # Ollama-specific LLM client.
      # Extends BaseClient to interact with an Ollama server (commonly used for open‑source models such as Qwen 3.5).
      # Ollama does not require an API key but requires a model to be configured.
      class Ollama < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:ollama, self)
        # api_key and model are inherited from BaseClient

        protected

        # Returns the base URL for Ollama service.
        # Checks the OLLAMA_BASE_URL env var, then the evaluator config, then falls back to localhost.
        #
        # @return [String]
        def base_url
          env_url = ENV.fetch('OLLAMA_BASE_URL', nil)
          return env_url unless env_url.to_s.empty?

          config_url = Evaluator::Config.llm_providers_config.dig(:ollama, :base_url)
          return config_url unless config_url.to_s.empty?

          'http://localhost:11434'
        end

        # Returns the request path for chat completions.
        #
        # @return [String]
        def request_path
          '/v1/chat/completions'
        end

        # Standardized error response when model is missing.
        #
        # @return [Hash]
        def config_error
          { success: false, response: { error: { message: 'OLLAMA_MODEL not set for Ollama' } } }
        end

        # Validates that a model is configured.
        #
        # @return [Boolean]
        def valid_config?
          !@model.to_s.empty?
        end

        # Returns headers for the request.
        #
        # @return [Hash]
        def request_headers
          headers = { 'Content-Type' => 'application/json' }
          headers['Authorization'] = "Bearer #{@api_key}" if @api_key && !@api_key.to_s.empty?
          headers
        end
      end
    end
  end
end
