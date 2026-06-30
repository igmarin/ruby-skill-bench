# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Services
    class SummaryFormatterTest < Minitest::Test
      def test_reports_counts_from_summary
        parsed = JSON.parse(SummaryFormatter.format(sample_aggregate))

        assert_equal 2, parsed['passed']
        assert_equal 1, parsed['failed']
        assert_equal 3, parsed['total']
      end

      def test_sums_total_tokens_across_results
        parsed = JSON.parse(SummaryFormatter.format(sample_aggregate))

        assert_equal 450, parsed['tokens']
      end

      def test_sums_non_nil_costs
        parsed = JSON.parse(SummaryFormatter.format(sample_aggregate))

        assert_in_delta(0.06, parsed['cost'])
      end

      def test_worst_delta_picks_smallest_skill_vs_baseline_delta
        parsed = JSON.parse(SummaryFormatter.format(sample_aggregate))

        assert_equal 'evals/eval-c', parsed['worst_delta']['eval_name']
        assert_equal 5, parsed['worst_delta']['delta']
      end

      def test_cost_is_null_when_no_result_reports_a_cost
        results = [result('evals/only', cost: nil, tokens: 10, report: report(40, 80))]
        parsed = JSON.parse(SummaryFormatter.format(envelope(results, passed: 1, failed: 0)))

        assert_nil parsed['cost']
      end

      def test_tolerates_results_without_a_delta_report
        results = [result('evals/no-report', cost: 0.01, tokens: 100, report: nil)]
        parsed = JSON.parse(SummaryFormatter.format(envelope(results, passed: 1, failed: 0)))

        assert_nil parsed['worst_delta']
        assert_equal 100, parsed['tokens']
      end

      def test_treats_missing_tokens_as_zero
        results = [{ eval_name: 'evals/bare', cost: 0.01, response: { report: report(40, 80) } }]
        parsed = JSON.parse(SummaryFormatter.format(envelope(results, passed: 1, failed: 0)))

        assert_equal 0, parsed['tokens']
      end

      def test_output_is_pretty_printed
        output = SummaryFormatter.format(sample_aggregate)

        assert_includes output, "{\n"
        assert_includes output, '  "passed":'
      end

      private

      def sample_aggregate
        results = [
          result('evals/eval-a', cost: 0.02, tokens: 100, report: report(30, 80)), # delta 50
          result('evals/eval-b', cost: 0.04, tokens: 200, report: report(20, 60)), # delta 40
          result('evals/eval-c', cost: nil, tokens: 150, report: report(35, 40))   # delta 5 (worst)
        ]
        envelope(results, passed: 2, failed: 1)
      end

      def envelope(results, passed:, failed:)
        { results: results, summary: { total: results.size, passed: passed, failed: failed } }
      end

      def result(name, tokens:, cost:, report:)
        {
          eval_name: name,
          tokens: { total_tokens: tokens },
          cost: cost,
          response: { report: report }
        }
      end

      def report(baseline_total, context_total)
        Struct.new(:baseline_total, :context_total, keyword_init: true).new(
          baseline_total: baseline_total, context_total: context_total
        )
      end
    end
  end
end
