# frozen_string_literal: true

module Evaluator
  module Clients
    # Handles error responses and logging for LLM provider clients.
    # Encapsulates error formatting, logging, and exception handling.
    class ResponseErrorHandler
      API_FAILED = 'API Request failed'

      # Creates an error response for failed HTTP requests.
      #
      # @param response [Faraday::Response] The HTTP response
      # @param parsed [Hash] Parsed response body
      # @param usage_extractor [Proc] Block to extract usage data
      # @return [Hash] Standardized error response
      def self.failure_response(response, parsed, &usage_extractor)
        error_msg = "#{API_FAILED}: #{response.status}"
        detail = parsed.is_a?(Hash) ? (parsed[:error] || parsed['error'] || parsed) : parsed

        if detail.is_a?(Hash) && (detail[:message] || detail['message'])
          error_msg += " - #{detail[:message] || detail['message']}"
        elsif !detail.to_s.empty?
          error_msg += " - #{detail}"
        end

        {
          success: false,
          result: error_msg,
          usage: usage_extractor.call(parsed),
          response: { error: { message: error_msg } },
          status: 'error',
          code: response.status
        }
      end

      # Creates an error response when the LLM response has no message content.
      #
      # @param response [Faraday::Response] The HTTP response
      # @param parsed [Hash] Parsed response body
      # @param usage_extractor [Proc] Block to extract usage data
      # @return [Hash] Standardized error response
      def self.missing_message_response(response, parsed, &usage_extractor)
        error_msg = 'LLM response missing message content'
        {
          success: false,
          result: error_msg,
          usage: usage_extractor.call(parsed),
          response: { error: { message: error_msg } },
          status: 'error',
          code: response.status
        }
      end

      # Handles an exception by logging and returning a standardized error response.
      #
      # @param error [StandardError] The exception that occurred
      # @param type [String] The error type label
      # @return [Hash] Standardized error response
      def self.handle_exception(error, type)
        log_error(error)
        { success: false, result: "#{type}: #{error.message}", status: 'error' }
      end

      # Logs an error message and backtrace to Rails.logger or stderr.
      #
      # @param error [StandardError] The exception to log
      # @return [void]
      def self.log_error(error)
        message = "Error: #{error.message}"
        backtrace = error.backtrace&.first(5)&.join("\n") || '(no backtrace)'

        logger = defined?(Rails) ? Rails.logger : nil
        if logger
          logger.error(message)
          logger.error(backtrace)
        else
          warn(message)
          warn(backtrace)
        end
      end
    end
  end
end
