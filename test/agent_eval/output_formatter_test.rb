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

    private

    def build_delta_report(verdict:)
      dimensions = [
        Dimension.new(name: 'correctness', description: '', max_score: 30),
        Dimension.new(name: 'skill_adherence', description: '', max_score: 25)
      ]
      DeltaReport.new(
        baseline: {
          'correctness' => { score: 12, max_score: 30, reasoning: '' },
          'skill_adherence' => { score: 5, max_score: 25, reasoning: '' }
        },
        context: {
          'correctness' => { score: 28, max_score: 30, reasoning: '' },
          'skill_adherence' => { score: 22, max_score: 25, reasoning: '' }
        },
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
