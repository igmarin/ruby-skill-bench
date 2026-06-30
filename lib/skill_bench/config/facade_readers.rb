# frozen_string_literal: true

module SkillBench
  class Config
    # Reader methods exposed by the Config facade.
    module FacadeReaders
      # Returns the current LLM provider.
      #
      # @return [Symbol, nil] current provider
      def current_llm_provider
        store.current_llm_provider
      end

      # Returns maximum command execution time.
      #
      # @return [Integer, nil] maximum execution time in seconds
      def max_execution_time
        store.max_execution_time
      end

      # Returns allowed command list.
      #
      # @return [Array<String>, nil] allowed commands
      def allowed_commands
        store.allowed_commands
      end

      # Returns whether un-isolated host command execution is permitted.
      #
      # @return [Boolean, nil] true when host execution is explicitly allowed
      def allow_host_execution
        store.allow_host_execution
      end

      # Returns provider configuration.
      #
      # @return [Hash] provider configuration by provider name
      def llm_providers_config
        store.llm_providers_config
      end

      # Returns skill sources mapping.
      #
      # @return [Hash, nil] skill source name → directory path
      def skill_sources
        store.skill_sources
      end

      # Returns the API key for the current LLM provider.
      #
      # @return [String, nil] API key for the current provider
      def api_key
        store.api_key
      end

      # Returns the model for the current LLM provider.
      #
      # @return [String, nil] model name for the current provider
      def model
        store.model
      end

      # Returns the base URL for the current LLM provider.
      #
      # @return [String, nil] base URL for the current provider
      def base_url
        store.base_url
      end

      # Returns configuration for a specific provider.
      #
      # @param provider [Symbol] provider name
      # @return [Hash] configuration for the provider
      def for_provider(provider)
        store.for_provider(provider)
      end
    end
  end
end
