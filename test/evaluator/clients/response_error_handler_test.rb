# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class ResponseErrorHandlerTest < Minitest::Test
      def test_failure_response_with_error_message
        response = Struct.new(:status).new(400)
        parsed = { error: { message: 'Bad request' } }
        result = ResponseErrorHandler.failure_response(response, parsed) { {} }

        refute result[:success]
        assert_includes result[:result], 'API Request failed: 400'
        assert_includes result[:result], 'Bad request'
        assert_equal 400, result[:code]
      end

      def test_failure_response_with_detail_string
        response = Struct.new(:status).new(500)
        parsed = 'Server error'
        result = ResponseErrorHandler.failure_response(response, parsed) { {} }

        assert_includes result[:result], 'Server error'
      end

      def test_missing_message_response
        response = Struct.new(:status).new(200)
        parsed = {}
        result = ResponseErrorHandler.missing_message_response(response, parsed) { {} }

        refute result[:success]
        assert_includes result[:result], 'LLM response missing message content'
        assert_equal 200, result[:code]
      end

      def test_handle_exception
        error = StandardError.new('test error')
        result = ResponseErrorHandler.handle_exception(error, 'Network Error')

        refute result[:success]
        assert_includes result[:result], 'Network Error: test error'
      end

      def test_log_error_warns_when_no_rails
        error = StandardError.new('test error')
        old_stderr = $stderr
        $stderr = StringIO.new
        ResponseErrorHandler.log_error(error)
        output = $stderr.string
        $stderr = old_stderr

        assert_includes output, 'test error'
      end
    end
  end
end
