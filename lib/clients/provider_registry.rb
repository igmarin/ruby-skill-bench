# frozen_string_literal: true

require_relative 'providers/null_client'
require_relative '../evaluator/error_logger'

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
        # Returns NullClient if the provider is not registered (with a warning).
        #
        # @param name [Symbol] the provider identifier
        # @return [Class] the provider class or NullClient
        def for(name)
          providers.fetch(name) do
            Evaluator::ErrorLogger.log_error(
              StandardError.new("Unknown provider '#{name}', falling back to NullClient"),
              'ProviderRegistry Warning'
            )
            Providers::NullClient
          end
        end

        # Looks up a provider class by name, raising if not found.
        #
        # @param name [Symbol] the provider identifier
        # @return [Class] the provider class
        # @raise [ArgumentError] if the provider is not registered
        def for!(name)
          providers.fetch(name) do
            raise ArgumentError, "Unknown provider '#{name}'. Registered: #{providers.keys.join(', ')}"
          end
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
