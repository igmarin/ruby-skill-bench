# frozen_string_literal: true

require_relative 'clients/all'
require_relative 'services/response_cache'

module SkillBench
  # Facade for calling LLM clients.
  # Delegates to the configured provider.
  class Client
    # Provider clients that must never be cached: their results either signal a
    # configuration error (NullClient) or are cheap, deterministic test doubles
    # (Mock). Caching them would provide no benefit and could mask errors.
    UNCACHEABLE_CLIENTS = [
      Clients::Providers::NullClient,
      Clients::Providers::Mock
    ].freeze

    # Calls the configured LLM provider with the given parameters.
    #
    # When response caching is enabled (see {Services::ResponseCache.enabled?})
    # and the resolved provider is cacheable, identical requests reuse a cached
    # response instead of calling the provider again. When caching is disabled
    # (the default), the provider is always invoked, leaving behavior unchanged.
    #
    # @param system_prompt [String] System prompt for the LLM
    # @param messages [Array<Hash>] Conversation messages
    # @param provider [Symbol, nil] Override the configured LLM provider (e.g., :deepseek, :openai)
    # @param options [Hash] Provider-specific options (api_key, model, etc.)
    # @return [Hash] Response from the LLM
    def self.call(system_prompt:, messages:, provider: nil, **options)
      resolved = provider || Config.current_llm_provider || :openai
      client_class = Clients::ProviderRegistry.for(resolved)
      warn "WARNING: LLM provider '#{resolved}' is not configured. Falling back to null client." if client_class == Clients::Providers::NullClient

      invoke = -> { client_class.call(system_prompt: system_prompt, messages: messages, **options) }
      return invoke.call unless cache_eligible?(client_class)

      cache_key = Services::ResponseCache.key(
        provider: resolved,
        model: options[:model],
        system_prompt: system_prompt,
        messages: messages,
        tools: options[:tools],
        temperature: options[:temperature],
        provider_config: options.slice(:base_url, :request_path, :endpoint, :location, :project_id, :api_version)
      )
      Services::ResponseCache.fetch(cache_key, &invoke)
    end

    # Whether a resolved provider client may be served from the cache.
    #
    # Requires caching to be enabled and the client to not be one of the
    # {UNCACHEABLE_CLIENTS} (null/mock), so disabling the cache restores the
    # original, uncached behavior exactly.
    #
    # @param client_class [Class] The resolved provider client class
    # @return [Boolean] true when the call should go through the cache
    def self.cache_eligible?(client_class)
      return false unless Services::ResponseCache.enabled?

      !UNCACHEABLE_CLIENTS.include?(client_class)
    end
    private_class_method :cache_eligible?
  end
end
