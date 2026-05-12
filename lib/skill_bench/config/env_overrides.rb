# frozen_string_literal: true

module SkillBench
  class Config
    # Builds configuration overrides from evaluator environment variables.
    class EnvOverrides
      # Mapping from environment variable names to provider configuration keys.
      # Supports both prefixed (SKILL_BENCH_*) and unprefixed variants for
      # backward compatibility. Prefixed variants are the documented standard.
      ENV_TO_PROVIDER_SETTINGS = {
        'SKILL_BENCH_OPENAI_API_KEY' => %i[openai api_key],
        'OPENAI_API_KEY' => %i[openai api_key],
        'SKILL_BENCH_ANTHROPIC_API_KEY' => %i[anthropic api_key],
        'ANTHROPIC_API_KEY' => %i[anthropic api_key],
        'SKILL_BENCH_OPENAI_MODEL' => %i[openai model],
        'OPENAI_MODEL' => %i[openai model],
        'SKILL_BENCH_OPENAI_BASE_URL' => %i[openai base_url],
        'OPENAI_BASE_URL' => %i[openai base_url],
        'SKILL_BENCH_GEMINI_API_KEY' => %i[gemini api_key],
        'GEMINI_API_KEY' => %i[gemini api_key],
        'SKILL_BENCH_GEMINI_LOCATION' => %i[gemini location],
        'GEMINI_LOCATION' => %i[gemini location],
        'SKILL_BENCH_GEMINI_PROJECT_ID' => %i[gemini project_id],
        'GEMINI_PROJECT_ID' => %i[gemini project_id],
        'SKILL_BENCH_GEMINI_MODEL' => %i[gemini model],
        'GEMINI_MODEL' => %i[gemini model],
        'SKILL_BENCH_OLLAMA_BASE_URL' => %i[ollama base_url],
        'OLLAMA_BASE_URL' => %i[ollama base_url],
        'SKILL_BENCH_OLLAMA_MODEL' => %i[ollama model],
        'OLLAMA_MODEL' => %i[ollama model],
        'SKILL_BENCH_AZURE_OPENAI_API_KEY' => %i[azure api_key],
        'AZURE_OPENAI_API_KEY' => %i[azure api_key],
        'SKILL_BENCH_AZURE_OPENAI_ENDPOINT' => %i[azure endpoint],
        'AZURE_OPENAI_ENDPOINT' => %i[azure endpoint],
        'SKILL_BENCH_AZURE_OPENAI_API_VERSION' => %i[azure api_version],
        'AZURE_OPENAI_API_VERSION' => %i[azure api_version],
        'SKILL_BENCH_AZURE_OPENAI_MODEL' => %i[azure model],
        'AZURE_OPENAI_MODEL' => %i[azure model],
        'SKILL_BENCH_ANTHROPIC_MODEL' => %i[anthropic model],
        'ANTHROPIC_MODEL' => %i[anthropic model],
        'SKILL_BENCH_GROQ_API_KEY' => %i[groq api_key],
        'SKILL_BENCH_GROQ_MODEL' => %i[groq model],
        'SKILL_BENCH_DEEPSEEK_API_KEY' => %i[deepseek api_key],
        'SKILL_BENCH_DEEPSEEK_MODEL' => %i[deepseek model],
        'SKILL_BENCH_OPENCODE_API_KEY' => %i[opencode api_key],
        'OPENCODE_API_KEY' => %i[opencode api_key],
        'SKILL_BENCH_OPENCODE_BASE_URL' => %i[opencode base_url],
        'OPENCODE_BASE_URL' => %i[opencode base_url],
        'SKILL_BENCH_OPENCODE_MODEL' => %i[opencode model],
        'OPENCODE_MODEL' => %i[opencode model],
        'SKILL_BENCH_OPENROUTER_API_KEY' => %i[openrouter api_key],
        'SKILL_BENCH_OPENROUTER_MODEL' => %i[openrouter model]
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
        SkillBench::ErrorLogger.log_error(e, 'EnvOverrides Error')
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
