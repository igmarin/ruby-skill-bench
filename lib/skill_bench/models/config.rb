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

      # Returns the configuration for a path, memoizing the parse per run.
      #
      # Hot paths such as {SkillBench::Services::ProviderResolver} resolve the
      # provider on every run, yet skill-bench.json is stable within a single
      # run. The parse is cached per absolute path and invalidated when the
      # file's mtime changes, so the file is parsed at most once per run while
      # a rewritten file (for example between tests) is still re-read. Reset by
      # setting the @loaded ivar to nil.
      #
      # @param path [String] Path to config file (default: skill-bench.json)
      # @return [SkillBench::Models::Config] Memoized config instance
      # @raise [Errno::ENOENT] if config file not found
      def self.loaded(path = 'skill-bench.json')
        key = File.expand_path(path)
        mtime = File.mtime(key)
        cache = (@loaded ||= {})
        entry = cache[key]
        return entry[:config] if entry && entry[:mtime] == mtime

        config = load(path)
        cache[key] = { mtime: mtime, config: config }
        config
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

      # Indicates whether the config explicitly selects the built-in mock
      # provider, as opposed to having no provider configured at all.
      #
      # @return [Boolean] true when the configured provider is 'mock'
      def mock?
        provider_name == 'mock'
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
