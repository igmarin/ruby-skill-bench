# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class JUnitFormatterTest < Minitest::Test
      def test_format_with_legacy_pass
        result = { eval_name: 'test-eval', pass: true, score: 1.0 }
        output = JUnitFormatter.format(result)

        assert_includes output, '<?xml version="1.0"?>'
        assert_includes output, '<testsuite name="SkillBench" tests="1" failures="0">'
        assert_includes output, '<testcase name="test-eval"'
        refute_includes output, '<failure'
      end

      def test_format_with_legacy_fail
        result = { eval_name: 'test-eval', pass: false, score: 0.3 }
        output = JUnitFormatter.format(result)

        assert_includes output, 'failures="1"'
        assert_includes output, '<failure message="Score: 0.3">'
      end

      def test_format_with_delta_report_pass
        report = build_delta_report(verdict: true)
        result = {
          success: true,
          response: { report: report },
          eval_name: 'delta-eval'
        }
        output = JUnitFormatter.format(result)

        assert_includes output, 'failures="0"'
        assert_includes output, '<testcase name="delta-eval"'
        refute_includes output, '<failure'
      end

      def test_format_with_delta_report_fail
        report = build_delta_report(verdict: false)
        result = {
          success: true,
          response: { report: report },
          eval_name: 'delta-eval'
        }
        output = JUnitFormatter.format(result)

        assert_includes output, 'failures="1"'
        assert_includes output, '<failure'
      end

      def test_format_escapes_html_in_eval_name
        result = { eval_name: 'test<eval>&name', pass: true }
        output = JUnitFormatter.format(result)

        refute_includes output, 'test<eval>&name'
        assert_includes output, 'test&lt;eval&gt;&amp;name'
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
