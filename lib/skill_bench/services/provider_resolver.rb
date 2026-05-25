# frozen_string_literal: true

require_relative '../models/config'
require_relative '../models/provider'

module SkillBench
  module Services
    # Resolves the provider and its configuration.
    class ProviderResolver
      # Stand-in provider when no LLM config is available.
      MOCK_PROVIDER = Struct.new(:name, :runtime, :llm, :merged_config)
      private_constant :MOCK_PROVIDER

      # Resolves the provider and its configuration.
      #
      # @return [Hash] Result with keys:
      #   - success: Boolean indicating if resolution succeeded
      #   - provider: The resolved provider instance
      #   - config: The merged provider config (if successful)
      #   - error: The error object (if failed)
      def self.call
        new.call
      end

      # Resolves the provider and its configuration.
      #
      # @return [Hash] Result with keys:
      #   - success: Boolean indicating if resolution succeeded
      #   - provider: The resolved provider instance
      #   - config: The merged provider config (if successful)
      #   - error: The error object (if failed)
      def call
        provider = resolve_provider
        config_result = resolve_provider_config(provider)

        if config_result[:success]
          {
            success: true,
            provider: provider,
            config: config_result[:config]
          }
        else
          {
            success: false,
            provider: provider,
            error: config_result[:error]
          }
        end
      end

      private

      def resolve_provider
        config = SkillBench::Models::Config.load
        provider = config.to_provider
        return provider if provider

        warn 'Config load failed, using mock provider'
        MOCK_PROVIDER.new('mock', 'mock', 'mock', {})
      end

      def resolve_provider_config(provider)
        { success: true, config: provider.merged_config }
      rescue ArgumentError => e
        { success: false, error: e }
      end
    end
  end
end
