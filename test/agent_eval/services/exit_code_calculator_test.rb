# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ExitCodeCalculatorTest < Minitest::Test
      def test_call_returns_0_when_both_pass
        result_a = { response: { report: { verdict: 'PASS' } } }
        result_b = { response: { report: { verdict: 'PASS' } } }

        exit_code = ExitCodeCalculator.call(result_a, result_b)

        assert_equal 0, exit_code
      end

      def test_call_returns_1_when_a_fails
        result_a = { response: { report: { verdict: 'FAIL' } } }
        result_b = { response: { report: { verdict: 'PASS' } } }

        exit_code = ExitCodeCalculator.call(result_a, result_b)

        assert_equal 1, exit_code
      end

      def test_call_returns_1_when_b_fails
        result_a = { response: { report: { verdict: 'PASS' } } }
        result_b = { response: { report: { verdict: 'FAIL' } } }

        exit_code = ExitCodeCalculator.call(result_a, result_b)

        assert_equal 1, exit_code
      end

      def test_call_returns_1_when_both_fail
        result_a = { response: { report: { verdict: 'FAIL' } } }
        result_b = { response: { report: { verdict: 'FAIL' } } }

        exit_code = ExitCodeCalculator.call(result_a, result_b)

        assert_equal 1, exit_code
      end

      def test_call_returns_1_when_verdicts_missing
        result_a = { response: {} }
        result_b = { response: {} }

        exit_code = ExitCodeCalculator.call(result_a, result_b)

        assert_equal 1, exit_code
      end

      def test_call_returns_1_when_reports_missing
        result_a = {}
        result_b = {}

        exit_code = ExitCodeCalculator.call(result_a, result_b)

        assert_equal 1, exit_code
      end
    end
  end
end
