# frozen_string_literal: true

module SkillBench
  module Services
    # Builds judge parameters from provider configuration.
    class JudgeParamsBuilder
      # Builds judge parameters from provider configuration.
      #
      # @param provider [Object] The resolved provider
      # @param config [Hash, nil] Provider config
      # @return [Hash] Judge parameters with api_key, model, and provider
      def self.call(provider, config)
        new(provider, config).call
      end

      # @param provider [Object] The resolved provider
      # @param config [Hash, nil] Provider config
      def initialize(provider, config)
        @provider = provider
        @config = config
      end

      # Builds judge parameters from provider configuration.
      #
      # @return [Hash] Judge parameters with api_key, model, and provider
      def call
        return {} if @provider.name == 'mock'

        config = @config || safe_merged_config
        return {} unless config

        {
          api_key: config[:api_key],
          model: config[:model] || @provider.llm,
          provider: @provider.runtime.to_sym
        }
      rescue StandardError
        {}
      end

      private

      # Safely calls merged_config, returning nil on any error.
      #
      # @return [Hash, nil] The merged config or nil
      def safe_merged_config
        @provider.merged_config
      rescue StandardError
        nil
      end
    end
  end
end
