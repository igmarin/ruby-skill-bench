# frozen_string_literal: true

require 'json'

module SkillBench
  module Commands
    # Handles the `skill-bench init` command.
    # Generates a skill-bench.json config file with default provider settings.
    class Init
      # Run the init command to generate config.
      #
      # @param force [Boolean] Whether to overwrite an existing config file.
      # @return [void]
      # @raise [RuntimeError] if config file exists and force is false
      def self.run(force: false)
        raise "Config file '#{SkillBench::Config::CONFIG_FILENAME}' already exists. Use --force to overwrite." if File.exist?(SkillBench::Config::CONFIG_FILENAME) && !force

        config = default_config
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.pretty_generate(config))
      end

      # Returns default configuration hash.
      #
      # @return [Hash] Default configuration with all supported providers.
      def self.default_config
        {
          current_llm_provider: 'openai',
          max_execution_time: 30,
          providers: {
            openai: { api_key: nil, model: 'gpt-4o' },
            anthropic: { api_key: nil, model: 'claude-sonnet-4-20250514' },
            gemini: { api_key: nil, model: 'gemini-1.5-flash-latest', location: 'us-central1', project_id: nil },
            ollama: { api_key: nil, model: 'qwen:7b', base_url: nil },
            azure: { api_key: nil, model: 'gpt-4', endpoint: nil, api_version: nil },
            groq: { api_key: nil, model: 'llama-3.3-70b-versatile' },
            deepseek: { api_key: nil, model: 'deepseek-chat' },
            opencode: { api_key: nil, model: 'opencode-model' }
          }
        }
      end
    end
  end
end
