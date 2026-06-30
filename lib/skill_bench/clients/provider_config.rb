# frozen_string_literal: true

require_relative '../config'
require_relative 'base_url_validator'

module SkillBench
  module Clients
    # Service object to load and validate provider configuration.
    class ProviderConfig
      # @param provider [Symbol] provider identifier (e.g., :openai, :ollama)
      # @param options [Hash] override options
      # @return [Hash] standardized configuration
      def self.call(provider:, options: {})
        new(provider, options).call
      end

      # @param provider [Symbol, String] provider identifier, coerced to a Symbol (e.g., :openai, :ollama)
      # @param options [Hash] override options that take precedence over the loaded provider config
      def initialize(provider, options)
        @provider = provider.to_sym
        @options = options
        @config = SkillBench::Config.for_provider(@provider) || {}
      end

      # Loads and returns standardized provider configuration.
      #
      # The resolved transport URLs (`base_url` and, for Azure, `endpoint`) are
      # validated before being returned: they must be absolute http(s) URLs, and
      # a credential is never sent over cleartext http to a non-loopback host.
      #
      # @raise [BaseUrlValidator::InvalidBaseURLError] when a transport URL is
      #   structurally invalid or would leak the credential over cleartext http.
      # @return [Hash] Standardized configuration with api_key, model, base_url, etc.
      def call
        validate_transport_urls!
        standardized_config
      end

      private

      def standardized_config
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

      # Validates every transport URL that could carry the credential. Both
      # `base_url` and Azure's `endpoint` are user-supplied URLs that the
      # authenticated request targets, so both are checked with one helper.
      #
      # @raise [BaseUrlValidator::InvalidBaseURLError] on an invalid/insecure URL.
      # @return [void]
      def validate_transport_urls!
        has_credential = !fetch_config(:api_key).to_s.empty?
        allow_insecure = truthy?(fetch_config(:allow_insecure_base_url))

        [fetch_config(:base_url), fetch_config(:endpoint)].each do |url|
          BaseUrlValidator.call(base_url: url, has_credential: has_credential, allow_insecure: allow_insecure)
        end
      end

      def truthy?(value)
        value == true || value.to_s.strip.casecmp?('true')
      end

      def fetch_config(key)
        @options[key] || @config[key]
      end
    end
  end
end
