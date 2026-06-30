# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class OutputFormatterTest < Minitest::Test
    def test_format_human_with_pass
      result = { eval_name: 'test-eval', skill_name: 'test-skill', provider_name: 'mock', pass: true, score: 1.0 }
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'Eval: test-eval'
      assert_includes output, 'Skill: test-skill'
      assert_includes output, 'Provider: mock'
      assert_includes output, 'Status: PASSED'
      assert_includes output, 'Score: 1.0'
    end

    def test_format_human_with_fail
      result = { eval_name: 'test-eval', skill_name: 'test-skill', provider_name: 'mock', pass: false, score: 0.3 }
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'Status: FAILED'
      assert_includes output, 'Score: 0.3'
    end

    def test_format_json
      result = { eval_name: 'test-eval', pass: true, score: 1.0 }
      output = OutputFormatter.format(result, format: :json)
      parsed = JSON.parse(output)

      assert_equal 'test-eval', parsed['eval_name']
      assert parsed['pass']
      assert_in_delta(1.0, parsed['score'])
    end

    def test_format_junit_with_pass
      result = { eval_name: 'test-eval', pass: true, score: 1.0 }
      output = OutputFormatter.format(result, format: :junit)

      assert_includes output, '<?xml version="1.0"?>'
      assert_includes output, '<testsuite name="SkillBench" tests="1" failures="0">'
      assert_includes output, '<testcase name="test-eval"'
      refute_includes output, '<failure'
    end

    def test_format_junit_with_fail
      result = { eval_name: 'test-eval', pass: false, score: 0.3 }
      output = OutputFormatter.format(result, format: :junit)

      assert_includes output, 'failures="1"'
      assert_includes output, '<failure message="Score: 0.3">'
    end

    def test_format_junit_with_delta_report_pass
      report = build_delta_report(verdict: true)
      result = {
        success: true,
        response: { report: report },
        eval_name: 'delta-eval'
      }
      output = OutputFormatter.format(result, format: :junit)

      assert_includes output, '<?xml version="1.0"?>'
      assert_includes output, '<testsuite name="SkillBench" tests="1" failures="0">'
      assert_includes output, '<testcase name="delta-eval"'
      refute_includes output, '<failure'
    end

    def test_format_junit_with_delta_report_fail
      report = build_delta_report(verdict: false)
      result = {
        success: true,
        response: { report: report },
        eval_name: 'delta-eval'
      }
      output = OutputFormatter.format(result, format: :junit)

      assert_includes output, 'failures="1"'
      assert_includes output, '<failure'
      assert_includes output, 'delta-eval'
    end

    def test_exit_code_returns_0_for_pass
      result = { pass: true }

      assert_equal 0, OutputFormatter.exit_code(result)
    end

    def test_exit_code_returns_1_for_fail
      result = { pass: false }

      assert_equal 1, OutputFormatter.exit_code(result)
    end

    def test_format_defaults_to_human
      result = { eval_name: 'test-eval', pass: true, score: 1.0, skill_name: 's', provider_name: 'p' }
      output = OutputFormatter.format(result)

      assert_includes output, 'Eval: test-eval'
    end

    def test_format_human_with_delta_report
      report = build_delta_report(verdict: true)
      result = {
        success: true,
        response: {
          report: report
        }
      }
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'DIMENSION'
      assert_includes output, 'BASELINE'
      assert_includes output, 'CONTEXT'
      assert_includes output, 'DELTA'
      assert_includes output, 'Correctness (30)'
      assert_includes output, 'VERDICT: PASS'
    end

    def test_format_human_with_delta_report_fail
      report = build_delta_report(verdict: false)
      result = { success: true, response: { report: report } }
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'VERDICT: FAIL'
    end

    def test_exit_code_returns_0_for_delta_report_pass
      result = { success: true, response: { report: build_delta_report(verdict: true) } }

      assert_equal 0, OutputFormatter.exit_code(result)
    end

    def test_exit_code_returns_1_for_delta_report_fail
      result = { success: true, response: { report: build_delta_report(verdict: false) } }

      assert_equal 1, OutputFormatter.exit_code(result)
    end

    def test_format_human_with_error_result_shows_error_message
      result = {
        success: false,
        response: {
          error: { message: 'baseline agent failed: connection refused' }
        },
        eval_name: 'test-eval',
        skill_name: 'test-skill',
        provider_name: 'openai'
      }
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'Eval: test-eval'
      assert_includes output, 'Skill: test-skill'
      assert_includes output, 'Provider: openai'
      assert_includes output, 'Status: FAILED'
      assert_includes output, 'Error: baseline agent failed: connection refused'
    end

    def test_format_human_with_error_result_missing_metadata
      result = {
        success: false,
        response: {
          error: { message: 'context agent failed: timeout' }
        }
      }
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'Status: FAILED'
      assert_includes output, 'Error: context agent failed: timeout'
    end

    def test_exit_code_returns_1_for_error_result
      result = { success: false, response: { error: { message: 'failed' } } }

      assert_equal 1, OutputFormatter.exit_code(result)
    end

    def test_format_batch_lists_per_eval_verdicts_and_summary
      aggregate = build_aggregate(passed: 1, failed: 1)
      output = OutputFormatter.format_batch(aggregate)

      assert_includes output, 'PASS'
      assert_includes output, 'FAIL'
      assert_includes output, '1 passed'
      assert_includes output, '1 failed'
      assert_includes output, '2 total'
    end

    def test_format_batch_includes_error_message_for_failed_eval
      results = [{ success: false, eval_name: 'broken-eval', response: { error: { message: 'connection refused' } } }]
      aggregate = { results: results, summary: { total: 1, passed: 0, failed: 1 } }
      output = OutputFormatter.format_batch(aggregate)

      assert_includes output, 'broken-eval'
      assert_includes output, 'connection refused'
    end

    def test_batch_exit_code_returns_0_when_all_pass
      aggregate = build_aggregate(passed: 2, failed: 0)

      assert_equal 0, OutputFormatter.batch_exit_code(aggregate)
    end

    def test_batch_exit_code_returns_1_when_any_fail
      aggregate = build_aggregate(passed: 1, failed: 1)

      assert_equal 1, OutputFormatter.batch_exit_code(aggregate)
    end

    def test_format_human_includes_iteration_timeline
      result = build_result_with_iterations(
        baseline_iterations: [
          { step_number: 1, thought: 'Read file', tools_used: %w[read_file], observation_summary: 'content' }
        ],
        context_iterations: [
          { step_number: 1, thought: 'Final', tools_used: [], observation_summary: '' }
        ]
      )
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'BASELINE ITERATIONS'
      assert_includes output, 'Step 1: Read file'
      assert_includes output, 'read_file'
      assert_includes output, 'CONTEXT ITERATIONS'
      assert_includes output, 'Step 1: Final'
    end

    def test_format_human_includes_what_went_well
      result = build_result_with_reasoning(
        baseline: { 'correctness' => { score: 10, max_score: 30, reasoning: 'Partial' } },
        context: { 'correctness' => { score: 28, max_score: 30, reasoning: 'Great work' } }
      )
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'WHAT WENT WELL'
      assert_includes output, 'Great work'
    end

    def test_format_human_includes_what_went_wrong
      result = build_result_with_reasoning(
        baseline: { 'correctness' => { score: 5, max_score: 30, reasoning: 'Broken' } },
        context: { 'correctness' => { score: 8, max_score: 30, reasoning: 'Still broken' } }
      )
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'WHAT WENT WRONG'
      assert_includes output, 'Still broken'
    end

    def test_format_human_includes_advice_for_low_scoring_dimensions
      result = build_result_with_reasoning(
        baseline: { 'code_quality' => { score: 2, max_score: 20, reasoning: 'Messy' } },
        context: { 'code_quality' => { score: 4, max_score: 20, reasoning: 'Still messy' } }
      )
      output = OutputFormatter.format(result, format: :human)

      assert_includes output, 'ADVICE'
      assert_includes output, 'Clean code'
    end

    private

    def build_aggregate(passed:, failed:)
      results = []
      passed.times { |i| results << { success: true, eval_name: "pass-#{i}", response: { report: build_delta_report(verdict: true) } } }
      failed.times { |i| results << { success: true, eval_name: "fail-#{i}", response: { report: build_delta_report(verdict: false) } } }
      { results: results, summary: { total: passed + failed, passed: passed, failed: failed } }
    end

    def build_result_with_iterations(baseline_iterations:, context_iterations:)
      report = build_delta_report(verdict: true)
      {
        success: true,
        eval_name: 'iteration-eval',
        skill_name: 'test-skill',
        provider_name: 'mock',
        response: {
          report: report,
          baseline_iterations: baseline_iterations,
          context_iterations: context_iterations
        }
      }
    end

    def build_result_with_reasoning(baseline:, context:)
      dimensions = baseline.keys.map do |name|
        desc = name == 'code_quality' ? 'Clean code matters' : ''
        Dimension.new(name: name, description: desc, max_score: baseline[name][:max_score])
      end
      report = DeltaReport.new(
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
      {
        success: true,
        eval_name: 'reasoning-eval',
        skill_name: 'test-skill',
        provider_name: 'mock',
        response: {
          report: report,
          baseline_iterations: [],
          context_iterations: []
        }
      }
    end

    def build_delta_report(verdict:)
      dimensions = [
        Dimension.new(name: 'correctness', description: '', max_score: 30),
        Dimension.new(name: 'skill_adherence', description: '', max_score: 25)
      ]
      baseline = {
        'correctness' => { score: 12, max_score: 30, reasoning: '' },
        'skill_adherence' => { score: 5, max_score: 25, reasoning: '' }
      }
      context = {
        'correctness' => { score: 28, max_score: 30, reasoning: '' },
        'skill_adherence' => { score: 22, max_score: 25, reasoning: '' }
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
