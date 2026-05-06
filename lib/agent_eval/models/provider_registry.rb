# frozen_string_literal: true

require_relative 'provider'

module AgentEval
  module Models
    # Registry for managing agent runtime + LLM providers
    class ProviderRegistry
      attr_reader :providers

      # @param providers [Hash{String => AgentEval::Models::Provider}] Pre-configured providers
      def initialize(providers: {})
        @providers = providers
      end

      # Load providers from a config hash
      # @param config [Hash] Configuration hash containing "providers" key
      # @return [AgentEval::Models::ProviderRegistry] Registry with loaded providers
      def self.load_from_config(config)
        providers = {}
        config.fetch('providers', {}).each do |name, provider_config|
          providers[name] = Provider.new(
            name: name,
            runtime: provider_config['runtime'],
            llm: provider_config['llm'],
            config: provider_config['config'] || {}
          )
        end
        new(providers: providers)
      end

      # Get a provider by name
      # @param name [String] Provider name
      # @return [AgentEval::Models::Provider, nil] Provider instance or nil
      def get(name)
        providers[name]
      end
    end
  end
end
