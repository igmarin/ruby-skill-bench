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
          result: { status: :success },
          skill_name: 'test-skill',
          provider_name: 'mock'
        )

        assert result[:pass]
        assert_equal @eval.name, result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_call_returns_fail_when_result_status_is_error
        result = ScoringService.call(
          eval: @eval,
          result: {
            status: :error,
            test_results: [{ status: :failed }, { status: :failed }],
            error_count: 1,
            total_count: 1
          },
          skill_name: 'test-skill',
          provider_name: 'mock'
        )

        refute result[:pass]
        assert_in_delta 0.3, result[:score], 0.01
        assert_equal 'test-eval', result[:eval_name]
      end

      def test_call_includes_eval_metadata
        result = ScoringService.call(
          eval: @eval,
          result: { status: :success },
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
