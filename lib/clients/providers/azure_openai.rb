# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # Azure OpenAI provider using the OpenAI-compatible API.
      #
      # This provider bridges the gap between standard OpenAI requests and Azure's
      # deployment-based endpoint structure.
      #
      # @see https://learn.microsoft.com/en-us/azure/ai-services/openai/reference
      class AzureOpenAI < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:azure, self)

        # Default API version if none is provided.
        DEFAULT_API_VERSION = '2024-02-15-preview'

        # Initializes the Azure OpenAI client.
        #
        # @param system_prompt [String] Instructions for the AI's behavior
        # @param messages [Array<Hash>] Conversation history
        # @param tools [Array<Hash>] Definitions of tools available to the AI
        # @param options [Hash] Provider-specific configuration
        # @option options [String] :endpoint The Azure endpoint URL (e.g., https://resource.openai.azure.com)
        # @option options [String] :api_version The Azure API version string
        def initialize(system_prompt:, messages:, tools: [], **options)
          super
          config = Evaluator::Config.llm_providers_config[:azure] || {}
          @api_key = options[:api_key] || config[:api_key]
          @model = options[:model] || config[:model]
          @endpoint = options[:endpoint] || config[:endpoint]
          @api_version = options[:api_version] || config[:api_version] || DEFAULT_API_VERSION
        end

        protected

        # Returns the base URL for Azure OpenAI.
        #
        # @return [String]
        def base_url
          endpoint.to_s
        end

        # Returns the request path including the deployment name and API version.
        #
        # @return [String]
        def request_path
          "/openai/deployments/#{@model}/chat/completions?api-version=#{@api_version}"
        end

        # Returns the headers required for Azure OpenAI authentication.
        #
        # @return [Hash]
        def request_headers
          {
            'api-key' => @api_key,
            'Content-Type' => 'application/json'
          }
        end

        # Validates that API key, endpoint, and model are present.
        #
        # @return [Boolean]
        def valid_config?
          !@api_key.to_s.strip.empty? &&
            !endpoint.to_s.strip.empty? &&
            !@model.to_s.strip.empty?
        end

        # Standardized error response when configuration is missing.
        #
        # @return [Hash]
        def config_error
          missing = []
          missing << 'AZURE_OPENAI_API_KEY' if @api_key.to_s.strip.empty?
          missing << 'AZURE_OPENAI_ENDPOINT' if endpoint.to_s.strip.empty?
          missing << 'AZURE_OPENAI_MODEL' if @model.to_s.strip.empty?

          message = if missing.length > 1
                      "#{missing[0...-1].join(', ')}, and #{missing[-1]} not set for Azure OpenAI"
                    else
                      "#{missing.first} not set for Azure OpenAI"
                    end
          { success: false, response: { error: { message: message } } }
        end

        private

        attr_reader :endpoint
      end
    end
  end
end
