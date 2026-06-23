# frozen_string_literal: true

module SkillBench
  module Clients
    # Service object for building standardized response hashes.
    # Eliminates duplication of error response formatting across the codebase.
    class ResponseBuilder
      # Builds a standardized error response.
      #
      # @param message [String] The error message.
      # @param provider_name [String, nil] The provider name for context (not appended to message).
      # @param status [String] The status identifier (default: 'error').
      # @return [Hash] Standardized error response hash.
      def self.error(message:, provider_name: nil, status: 'error')
        {
          success: false,
          response: { error: { message: message } },
          result: message,
          status: status
        }
      end

      # Builds a standardized success response.
      #
      # @param content [String] The response content.
      # @param metadata [Hash] Additional metadata to include in response.
      # @return [Hash] Standardized success response hash.
      def self.success(content:, metadata: {})
        {
          success: true,
          result: content,
          response: { content: content }.merge(metadata),
          status: 'success'
        }
      end

      # Builds a standardized API error response.
      #
      # @param error_message [String] The API error message.
      # @param usage [Hash] Token usage information.
      # @return [Hash] Standardized API error response hash.
      def self.api_error(error_message:, usage: {})
        {
          success: false,
          result: "API Error: #{error_message}",
          usage: usage,
          response: { error: { message: "API Error: #{error_message}" } },
          status: 'error'
        }
      end

      # Builds a standardized network error response.
      #
      # @param error_message [String] The network error message.
      # @return [Hash] Standardized network error response hash.
      def self.network_error(error_message:)
        {
          success: false,
          response: { error: { message: "Network Error: #{error_message}" } },
          result: "Network Error: #{error_message}",
          status: 'error'
        }
      end

      # Builds a standardized parsing error response.
      #
      # @param error_message [String] The parsing error message.
      # @return [Hash] Standardized parsing error response hash.
      def self.parsing_error(error_message:)
        {
          success: false,
          response: { error: { message: "Parsing Error: #{error_message}" } },
          result: "Parsing Error: #{error_message}",
          status: 'error'
        }
      end

      # Builds a standardized unexpected error response.
      #
      # @param error_message [String] The unexpected error message.
      # @return [Hash] Standardized unexpected error response hash.
      def self.unexpected_error(error_message:)
        {
          success: false,
          response: { error: { message: "Unexpected Error: #{error_message}" } },
          result: "Unexpected Error: #{error_message}",
          status: 'error'
        }
      end
    end
  end
end