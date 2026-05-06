# frozen_string_literal: true

require "yaml"
require_relative "../models/config"

module AgentEval
  module Commands
    # Handles the `agent-eval init` command
    class Init
      # Run the init command to generate config
      # @param rails [Boolean] Whether to add Rails-specific config
      # @return [void]
      def self.run(rails: false)
        config = default_config
        config["rails"] = rails_config if rails

        File.write(".agent-eval.yml", config.to_yaml)
      end

      # @return [Hash] Default configuration
      def self.default_config
        {
          "providers" => {
            "openai" => {
              "runtime" => "opencode",
              "llm" => "openai",
              "config" => { "api_key" => "${AGENT_EVAL_OPENAI_API_KEY}" }
            }
          }
        }
      end

      # @return [Hash] Rails-specific configuration
      def self.rails_config
        {
          "skill_paths" => ["skills/"],
          "eval_paths" => ["evals/"],
          "rails_env" => "test"
        }
      end
    end
  end
end
