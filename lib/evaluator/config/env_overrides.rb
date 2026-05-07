# frozen_string_literal: true

module Evaluator
  class Config
    # Builds configuration overrides from evaluator environment variables.
    class EnvOverrides
      # Mapping from environment variable names to provider configuration keys.
      ENV_TO_PROVIDER_SETTINGS = {
        'OPENAI_API_KEY' => %i[openai api_key],
        'ANTHROPIC_API_KEY' => %i[anthropic api_key],
        'OPENAI_MODEL' => %i[openai model],
        'OPENAI_BASE_URL' => %i[openai base_url],
        'GEMINI_API_KEY' => %i[gemini api_key],
        'GEMINI_LOCATION' => %i[gemini location],
        'GEMINI_PROJECT_ID' => %i[gemini project_id],
        'GEMINI_MODEL' => %i[gemini model],
        'OLLAMA_BASE_URL' => %i[ollama base_url],
        'OLLAMA_MODEL' => %i[ollama model],
        'AZURE_OPENAI_API_KEY' => %i[azure api_key],
        'AZURE_OPENAI_ENDPOINT' => %i[azure endpoint],
        'AZURE_OPENAI_API_VERSION' => %i[azure api_version],
        'AZURE_OPENAI_MODEL' => %i[azure model],
        'ANTHROPIC_MODEL' => %i[anthropic model],
        'OPENCODE_API_KEY' => %i[opencode api_key],
        'OPENCODE_BASE_URL' => %i[opencode base_url],
        'OPENCODE_MODEL' => %i[opencode model]
      }.freeze

      # Returns provider overrides from the given environment.
      #
      # @param env [Hash] environment-like object keyed by variable name
      # @return [Hash] result envelope with provider configuration overrides
      def self.call(env: ENV)
        new(env:).call
      end

      # Initializes the override builder.
      #
      # @param env [Hash] environment-like object keyed by variable name
      # @return [EnvOverrides] an override builder instance
      def initialize(env:)
        @env = env
      end

      # Returns provider overrides from configured environment variables.
      #
      # @return [Hash] result envelope with provider configuration overrides
      def call
        { success: true, response: { overrides: provider_overrides } }
      rescue StandardError => e
        { success: false, response: { error: { message: e.message } } }
      end

      # Mutable accumulator for provider override hashes.
      class ProviderOverrides
        # Assigns one provider override.
        #
        # @param provider [Symbol] provider name
        # @param setting [Symbol] provider setting
        # @param value [Object] override value
        # @return [Object] assigned value
        def assign(provider, setting, value)
          provider_overrides(provider)[setting] = value
        end

        # Returns accumulated overrides as a hash.
        #
        # @return [Hash] provider configuration overrides
        def to_h
          @to_h ||= {}
        end

        private

        def provider_overrides(provider)
          to_h.fetch(provider) { to_h[provider] = {} }
        end
      end

      private

      def provider_overrides
        ENV_TO_PROVIDER_SETTINGS.each_with_object(ProviderOverrides.new) do |(env_key, (provider, setting)), overrides|
          value = @env.fetch(env_key, nil)
          overrides.assign(provider, setting, value) if value
        end.to_h
      end
    end
  end
end
