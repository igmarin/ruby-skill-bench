# frozen_string_literal: true

require_relative '../provider_schemas'

module SkillBench
  module Models
    # Represents an agent runtime + LLM provider
    class Provider
      attr_reader :name, :runtime, :llm, :config

      ALLOWED_PROVIDERS = (ProviderSchemas.names.map(&:to_s) + %w[mock]).freeze

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

      # Returns merged config with environment variable fallbacks
      # @return [Hash] Merged configuration
      # @raise [ArgumentError] if API key is not found in config or env
      def merged_config
        raise ArgumentError, "Invalid provider name: #{name}" unless ALLOWED_PROVIDERS.include?(name)

        env_key = "SKILL_BENCH_#{name.upcase}_API_KEY"
        resolved_key = ENV[env_key] || config[:api_key]

        return config.merge(api_key: resolved_key) if resolved_key && !resolved_key.empty?

        raise ArgumentError, "API key not found for provider '#{name}'. Set #{env_key} environment variable or provide in config."
      end
    end
  end
end
