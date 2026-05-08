# frozen_string_literal: true

require 'yaml'
require 'json'

module SkillBench
  module Migration
    # Migrates old provider classes to new YAML-based configuration
    class ProviderMigrator
      # Migrate providers to YAML config file
      # @param providers [Hash] Providers to migrate (name => config hash)
      # @param yaml_path [String] Path to YAML config file (default: .agent-eval.yml)
      def self.migrate(providers, yaml_path = '.agent-eval.yml')
        existing = if File.exist?(yaml_path)
                     YAML.safe_load_file(yaml_path, permitted_classes: [], aliases: false) || {}
                   else
                     {}
                   end

        existing['providers'] ||= {}

        providers.each do |name, config|
          existing['providers'][name.to_s] = config.transform_keys(&:to_s)
        end

        File.write(yaml_path, existing.to_yaml)
      end
    end
  end
end
