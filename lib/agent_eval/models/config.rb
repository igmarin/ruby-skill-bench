# frozen_string_literal: true

module AgentEval
  module Models
    # Represents the agent-eval configuration loaded from .agent-eval.yml or custom path
    class Config
      # @param data [Hash] Raw configuration data
      # @raise [ArgumentError] if data is not a Hash
      def initialize(data = {})
        raise ArgumentError, 'Config data must be a Hash' unless data.is_a?(Hash)

        @data = self.class.send(:recursive_symbolize_keys, data)
      end

      # Recursively convert string keys to symbols in nested Hash and Array structures
      # @param obj [Object] Object to symbolize
      # @return [Object] Object with symbolized keys
      def self.recursive_symbolize_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = recursive_symbolize_keys(value)
          end
        when Array
          obj.map { |item| recursive_symbolize_keys(item) }
        else
          obj
        end
      end

      private_class_method :recursive_symbolize_keys

      # Load configuration from a YAML file
      # @param path [String] Path to config file (default: .agent-eval.yml)
      # @return [AgentEval::Models::Config] Loaded config instance
      # @note Missing config files are handled by logging (via Rails.logger if available) and returning an empty config
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
