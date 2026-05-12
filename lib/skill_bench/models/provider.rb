# frozen_string_literal: true

require_relative '../provider_schemas'

module SkillBench
  module Models
    # Represents an agent runtime + LLM provider
    class Provider
      attr_reader :name, :runtime, :llm, :config

      ALLOWED_PROVIDERS = (ProviderSchemas.names.map(&:to_s) + %w[mock]).freeze

      # Settings that can be overridden via environment variables.
      ENV_OVERRIDABLE_SETTINGS = %i[api_key model base_url endpoint location project_id api_version].freeze

      # Initialize a new Provider
      # @param name [String] Provider name (e.g., "openai")
      # @param runtime [String] Agent runtime (e.g., "opencode")
      # @param llm [String] LLM provider (e.g., "openai")
      # @param config [Hash] Provider-specific configuration
      def initialize(name:, runtime:, llm:, config: {})
        @name = name
        @runtime = runtime
        @llm = llm
        @config = config.is_a?(Hash) ? config.transform_keys(&:to_sym) : {}
      end

      # Returns merged config with environment variable fallbacks.
      # Checks both `SKILL_BENCH_<PROVIDER>_<SETTING>` (documented standard)
      # and `<PROVIDER>_<SETTING>` (legacy) naming conventions.
      #
      # @return [Hash] Merged configuration
      # @raise [ArgumentError] if provider name is invalid or API key is missing
      def merged_config
        raise ArgumentError, "Invalid provider name: #{name}" unless ALLOWED_PROVIDERS.include?(name)

        merged = config.dup
        ENV_OVERRIDABLE_SETTINGS.each do |setting|
          merged[setting] = resolve_env_setting(setting)
        end

        api_key = merged[:api_key]
        raise ArgumentError, "API key not found for provider '#{name}'. Set SKILL_BENCH_#{name.upcase}_API_KEY environment variable or provide in config." if api_key.nil? || api_key.to_s.empty?

        merged
      end

      private

      # Resolves a single setting from environment variables.
      # Prefers `SKILL_BENCH_<PROVIDER>_<SETTING>`, falls back to
      # `<PROVIDER>_<SETTING>`, then to the config file value.
      #
      # @param setting [Symbol] The setting name (e.g., :api_key)
      # @return [String, nil] The resolved value
      def resolve_env_setting(setting)
        prefixed = ENV.fetch("SKILL_BENCH_#{name.upcase}_#{setting.upcase}", nil)
        return prefixed if prefixed && !prefixed.to_s.empty?

        legacy = ENV.fetch("#{name.upcase}_#{setting.upcase}", nil)
        return legacy if legacy && !legacy.to_s.empty?

        config[setting]
      end
    end
  end
end
