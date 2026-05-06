# frozen_string_literal: true

require_relative 'providers/null_client'

module Evaluator
  module Clients
    # ProviderRegistry manages registration and lookup of LLM provider classes.
    # Follows the Registry pattern for extensible provider discovery.
    class ProviderRegistry
      class << self
        # Registers a provider class with a given name.
        #
        # @param name [Symbol] the provider identifier (e.g., :openai, :gemini)
        # @param klass [Class] the provider class implementing the client interface
        # @return [void]
        def register(name, klass)
          providers[name] = klass
        end

        # Looks up a provider class by name.
        # Returns NullClient if the provider is not registered.
        #
        # @param name [Symbol] the provider identifier
        # @return [Class] the provider class or NullClient
        def for(name)
          providers.fetch(name, Providers::NullClient)
        end

        # Returns all registered providers.
        #
        # @return [Hash] mapping of provider names to classes
        def providers
          @providers ||= {}
        end
      end
    end
  end
end
