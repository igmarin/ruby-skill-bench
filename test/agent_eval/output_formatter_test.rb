# frozen_string_literal: true

require 'test_helper'

module AgentEval
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
      assert_includes output, '<testsuite name="AgentEval" tests="1" failures="0">'
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
  end
end
