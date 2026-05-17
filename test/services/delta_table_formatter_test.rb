# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class DeltaTableFormatterTest < Minitest::Test
      def test_format_includes_dimension_rows
        report = build_delta_report(verdict: true)
        output = DeltaTableFormatter.format(report)

        assert_includes output, 'DIMENSION'
        assert_includes output, 'BASELINE'
        assert_includes output, 'CONTEXT'
        assert_includes output, 'DELTA'
        assert_includes output, 'Correctness (30)'
        assert_includes output, 'Skill Adherence (25)'
      end

      def test_format_includes_total_row
        report = build_delta_report(verdict: true)
        output = DeltaTableFormatter.format(report)

        assert_includes output, 'TOTAL'
        assert_includes output, '17/100'
        assert_includes output, '50/100'
        assert_includes output, '+33'
      end

      def test_format_includes_verdict_pass
        report = build_delta_report(verdict: true)
        output = DeltaTableFormatter.format(report)

        assert_includes output, 'VERDICT: PASS'
        assert_includes output, 'threshold: 70'
        assert_includes output, 'minimum delta: 10'
      end

      def test_format_includes_verdict_fail
        report = build_delta_report(verdict: false)
        output = DeltaTableFormatter.format(report)

        assert_includes output, 'VERDICT: FAIL'
      end

      def test_format_includes_trend_when_present
        report = build_delta_report(verdict: true)
        result = { trend: { baseline_trend: :improved, context_trend: :regressed, baseline_delta: 5, context_delta: -3 } }
        output = DeltaTableFormatter.format(report, result)

        assert_includes output, 'TREND: baseline ↑ (+5), context ↓ (-3)'
      end

      def test_format_omits_trend_when_absent
        report = build_delta_report(verdict: true)
        output = DeltaTableFormatter.format(report)

        refute_includes output, 'TREND'
      end

      def test_format_includes_bottom_border
        report = build_delta_report(verdict: true)
        output = DeltaTableFormatter.format(report)

        assert_includes output, '═' * 55
      end

      def test_format_shows_negative_delta
        dimensions = [
          Dimension.new(name: 'correctness', description: '', max_score: 30)
        ]
        baseline = { 'correctness' => { score: 25, max_score: 30 } }
        context = { 'correctness' => { score: 20, max_score: 30 } }
        report = DeltaReport.new(
          baseline: baseline,
          context: context,
          criteria: build_criteria(dimensions, false)
        )
        report.instance_variable_set(:@baseline_total, 25)
        report.instance_variable_set(:@context_total, 20)
        report.instance_variable_set(:@baseline_scores, { 'correctness' => 25 })
        report.instance_variable_set(:@context_scores, { 'correctness' => 20 })
        report.instance_variable_set(:@deltas, { 'correctness' => -5 })
        report.instance_variable_set(:@verdict, false)

        output = DeltaTableFormatter.format(report)

        assert_includes output, '-5'
      end

      private

      def build_delta_report(verdict:)
        dimensions = [
          Dimension.new(name: 'correctness', description: '', max_score: 30),
          Dimension.new(name: 'skill_adherence', description: '', max_score: 25)
        ]
        baseline = {
          'correctness' => { score: 12, max_score: 30 },
          'skill_adherence' => { score: 5, max_score: 25 }
        }
        context = {
          'correctness' => { score: 28, max_score: 30 },
          'skill_adherence' => { score: 22, max_score: 25 }
        }
        DeltaReport.new(
          baseline: baseline,
          context: context,
          criteria: build_criteria(dimensions, verdict)
        ).tap do |r|
          r.instance_variable_set(:@baseline_total, 17)
          r.instance_variable_set(:@context_total, 50)
          r.instance_variable_set(:@baseline_scores, { 'correctness' => 12, 'skill_adherence' => 5 })
          r.instance_variable_set(:@context_scores, { 'correctness' => 28, 'skill_adherence' => 22 })
          r.instance_variable_set(:@deltas, { 'correctness' => 16, 'skill_adherence' => 17 })
          r.instance_variable_set(:@verdict, verdict)
        end
      end

      def build_criteria(dimensions, _verdict)
        Criteria.new(path: '/dev/null').tap do |c|
          c.instance_variable_set(:@context, '')
          c.instance_variable_set(:@pass_threshold, 70)
          c.instance_variable_set(:@minimum_delta, 10)
          c.instance_variable_set(:@dimensions, dimensions)
        end
      end
    end
  end
end
