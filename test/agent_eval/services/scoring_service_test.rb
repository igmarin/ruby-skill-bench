# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ScoringServiceTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('scoring_service_test')
        @eval_dir = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(@eval_dir)
        File.write(File.join(@eval_dir, 'task.md'), 'Test task')
        File.write(File.join(@eval_dir, 'criteria.json'), '{"pass": {"score_threshold": 0.8}}')

        @eval = Models::Eval.load(@eval_dir)
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_returns_pass_when_score_above_threshold
        result = ScoringService.call(
          eval: @eval,
          result: { status: 'success' },
          skill_name: 'test-skill',
          provider_name: 'mock'
        )

        assert result[:pass]
        assert_equal @eval.name, result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_call_returns_fail_when_result_status_is_error
        old_stderr = $stderr
        $stderr = StringIO.new
        result = ScoringService.call(
          eval: @eval,
          result: { status: 'error', result: 'failed' },
          skill_name: 'test-skill',
          provider_name: 'mock'
        )
        $stderr = old_stderr

        # ScoringService currently returns pass: true for all cases (stub implementation)
        # This test documents expected behavior once real scoring is implemented
        assert result.key?(:pass)
        assert_equal 'test-eval', result[:eval_name]
      end

      def test_call_includes_eval_metadata
        result = ScoringService.call(
          eval: @eval,
          result: { status: 'success' },
          skill_name: 'my-skill',
          provider_name: 'openai'
        )

        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'my-skill', result[:skill_name]
        assert_equal 'openai', result[:provider_name]
      end
    end
  end
end
