# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class RetryHandlerTest < Minitest::Test
      def setup
        RetryHandler.any_instance.stubs(:wait)
      end

      def test_retries_on_429_then_raises
        attempts = 0

        assert_raises(Faraday::ClientError) do
          RetryHandler.call(max_attempts: 3, base_delay: 0.01) do
            attempts += 1
            raise Faraday::ClientError.new('rate limited', status: 429)
          end
        end

        assert_equal 3, attempts
      end

      def test_retries_on_503_then_raises
        attempts = 0

        assert_raises(Faraday::ServerError) do
          RetryHandler.call(max_attempts: 3, base_delay: 0.01) do
            attempts += 1
            raise Faraday::ServerError.new('unavailable', status: 503)
          end
        end

        assert_equal 3, attempts
      end

      def test_does_not_retry_on_401_error
        attempts = 0

        assert_raises(Faraday::ClientError) do
          RetryHandler.call(max_attempts: 3, base_delay: 0.01) do
            attempts += 1
            raise Faraday::ClientError.new('unauthorized', status: 401)
          end
        end

        assert_equal 1, attempts
      end

      def test_does_not_retry_on_403_error
        attempts = 0

        assert_raises(Faraday::ClientError) do
          RetryHandler.call(max_attempts: 3, base_delay: 0.01) do
            attempts += 1
            raise Faraday::ClientError.new('forbidden', status: 403)
          end
        end

        assert_equal 1, attempts
      end

      def test_retries_with_exponential_backoff
        delays = []

        RetryHandler.any_instance.unstub(:wait)
        RetryHandler.any_instance.stubs(:wait).with do |d|
          delays << d
          true
        end

        assert_raises(Faraday::ClientError) do
          RetryHandler.call(max_attempts: 3, base_delay: 1) do
            raise Faraday::ClientError.new('rate limited', status: 429)
          end
        end

        assert_equal [1, 2], delays
      end

      def test_returns_result_on_retry_recovery
        attempts = 0

        result = RetryHandler.call(max_attempts: 3, base_delay: 0.01) do
          attempts += 1
          raise Faraday::ClientError.new('rate limited', status: 429) if attempts < 3

          'success result'
        end

        assert_equal 'success result', result
        assert_equal 3, attempts
      end

      def test_max_attempts_defaults_to_three
        attempts = 0

        assert_raises(Faraday::ClientError) do
          RetryHandler.call(base_delay: 0.01) do
            attempts += 1
            raise Faraday::ClientError.new('rate limited', status: 429)
          end
        end

        assert_equal 3, attempts
      end

      def test_raises_argument_error_without_block
        assert_raises(ArgumentError) do
          RetryHandler.call
        end
      end

      def test_unknown_error_raises_immediately
        attempts = 0

        assert_raises(StandardError) do
          RetryHandler.call(max_attempts: 3, base_delay: 0.01) do
            attempts += 1
            raise StandardError, 'unknown error'
          end
        end

        assert_equal 1, attempts
      end
    end
  end
end
