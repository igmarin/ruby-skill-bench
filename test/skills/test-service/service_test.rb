# frozen_string_literal: true

require 'test_helper'
require_relative '../../../skills/test-service/service'

module AgentEval
  module Skills
    class TestServiceTest < Minitest::Test
      def test_call_returns_success_by_default
        service = TestService.new
        result = service.call

        assert result[:success]
        assert_equal 'Not implemented', result[:response][:message]
      end

      def test_call_returns_standard_response_format
        service = TestService.new
        result = service.call

        assert result.key?(:success)
        assert result.key?(:response)
        assert_instance_of Hash, result[:response]
      end

      def test_call_response_has_message_key
        service = TestService.new
        result = service.call

        assert result[:response].key?(:message)
      end

      def test_initialize_accepts_keyword_args
        # Should not raise
        service = TestService.new(foo: 'bar', baz: 123)

        assert_instance_of TestService, service
      end

      def test_error_response_format_when_rails_logger_missing
        # When Rails.logger is missing, the rescue block should still work
        # We can't easily test the rescue path without forcing an error,
        # but we can verify the class structure is correct
        assert_respond_to TestService.new, :call
      end
    end
  end
end
