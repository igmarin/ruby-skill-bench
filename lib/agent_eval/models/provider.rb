# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'

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
        @config = config.deep_symbolize_keys
      end

      # Returns merged config with environment variable fallbacks
      # @return [Hash] Merged configuration
      # @raise [StandardError] if API key is not found in config or env
      def merged_config
        env_key = "AGENT_EVAL_#{name.upcase}_API_KEY"
        config.merge(api_key: ENV[env_key] || config[:api_key])
      end
    end
  end
end
