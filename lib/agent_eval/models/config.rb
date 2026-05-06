# frozen_string_literal: true

require 'active_support/core_ext/hash'

module AgentEval
  module Models
    # Represents the agent-eval configuration loaded from .agent-eval.yml or custom path
    class Config
      # @param data [Hash] Raw configuration data
      # @raise [ArgumentError] if data is not a Hash
      def initialize(data = {})
        raise ArgumentError, 'Config data must be a Hash' unless data.is_a?(Hash)

        @data = data.deep_symbolize_keys
      end

      # Load configuration from a YAML file
      # @param path [String] Path to config file (default: .agent-eval.yml)
      # @return [AgentEval::Models::Config] Loaded config instance
      # @raise [Errno::ENOENT] if config file does not exist
      def self.load(path = '.agent-eval.yml')
        raw_data = YAML.safe_load_file(path, permitted_classes: [Symbol]) || {}
        new(raw_data)
      rescue Errno::ENOENT
        Rails.logger.error("Config file not found: #{path}") if defined?(Rails)
        new({})
      end

      # Returns configured providers
      # @return [Hash] Provider configurations keyed by provider name
      def providers
        @data.fetch(:providers, {})
      end
    end
  end
end
