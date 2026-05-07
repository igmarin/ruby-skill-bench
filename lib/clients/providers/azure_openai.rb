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

        def provider_name
          :azure
        end

        protected

        # Returns the base URL for Azure OpenAI.
        #
        # @return [String]
        def base_url
          @endpoint.to_s
        end

        # Returns the request path including the deployment name and API version.
        #
        # @return [String]
        def request_path
          api_ver = @api_version || DEFAULT_API_VERSION
          "/openai/deployments/#{@model}/chat/completions?api-version=#{api_ver}"
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

        private

        # @return [Array<String>]
        def missing_config_keys
          missing = []
          missing << 'AZURE_OPENAI_API_KEY'  if @api_key.to_s.strip.empty?
          missing << 'AZURE_OPENAI_ENDPOINT' if @endpoint.to_s.strip.empty?
          missing << 'AZURE_OPENAI_MODEL'    if @model.to_s.strip.empty?
          missing
        end
      end
    end
  end
end
