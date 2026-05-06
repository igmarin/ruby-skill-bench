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

        attr_reader :location, :project_id

        # Initializes the Google Gemini client.
        #
        # @param system_prompt [String] Instructions for the AI's behavior
        # @param messages [Array<Hash>] Conversation history
        # @param tools [Array<Hash>] Definitions of tools available to the AI
        # @param options [Hash] Provider-specific configuration
        # @option options [String] :api_key The Google API key for authentication
        # @option options [String] :model The Gemini model name (e.g., 'gemini-1.5-flash-latest')
        # @option options [String] :location The Google Cloud location (e.g., 'us-central1')
        # @option options [String] :project_id The Google Cloud Project ID
        # @raise [StandardError] if configuration is invalid (handled gracefully in call)
        def initialize(system_prompt:, messages:, tools: [], **options)
          super
          @api_key = options[:api_key] || Evaluator::Config.llm_providers_config.dig(:gemini, :api_key)
          @model = options[:model] || Evaluator::Config.llm_providers_config.dig(:gemini, :model)
          @location = options[:location] || Evaluator::Config.llm_providers_config.dig(:gemini, :location)
          @project_id = options[:project_id] || Evaluator::Config.llm_providers_config.dig(:gemini, :project_id)
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

        # Validates that API key, project ID, location, and model are present.
        #
        # @return [Boolean]
        def valid_config?
          !@api_key.to_s.strip.empty? &&
            !@project_id.to_s.strip.empty? &&
            !@location.to_s.strip.empty? &&
            !@model.to_s.strip.empty?
        end

        # Standardized error response when configuration is missing.
        #
        # @return [Hash]
        def config_error
          missing = missing_config_keys
          message = if missing.length > 1
                      "#{missing[0...-1].join(', ')}, and #{missing[-1]} not set for Gemini"
                    else
                      "#{missing.first} not set for Gemini"
                    end
          { success: false, response: { error: { message: message } } }
        end

        private

        # @return [Array<String>]
        def missing_config_keys
          missing = []
          missing << 'GEMINI_API_KEY' if @api_key.to_s.strip.empty?
          missing << 'GEMINI_PROJECT_ID' if @project_id.to_s.strip.empty?
          missing << 'GEMINI_LOCATION' if @location.to_s.strip.empty?
          missing << 'GEMINI_MODEL' if @model.to_s.strip.empty?
          missing
        end
      end
    end
  end
end
