# frozen_string_literal: true

require 'json'
require_relative '../clients/provider_schemas'

module SkillBench
  module Commands
    # Handles the `skill-bench init` command.
    # Generates a skill-bench.json config file with single-provider settings.
    class Init
      # Run the init command to generate config.
      #
      # @param provider [Symbol] LLM provider name (e.g., :openai, :gemini)
      # @param force [Boolean] Whether to overwrite an existing config file.
      # @return [void]
      # @raise [RuntimeError] if config file exists and force is false
      # @raise [ArgumentError] if provider is not registered
      def self.run(provider:, force: false)
        raise "Config file '#{SkillBench::Config::CONFIG_FILENAME}' already exists. Use --force to overwrite." if File.exist?(SkillBench::Config::CONFIG_FILENAME) && !force

        config = config_for_provider(provider)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.pretty_generate(config))
      end

      # Generates configuration hash for a specific provider.
      #
      # The built-in `:mock` provider needs no credentials, so it produces a
      # minimal offline config without a nested `config:` block.
      #
      # @param provider [Symbol] LLM provider name
      # @return [Hash] Single-provider configuration
      # @raise [ArgumentError] if provider is not registered
      def self.config_for_provider(provider)
        return { provider: :mock, max_execution_time: 30 } if provider == :mock

        {
          provider: provider,
          max_execution_time: 30,
          config: SkillBench::Clients::ProviderSchemas.for(provider)
        }
      end
    end
  end
end
