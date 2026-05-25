# frozen_string_literal: true

module SkillBench
  module Services
    # Finds the registry manifest file path.
    class ManifestFinder
      # Default path relative to current working directory.
      DEFAULT_PATH = '../agent-mcp-runtime/registry.json'

      # Finds the registry manifest file.
      #
      # @param path [String, nil] Optional custom path to the manifest
      # @return [String] Absolute path to the registry manifest
      # @raise [ArgumentError] when the manifest file is not found
      def self.call(path: nil)
        new(path: path).call
      end

      # @param path [String, nil] Optional custom path to the manifest
      def initialize(path: nil)
        @path = path
      end

      # Finds the registry manifest file.
      #
      # @return [String] Absolute path to the registry manifest
      # @raise [ArgumentError] when the manifest file is not found
      def call
        manifest_path = @path || File.expand_path(DEFAULT_PATH, Dir.pwd)
        raise ArgumentError, "Registry manifest not found: #{manifest_path}" unless File.exist?(manifest_path)

        manifest_path
      end
    end
  end
end
