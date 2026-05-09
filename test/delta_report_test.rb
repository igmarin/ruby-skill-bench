# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class DeltaReportTest < Minitest::Test
    def test_computes_deltas_and_passes_verdict
      baseline = build_response(20, 15, 10, 8, 5)
      context = build_response(28, 22, 16, 13, 8)
      criteria = build_criteria(70, 10)

      result = DeltaReport.call(baseline: baseline, context: context, criteria: criteria)

      assert result[:success]
      report = result[:response][:delta_report]

      assert_equal 8, report.deltas['correctness']
      assert_equal 7, report.deltas['skill_adherence']
      assert_equal 6, report.deltas['code_quality']
      assert_equal 5, report.deltas['test_coverage']
      assert_equal 3, report.deltas['documentation']
      assert report.verdict
    end

    def test_fails_when_context_below_threshold
      baseline = build_response(20, 15, 10, 8, 5)
      context = build_response(10, 10, 10, 10, 10)
      criteria = build_criteria(70, 10)

      result = DeltaReport.call(baseline: baseline, context: context, criteria: criteria)

      assert result[:success]
      report = result[:response][:delta_report]

      refute report.verdict
      assert_equal 50, report.context_total
    end

    def test_fails_when_delta_below_minimum
      baseline = build_response(25, 20, 15, 12, 10)
      context = build_response(28, 22, 16, 13, 8)
      criteria = build_criteria(70, 20)

      result = DeltaReport.call(baseline: baseline, context: context, criteria: criteria)

      assert result[:success]
      report = result[:response][:delta_report]

      refute report.verdict
    end

    def test_returns_error_when_dimensions_mismatch
      baseline = build_response(20, 15, 10, 8, 5)
      context = { 'correctness' => { score: 28, max_score: 30, reasoning: '' } }
      criteria = build_criteria(70, 10)

      result = DeltaReport.call(baseline: baseline, context: context, criteria: criteria)

      refute result[:success]
      assert_match(/mismatch/, result[:response][:error][:message])
    end

    private

    def build_response(correctness, skill, quality, coverage, docs)
      {
        'correctness' => { score: correctness, max_score: 30, reasoning: '' },
        'skill_adherence' => { score: skill, max_score: 25, reasoning: '' },
        'code_quality' => { score: quality, max_score: 20, reasoning: '' },
        'test_coverage' => { score: coverage, max_score: 15, reasoning: '' },
        'documentation' => { score: docs, max_score: 10, reasoning: '' }
      }
    end

    def build_criteria(threshold, delta)
      dimensions = [
        Dimension.new(name: 'correctness', description: '', max_score: 30),
        Dimension.new(name: 'skill_adherence', description: '', max_score: 25),
        Dimension.new(name: 'code_quality', description: '', max_score: 20),
        Dimension.new(name: 'test_coverage', description: '', max_score: 15),
        Dimension.new(name: 'documentation', description: '', max_score: 10)
      ]
      Criteria.new(path: '/dev/null').tap do |c|
        c.instance_variable_set(:@context, '')
        c.instance_variable_set(:@pass_threshold, threshold)
        c.instance_variable_set(:@minimum_delta, delta)
        c.instance_variable_set(:@dimensions, dimensions)
      end
    end
  end
end
