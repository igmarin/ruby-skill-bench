# frozen_string_literal: true

module SkillBench
  class Config
    # Holds mutable evaluator configuration state behind the Config facade.
    class Store
      # Returns the current provider name.
      #
      # @return [Symbol, nil] current provider
      attr_accessor :current_llm_provider

      # Returns the maximum command execution time.
      #
      # @return [Integer, nil] maximum execution time in seconds
      attr_reader :max_execution_time

      # Returns the allowed command list.
      #
      # @return [Array<String>, nil] allowed commands
      attr_accessor :allowed_commands

      # Returns provider configuration.
      #
      # @return [Hash, nil] provider configuration by provider name
      attr_accessor :llm_providers_config

      # Returns skill sources mapping.
      #
      # @return [Hash, nil] skill source name → directory path
      attr_accessor :skill_sources

      # Initializes a new configuration store with empty provider settings.
      def initialize
        @llm_providers_config = {}
      end

      # Returns the API key for the current provider.
      #
      # @return [String, nil] configured API key
      def api_key
        llm_providers_config.dig(current_llm_provider, :api_key)
      end

      # Returns the model for the current provider.
      #
      # @return [String, nil] configured model name
      def model
        llm_providers_config.dig(current_llm_provider, :model)
      end

      # Returns the base URL for the current provider.
      #
      # @return [String, nil] configured base URL
      def base_url
        llm_providers_config.dig(current_llm_provider, :base_url)
      end

      # Returns configuration for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @return [Hash] configuration for the provider
      def for_provider(provider)
        llm_providers_config[provider.to_sym] || {}
      end

      # Applies provider-specific configuration values.
      #
      # @param providers [Hash] provider configuration by provider name
      # @return [Hash] provider configuration
      def apply_provider_config(providers)
        providers.each do |provider, config|
          provider_config(provider).merge!(config)
        end
      end

      # Sets one provider-specific configuration value.
      #
      # @param provider [String, Symbol] provider name
      # @param setting [Symbol] provider setting name
      # @param value [Object] provider setting value
      # @return [Object] assigned value
      def set_provider_setting(provider, setting, value)
        provider_config(provider)[setting] = value
      end

      # Sets the current provider.
      #
      # @param value [String, Symbol] provider name
      # @return [Symbol, nil] assigned provider
      def assign_current_llm_provider(value)
        stripped = value.to_s.strip
        @current_llm_provider = stripped.empty? ? nil : stripped.to_sym
        @current_llm_provider
      end

      # Sets maximum command execution time.
      #
      # @param value [Integer] maximum execution time in seconds
      # @return [Integer] assigned maximum execution time
      def assign_max_execution_time(value)
        @max_execution_time = value
      end

      # Sets allowed commands.
      #
      # @param value [Array<String>, nil] allowed command list
      # @return [Array<String>, nil] assigned allowed commands
      def assign_allowed_commands(value)
        @allowed_commands = value
      end

      # Sets provider configuration.
      #
      # @param value [Hash] provider configuration
      # @return [Hash] assigned provider configuration
      def replace_provider_config(value)
        @llm_providers_config = value
      end

      # Sets API key for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @param api_key [String] API key value
      # @return [String] assigned API key
      def set_provider_api_key(provider, api_key)
        provider_config(provider)[:api_key] = api_key
      end

      # Sets model for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @param model [String] model name
      # @return [String] assigned model
      def set_provider_model(provider, model)
        provider_config(provider)[:model] = model
      end

      # Sets endpoint for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @param endpoint [String] endpoint URL
      # @return [String] assigned endpoint
      def set_provider_endpoint(provider, endpoint)
        provider_config(provider)[:endpoint] = endpoint
      end

      # Sets location for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @param location [String] location
      # @return [String] assigned location
      def set_provider_location(provider, location)
        provider_config(provider)[:location] = location
      end

      # Sets project_id for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @param project_id [String] project ID
      # @return [String] assigned project_id
      def set_provider_project_id(provider, project_id)
        provider_config(provider)[:project_id] = project_id
      end

      # Sets base_url for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @param base_url [String] base URL
      # @return [String] assigned base_url
      def set_provider_base_url(provider, base_url)
        provider_config(provider)[:base_url] = base_url
      end

      private

      def provider_config(provider)
        @llm_providers_config ||= {}
        @llm_providers_config[provider.to_sym] ||= {}
      end
    end
  end
end
