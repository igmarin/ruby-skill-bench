# frozen_string_literal: true

require 'faraday'
require_relative '../error_logger'
require_relative '../constants'

module SkillBench
  module Clients
    # Service object for retrying HTTP requests with exponential backoff.
    # Retries on transient errors (429, 503). Raises permanent errors immediately.
    # Returns the block result on success.
    class RetryHandler
      # Executes the given block with retry logic.
      #
      # @param max_attempts [Integer] Maximum number of attempts (default: 3).
      # @param base_delay [Numeric] Base delay in seconds before first retry (doubles each attempt).
      # @yield The request block to execute.
      # @return [Object] The block's return value on success.
      # @raise [Faraday::Error] On non-retryable errors or after exhausting retries.
      # @raise [ArgumentError] if no block is given or max_attempts < 1.
      def self.call(max_attempts: Constants::HttpClient::DEFAULT_MAX_RETRIES, base_delay: Constants::HttpClient::DEFAULT_RETRY_DELAY, &block)
        raise ArgumentError, 'RetryHandler requires a block' unless block
        raise ArgumentError, 'max_attempts must be >= 1' if max_attempts < 1

        new(max_attempts:, base_delay:, block:).call
      end

      # @param max_attempts [Integer] Maximum number of attempts.
      # @param base_delay [Numeric] Base delay before first retry.
      # @param block [Proc] The request block to execute.
      def initialize(max_attempts:, base_delay:, block:)
        @max_attempts = max_attempts
        @base_delay = base_delay
        @block = block
      end

      # Executes the block with retry logic.
      #
      # @return [Object] The block's return value on success.
      # @raise [Faraday::Error] On non-retryable errors or after exhausting retries.
      def call
        attempt = 0

        loop do
          attempt += 1
          return @block.call
        rescue Faraday::Error => e
          status = extract_status(e)
          raise e unless retryable?(status, attempt)

          delay = compute_delay(attempt)
          wait(delay)
        end
      end

      private

      def retryable?(status, attempt)
        Constants::HttpClient::RETRYABLE_STATUSES.include?(status) && attempt < @max_attempts
      end

      def compute_delay(attempt)
        [@base_delay * (2**(attempt - 1)), Constants::ReactAgent::DEFAULT_MAX_DELAY].min
      end

      def extract_status(error)
        error.respond_to?(:response_status) ? error.response_status : 0
      end

      def wait(delay)
        sleep(delay)
      end
    end
  end
end
