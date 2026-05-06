# frozen_string_literal: true

require 'yaml'
require_relative '../models/config'

module AgentEval
  module Commands
    # Handles the `agent-eval init` command
    class Init
      # Run the init command to generate config
      # @param options [Hash] Options for init (e.g., rails: true)
      # @return [void]
      def self.run(options = {})
        config = default_config
        config['rails'] = rails_config if options[:rails]

        File.write('.agent-eval.yml', config.to_yaml)
      end

      # Returns default configuration hash
      # @return [Hash] Default configuration with providers
      def self.default_config
        {
          'providers' => {
            'openai' => {
              'runtime' => 'opencode',
              'llm' => 'openai',
              'config' => { 'api_key' => '${AGENT_EVAL_OPENAI_API_KEY}' }
            }
          }
        }
      end

      # Returns Rails-specific configuration
      # @return [Hash] Rails configuration with skill/eval paths
      def self.rails_config
        {
          'skill_paths' => ['skills/'],
          'eval_paths' => ['evals/'],
          'rails_env' => 'test'
        }
      end
    end
  end
end
