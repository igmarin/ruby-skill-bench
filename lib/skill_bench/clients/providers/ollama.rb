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

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :ollama
        end

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

        # Returns headers for the request. Authorization is included only when an API key is present.
        #
        # @return [Hash]
        def request_headers
          headers = { 'Content-Type' => 'application/json' }
          headers['Authorization'] = "Bearer #{@api_key}" if @api_key && !@api_key.to_s.empty?
          headers
        end

        # Ollama only requires a model; an API key is optional.
        #
        # @return [Array<String>]
        def missing_config_keys
          @model.to_s.strip.empty? ? ['OLLAMA_MODEL'] : []
        end
      end
    end
  end
end
