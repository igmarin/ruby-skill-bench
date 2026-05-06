# frozen_string_literal: true

module AgentEval
  module Models
    # Represents an agent runtime + LLM provider
    class Provider
      attr_reader :name, :runtime, :llm, :config

      # Initialize a new Provider
      # @param name [String] Provider name (e.g., "openai")
      # @param runtime [String] Agent runtime (e.g., "opencode")
      # @param llm [String] LLM provider (e.g., "openai")
      # @param config [Hash] Provider-specific configuration
      def initialize(name:, runtime:, llm:, config: {})
        @name = name
        @runtime = runtime
        @llm = llm
        @config = self.class.symbolize_keys(config)
      end

      # Convert string keys to symbols (shallow, non-recursive)
      # @param hash [Hash] Hash to symbolize
      # @return [Hash] Hash with symbolized keys
      def self.symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[key.to_sym] = value
        end
      end

      private_class_method :symbolize_keys

      # Returns merged config with environment variable fallbacks
      # @return [Hash] Merged configuration
      # @raise [ArgumentError] if API key is not found in config or env
      def merged_config
        env_key = "AGENT_EVAL_#{name.upcase}_API_KEY"
        resolved_key = ENV[env_key] || config[:api_key]

        return config.merge(api_key: resolved_key) if resolved_key && !resolved_key.empty?

        raise ArgumentError, "API key not found for provider '#{name}'. Set #{env_key} environment variable or provide in config."
      end
    end
  end
end
