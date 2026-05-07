# frozen_string_literal: true

require 'yaml'

module SkillBench
  module Commands
    # Handles the `agent-eval init` command
    class Init
      # Run the init command to generate config
      # @param options [Hash] Options for init (e.g., rails: true, force: true)
      # @return [void]
      def self.run(options = {})
        raise 'Config file already exists. Use --force to overwrite or backup the file first.' if File.exist?('.agent-eval.yml') && !options[:force]

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
