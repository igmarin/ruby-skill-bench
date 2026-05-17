# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class FeedbackGeneratorTest < Minitest::Test
      def test_call_returns_success_response
        report = build_report_with_reasoning(
          baseline: { 'correctness' => { score: 10, max_score: 30, reasoning: 'Partial' } },
          context: { 'correctness' => { score: 28, max_score: 30, reasoning: 'Great work' } }
        )
        result = FeedbackGenerator.call(report)

        assert result[:success]
        assert result[:response].key?(:output)
      end

      def test_call_categorizes_high_scores_as_went_well
        report = build_report_with_reasoning(
          baseline: { 'correctness' => { score: 10, max_score: 30, reasoning: 'Partial' } },
          context: { 'correctness' => { score: 28, max_score: 30, reasoning: 'Great work' } }
        )
        output = FeedbackGenerator.call(report)[:response][:output]

        assert_includes output, 'WHAT WENT WELL'
        assert_includes output, 'Great work'
        refute_includes output, 'WHAT WENT WRONG'
      end

      def test_call_categorizes_low_scores_as_went_wrong
        report = build_report_with_reasoning(
          baseline: { 'correctness' => { score: 5, max_score: 30, reasoning: 'Broken' } },
          context: { 'correctness' => { score: 8, max_score: 30, reasoning: 'Still broken' } }
        )
        output = FeedbackGenerator.call(report)[:response][:output]

        assert_includes output, 'WHAT WENT WRONG'
        assert_includes output, 'Still broken'
        refute_includes output, 'WHAT WENT WELL'
      end

      def test_call_includes_advice_for_low_scoring_dimensions
        report = build_report_with_reasoning(
          baseline: { 'code_quality' => { score: 2, max_score: 20, reasoning: 'Messy' } },
          context: { 'code_quality' => { score: 4, max_score: 20, reasoning: 'Still messy' } }
        )
        output = FeedbackGenerator.call(report)[:response][:output]

        assert_includes output, 'ADVICE'
        assert_includes output, 'Clean code matters'
      end

      def test_call_returns_empty_output_when_no_dimensions
        report = DeltaReport.new(
          baseline: {},
          context: {},
          criteria: build_criteria([], true)
        )
        output = FeedbackGenerator.call(report)[:response][:output]

        assert_empty output
      end

      def test_call_returns_empty_output_when_dimensions_not_respond
        report = Object.new
        output = FeedbackGenerator.call(report)[:response][:output]

        assert_empty output
      end

      def test_call_includes_both_well_and_wrong_sections
        dimensions = [
          Dimension.new(name: 'correctness', description: '', max_score: 30),
          Dimension.new(name: 'code_quality', description: 'Keep it clean', max_score: 20)
        ]
        baseline = {
          'correctness' => { score: 10, max_score: 30, reasoning: 'Partial' },
          'code_quality' => { score: 2, max_score: 20, reasoning: 'Messy' }
        }
        context = {
          'correctness' => { score: 28, max_score: 30, reasoning: 'Great' },
          'code_quality' => { score: 4, max_score: 20, reasoning: 'Still messy' }
        }
        report = DeltaReport.new(
          baseline: baseline,
          context: context,
          criteria: build_criteria(dimensions, true)
        ).tap do |r|
          r.instance_variable_set(:@baseline_total, 12)
          r.instance_variable_set(:@context_total, 32)
          r.instance_variable_set(:@baseline_scores, { 'correctness' => 10, 'code_quality' => 2 })
          r.instance_variable_set(:@context_scores, { 'correctness' => 28, 'code_quality' => 4 })
          r.instance_variable_set(:@deltas, { 'correctness' => 18, 'code_quality' => 2 })
          r.instance_variable_set(:@verdict, true)
          r.instance_variable_set(:@baseline_dimensions, baseline.transform_values(&:dup))
          r.instance_variable_set(:@context_dimensions, context.transform_values(&:dup))
        end

        output = FeedbackGenerator.call(report)[:response][:output]

        assert_includes output, 'WHAT WENT WELL'
        assert_includes output, 'WHAT WENT WRONG'
        assert_includes output, 'ADVICE'
      end

      private

      def build_report_with_reasoning(baseline:, context:)
        dimensions = baseline.keys.map do |name|
          desc = name == 'code_quality' ? 'Clean code matters' : ''
          Dimension.new(name: name, description: desc, max_score: baseline[name][:max_score])
        end
        DeltaReport.new(
          baseline: baseline,
          context: context,
          criteria: build_criteria(dimensions, true)
        ).tap do |r|
          r.instance_variable_set(:@baseline_total, baseline.values.sum { |v| v[:score] })
          r.instance_variable_set(:@context_total, context.values.sum { |v| v[:score] })
          r.instance_variable_set(:@baseline_scores, baseline.transform_values { |v| v[:score] })
          r.instance_variable_set(:@context_scores, context.transform_values { |v| v[:score] })
          r.instance_variable_set(:@deltas, baseline.transform_values { |_v| 0 })
          r.instance_variable_set(:@verdict, true)
          r.instance_variable_set(:@baseline_dimensions, baseline.transform_values(&:dup))
          r.instance_variable_set(:@context_dimensions, context.transform_values(&:dup))
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
