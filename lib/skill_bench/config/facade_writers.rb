# frozen_string_literal: true

module SkillBench
  class Config
    # Writer methods exposed by the Config facade.
    module FacadeWriters
      # Public writer method names mapped to provider setting keys.
      PROVIDER_SETTINGS = {
        api_key: :api_key,
        model: :model,
        location: :location,
        project_id: :project_id,
        base_url: :base_url,
        endpoint: :endpoint,
        api_version: :api_version
      }.freeze

      # Dynamically sets a specific provider's API key.
      #
      # @param provider [String, Symbol] provider name
      # @param key [String, nil] provider API key
      # @return [String, nil] assigned API key
      def set_provider_api_key(provider, key)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:api_key), key)
      end

      # Dynamically sets a specific provider's model.
      #
      # @param provider [String, Symbol] provider name
      # @param model_name [String] provider model name
      # @return [String] assigned model name
      def set_provider_model(provider, model_name)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:model), model_name)
      end

      # Dynamically sets a specific provider's location.
      #
      # @param provider [String, Symbol] provider name
      # @param location_name [String] provider location
      # @return [String] assigned location
      def set_provider_location(provider, location_name)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:location), location_name)
      end

      # Dynamically sets a specific provider's project ID.
      #
      # @param provider [String, Symbol] provider name
      # @param project_id_value [String, nil] provider project ID
      # @return [String, nil] assigned project ID
      def set_provider_project_id(provider, project_id_value)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:project_id), project_id_value)
      end

      # Dynamically sets a specific provider's base URL.
      #
      # @param provider [String, Symbol] provider name
      # @param base_url_value [String, nil] provider base URL
      # @return [String, nil] assigned base URL
      def set_provider_base_url(provider, base_url_value)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:base_url), base_url_value)
      end

      # Dynamically sets a specific provider's endpoint (Azure OpenAI).
      #
      # @param provider [String, Symbol] provider name
      # @param endpoint_value [String, nil] provider endpoint URL
      # @return [String, nil] assigned endpoint
      def set_provider_endpoint(provider, endpoint_value)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:endpoint), endpoint_value)
      end

      # Dynamically sets a specific provider's API version (Azure OpenAI).
      #
      # @param provider [String, Symbol] provider name
      # @param version_value [String, nil] provider API version
      # @return [String, nil] assigned API version
      def set_provider_api_version(provider, version_value)
        set_provider_setting(provider, PROVIDER_SETTINGS.fetch(:api_version), version_value)
      end

      # Sets the current LLM provider.
      #
      # @param value [String, Symbol] provider name
      # @return [Symbol, nil] assigned provider name
      def current_llm_provider=(value)
        store.assign_current_llm_provider(value)
      end

      # Sets the maximum command execution time.
      #
      # @param value [Integer] maximum execution time in seconds
      # @return [Integer] assigned maximum execution time
      def max_execution_time=(value)
        store.assign_max_execution_time(value)
      end

      # Sets the allowed command list.
      #
      # @param value [Array<String>, nil] allowed command list
      # @return [Array<String>, nil] assigned allowed commands
      def allowed_commands=(value)
        store.assign_allowed_commands(value)
      end

      # Sets whether un-isolated host command execution is permitted.
      #
      # @param value [Boolean] true to permit un-isolated host execution
      # @return [Boolean] assigned host execution flag
      def allow_host_execution=(value)
        store.assign_allow_host_execution(value)
      end

      # Replaces provider configuration.
      #
      # @param value [Hash] provider configuration
      # @return [Hash] assigned provider configuration
      def llm_providers_config=(value)
        store.replace_provider_config(value)
      end

      private

      def set_provider_setting(provider, setting, value)
        store.set_provider_setting(provider, setting, value)
      end
    end
  end
end
