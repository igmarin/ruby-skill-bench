# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class ResultPrinterTest < Minitest::Test
      def test_call_prints_pass_result
        result = {
          pass: true,
          score: 1.0,
          eval_name: 'test-eval',
          skill_name: 'test-skill',
          provider_name: 'openai'
        }

        assert_output(/Eval: test-eval.*Skill: test-skill.*Provider: openai.*Status: PASSED/m) do
          exit_code = ResultPrinter.call(result)

          assert_equal 0, exit_code
        end
      end

      def test_call_prints_fail_result
        result = {
          pass: false,
          score: 0.5,
          eval_name: 'test-eval',
          skill_name: 'test-skill',
          provider_name: 'gemini'
        }

        assert_output(/Eval: test-eval.*Skill: test-skill.*Provider: gemini.*Status: FAILED/m) do
          exit_code = ResultPrinter.call(result)

          assert_equal 1, exit_code
        end
      end

      def test_call_returns_zero_for_pass
        result = { pass: true, score: 0.9, eval_name: 'e', skill_name: 's', provider_name: 'p' }

        assert_equal 0, ResultPrinter.call(result)
      end

      def test_call_returns_one_for_fail
        result = { pass: false, score: 0.3, eval_name: 'e', skill_name: 's', provider_name: 'p' }

        assert_equal 1, ResultPrinter.call(result)
      end

      def assert_sends_output(pattern)
        old_stderr = $stderr
        $stderr = StringIO.new
        yield
        output = $stderr.string
      ensure
        $stderr = old_stderr

        assert_match(pattern, output)
      end
    end
  end
end
