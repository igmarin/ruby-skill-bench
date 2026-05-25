# frozen_string_literal: true

module SkillBench
  class Config
    # Builds the default evaluator configuration state.
    class Defaults
      # Returns the default configuration values.
      #
      # @return [Hash] result envelope with default provider, timeout, command, and provider settings
      def self.call
        { success: true, response: { config: config } }
      end

      # Builds the raw default configuration hash.
      #
      # @return [Hash] default provider, timeout, command, and provider settings
      def self.config
        {
          current_llm_provider: :openai,
          max_execution_time: 30,
          allowed_commands: nil,
          skill_sources: {},
          llm_providers_config: {
            openai: { api_key: nil, model: 'gpt-4o' },
            anthropic: { api_key: nil, model: 'claude-sonnet-4-20250514' },
            gemini: {
              api_key: nil,
              model: 'gemini-1.5-flash-latest',
              location: 'us-central1',
              project_id: nil
            },
            ollama: { api_key: nil, model: 'qwen:7b', base_url: nil },
            azure: { api_key: nil, model: 'gpt-4', endpoint: nil, api_version: nil },
            groq: { api_key: nil, model: 'llama-3.3-70b-versatile' },
            deepseek: { api_key: nil, model: 'deepseek-chat' },
            opencode: { api_key: nil, model: 'opencode-model', base_url: nil },
            openrouter: { api_key: nil, model: 'anthropic/claude-3.5-sonnet' }
          }
        }
      end
    end
  end
end
