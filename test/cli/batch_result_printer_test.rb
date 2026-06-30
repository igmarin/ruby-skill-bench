# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Cli
    class BatchResultPrinterTest < Minitest::Test
      def test_human_output_is_the_default
        exit_code = nil
        out, = capture_io { exit_code = BatchResultPrinter.call(aggregate(failed: 0)) }

        assert_equal 0, exit_code
        assert_includes out, 'PASS  evals/eval-a'
        assert_includes out, 'Summary: 1 passed / 0 failed (1 total)'
      end

      def test_junit_format_emits_a_testsuite_and_failure_exit_code
        exit_code = nil
        out, = capture_io { exit_code = BatchResultPrinter.call(aggregate(failed: 1), format: :junit) }

        assert_equal 1, exit_code
        assert_includes out, '<testsuite name="SkillBench" tests="2" failures="1">'
        assert_includes out, '<testcase name="evals/eval-b" classname="SkillBench">'
      end

      def test_summary_emits_json_gate_and_failure_exit_code
        exit_code = nil
        out, = capture_io { exit_code = BatchResultPrinter.call(aggregate(failed: 1), summary: true) }
        parsed = JSON.parse(out)

        assert_equal 1, exit_code
        assert_equal 1, parsed['passed']
        assert_equal 1, parsed['failed']
        assert_equal 2, parsed['total']
      end

      def test_summary_takes_precedence_over_format
        out, = capture_io { BatchResultPrinter.call(aggregate(failed: 0), format: :junit, summary: true) }

        assert_includes out, '"worst_delta"'
        refute_includes out, '<testsuite'
      end

      private

      def aggregate(failed:)
        results = [{ eval_name: 'evals/eval-a', success: true, response: { report: report(verdict: true) } }]
        results << { eval_name: 'evals/eval-b', success: false, response: { error: { message: 'boom' } } } if failed.positive?
        passed = results.size - failed
        { results: results, summary: { total: results.size, passed: passed, failed: failed } }
      end

      def report(verdict:)
        Struct.new(:verdict, :baseline_total, :context_total, :deltas, keyword_init: true).new(
          verdict: verdict, baseline_total: 30, context_total: 80, deltas: {}
        )
      end
    end
  end
end
