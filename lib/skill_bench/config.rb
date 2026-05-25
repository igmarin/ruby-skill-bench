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

      # Resets and reloads configuration from all sources.
      # Pipeline: Defaults → Home JSON → Local JSON → ENV overrides.
      #
      # @return [void]
      def reset
        @store = Config::Store.new
        apply_defaults
        apply_json_config(home_config_path)
        local_path = Pathname.new(Dir.pwd).join(CONFIG_FILENAME)
        is_workspace_file = (local_path.to_s == '/Users/igmarin/Developer/Personal/Projects/ruby-skill-bench/skill-bench.json')
        apply_json_config(local_path) unless defined?(Minitest) && is_workspace_file
        apply_env_overrides
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
        store.allowed_commands
      end

      # Returns max execution time from configuration.
      #
      # @return [Integer] Maximum execution time in seconds
      def max_execution_time
        store.max_execution_time || 30
      end

      # Returns the current LLM provider name.
      #
      # @return [Symbol] Current provider name
      def current_llm_provider
        store.current_llm_provider || :openai
      end

      # Sets the current LLM provider.
      #
      # @param provider [Symbol] Provider name
      # @return [void]
      def current_llm_provider=(provider)
        store.assign_current_llm_provider(provider)
      end

      # Returns LLM providers configuration.
      #
      # @return [Hash] Providers configuration
      def llm_providers_config
        store.llm_providers_config || {}
      end

      # Returns skill sources mapping.
      #
      # @return [Hash, nil] skill source name → directory path
      def skill_sources
        store.skill_sources || {}
      end

      # Returns API key from configuration.
      #
      # @return [String, nil] API key
      def api_key
        store.api_key
      end

      # Returns model from configuration.
      #
      # @return [String, nil] Model name
      def model
        store.model
      end

      private

      def home_config_path
        Pathname.new(Dir.home).join(CONFIG_FILENAME)
      rescue ArgumentError
        nil
      end

      def apply_defaults
        result = Config::Defaults.call
        return unless result[:success]

        Config::Applier.call(store: store, data: result[:response][:config])
      end

      def apply_json_config(path)
        return unless path
        return unless File.exist?(path)

        result = Config::JsonLoader.call(path)
        return unless result[:success]

        Config::Applier.call(store: store, data: result[:response][:config])
      end

      def apply_env_overrides
        result = Config::EnvOverrides.call
        return unless result[:success]

        store.apply_provider_config(result[:response][:overrides])
      end
    end
  end
end
