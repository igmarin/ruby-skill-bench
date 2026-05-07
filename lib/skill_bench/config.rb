# frozen_string_literal: true

require 'pathname'
require_relative 'config/defaults'
require_relative 'config/store'
require_relative 'config/applier'
require_relative 'config/json_loader'
require_relative 'config/env_overrides'
require_relative 'config/facade_readers'
require_relative 'config/facade_writers'

module SkillBench
  # Centralized configuration for the SkillBench system.
  # Supports hierarchical loading: Defaults < Home JSON < Local JSON < ENV Variables.
  # :reek:Attribute
  class Config
    # File name used for local and home evaluator configuration.
    CONFIG_FILENAME = 'skill-bench.json'

    class << self
      include Config::FacadeReaders
      include Config::FacadeWriters

      # Returns the mutable configuration store behind the facade.
      # Lazily initializes configuration on first access.
      #
      # @return [Config::Store] configuration state store
      def store
        @store ||= Config::Store.new
      end

      # Returns the default configuration.
      #
      # @return [Hash] default configuration hash
      def defaults
        Config::Defaults.call
      end

      # Applies configuration from the store.
      #
      # @return [Hash] applied configuration
      def apply
        Config::Applier.call(store.to_h)
      end

      # Loads configuration from a JSON file.
      #
      # @param path [String] Path to JSON file
      # @return [Hash] loaded configuration
      def load_from_file(path)
        Config::JsonLoader.call(path)
      end

      # Saves configuration to a JSON file.
      #
      # @param path [String] Path to JSON file
      # @param config [Hash] Configuration to save
      # @return [void]
      def save_to_file(path, config)
        Config::FacadeWriters.save_to_file(path, config)
      end

      # Returns configuration overrides from environment variables.
      #
      # @return [Hash] environment-based overrides
      def env_overrides
        Config::EnvOverrides.call
      end

      # Resets the configuration store to defaults.
      #
      # @return [void]
      def reset
        @store = nil
      end

      # Sets up configuration with a block.
      #
      # @yieldparam config [Config::Store] Configuration store for modification
      # @return [void]
      def setup
        yield store
      end

      # Returns allowed commands from configuration.
      #
      # @return [Array<String>, nil] List of allowed commands
      def allowed_commands
        store.to_h[:allowed_commands]
      end

      # Returns max execution time from configuration.
      #
      # @return [Integer] Maximum execution time in seconds
      def max_execution_time
        store.to_h[:max_execution_time] || 30
      end

      # Returns the current LLM provider name.
      #
      # @return [Symbol] Current provider name
      def current_llm_provider
        store.to_h[:current_llm_provider] || :openai
      end

      # Sets the current LLM provider.
      #
      # @param provider [Symbol] Provider name
      # @return [void]
      def current_llm_provider=(provider)
        store.to_h[:current_llm_provider] = provider
      end

      # Returns LLM providers configuration.
      #
      # @return [Hash] Providers configuration
      def llm_providers_config
        store.to_h[:llm_providers_config] || {}
      end
    end
  end
end
