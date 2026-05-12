# frozen_string_literal: true

require_relative 'clients/all'

module SkillBench
  # Facade for calling LLM clients.
  # Delegates to the configured provider.
  class Client
    # Calls the configured LLM provider with the given parameters.
    #
    # @param system_prompt [String] System prompt for the LLM
    # @param messages [Array<Hash>] Conversation messages
    # @param provider [Symbol, nil] Override the configured LLM provider (e.g., :deepseek, :openai)
    # @param options [Hash] Provider-specific options (api_key, model, etc.)
    # @return [Hash] Response from the LLM
    def self.call(system_prompt:, messages:, provider: nil, **options)
      resolved = provider || Config.current_llm_provider || :openai
      client_class = Clients::ProviderRegistry.for(resolved)
      client_class.call(system_prompt: system_prompt, messages: messages, **options)
    end
  end
end
