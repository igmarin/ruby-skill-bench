# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # Google Gemini provider using the OpenAI-compatible Vertex AI endpoint.
      #
      # This client handles the authentication and routing for Google's Vertex AI
      # OpenAI-compatible API, allowing it to be used alongside other providers.
      #
      # @see https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/openai-compatible-api
      class Gemini < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:gemini, self)

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :gemini
        end

        protected

        # Returns the base URL for Gemini's Vertex AI endpoint.
        #
        # @return [String]
        def base_url
          "https://#{@location}-aiplatform.googleapis.com"
        end

        # Returns the request path for the Vertex AI OpenAI-compatible endpoint.
        #
        # @return [String]
        def request_path
          "/v1/projects/#{@project_id}/locations/#{@location}/endpoints/openapi/chat/completions"
        end

        # Model name formatted for Vertex AI.
        #
        # @return [String]
        def model_name
          "google/#{@model}"
        end

        private

        # @return [Array<String>]
        def missing_config_keys
          missing = []
          missing << 'GEMINI_API_KEY'     if @api_key.to_s.strip.empty?
          missing << 'GEMINI_PROJECT_ID'  if @project_id.to_s.strip.empty?
          missing << 'GEMINI_LOCATION'    if @location.to_s.strip.empty?
          missing << 'GEMINI_MODEL'       if @model.to_s.strip.empty?
          missing
        end
      end
    end
  end
end
