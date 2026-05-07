# frozen_string_literal: true

require 'yaml'
require 'json' # for symbolize_names

module SkillBench
  module Migration
    # Migrates old provider classes to new YAML-based configuration
    class ProviderMigrator
      # Migrate providers to YAML config file
      # @param providers [Hash] Providers to migrate (name => config hash)
      # @param yaml_path [String] Path to YAML config file (default: .agent-eval.yml)
      # @return [void]
      def self.migrate(providers, yaml_path = '.agent-eval.yml')
        # Load existing config or start fresh
        existing = if File.exist?(yaml_path)
                     YAML.safe_load_file(yaml_path, permitted_classes: [Symbol]) || {}
                   else
                     {}
                   end

        # Ensure providers key exists
        existing['providers'] ||= {}

        # Merge providers (new providers overwrite existing ones with same name)
        providers.each do |name, config|
          existing['providers'][name.to_s] = config.transform_keys(&:to_s)
        end

        # Write back
        File.write(yaml_path, existing.to_yaml)
      end
    end
  end
end
