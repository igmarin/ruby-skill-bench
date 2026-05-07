# frozen_string_literal: true

require_relative '../config'

module Evaluator
  module Clients
    # Service object to load and validate provider configuration.
    class ProviderConfig
      # @param provider [Symbol] provider identifier (e.g., :openai, :ollama)
      # @param options [Hash] override options
      # @return [Hash] standardized configuration
      def self.call(provider:, options: {})
        new(provider, options).call
      end

      def initialize(provider, options)
        @provider = provider.to_sym
        @options = options
        @config = Evaluator::Config.for_provider(@provider) || {}
      end

      # Loads and returns standardized provider configuration.
      #
      # @return [Hash] Standardized configuration with api_key, model, base_url, etc.
      def call
        {
          api_key: fetch_config(:api_key),
          model: fetch_config(:model),
          base_url: fetch_config(:base_url),
          request_path: fetch_config(:request_path),
          provider_name: @provider.to_s.capitalize,
          # Provider-specific extras (nil when not present)
          endpoint: fetch_config(:endpoint),
          location: fetch_config(:location),
          project_id: fetch_config(:project_id),
          api_version: fetch_config(:api_version)
        }
      end

      private

      def fetch_config(key)
        @options[key] || @config[key]
      end
    end
  end
end
