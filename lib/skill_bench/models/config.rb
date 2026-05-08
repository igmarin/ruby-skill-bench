# frozen_string_literal: true

require 'json'
require_relative 'provider'

module SkillBench
  module Models
    # Represents the skill-bench configuration loaded from skill-bench.json
    class Config
      # @param data [Hash] Raw configuration data
      # @raise [ArgumentError] if data is not a Hash
      def initialize(data = {})
        raise ArgumentError, 'Config-data must be a Hash' unless data.is_a?(Hash)

        @data = data
      end

      # Load configuration from a JSON file
      # @param path [String] Path to config file (default: skill-bench.json)
      # @return [SkillBench::Models::Config] Loaded config instance
      # @raise [Errno::ENOENT] if config file not found
      def self.load(path = 'skill-bench.json')
        raw_data = JSON.parse(File.read(path), symbolize_names: true)
        new(raw_data)
      end

      # Returns the configured provider name
      # @return [String, nil] Provider name
      def provider_name
        @data[:provider]
      end

      # Returns the provider configuration
      # @return [Hash] Provider configuration
      def provider_config
        @data[:config] || {}
      end

      # Returns max execution time
      # @return [Integer] Max execution time in seconds
      def max_execution_time
        @data[:max_execution_time] || 30
      end

      # Builds a Provider model from the current configuration.
      # Returns a mock provider if provider name is 'mock'.
      #
      # @return [SkillBench::Models::Provider] The configured provider
      def to_provider
        return nil if provider_name.nil? || provider_name == 'mock'

        Provider.new(
          name: provider_name,
          runtime: provider_name,
          llm: provider_name,
          config: provider_config
        )
      end
    end
  end
end
