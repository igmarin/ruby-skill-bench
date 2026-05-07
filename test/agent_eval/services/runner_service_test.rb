# frozen_string_literal: true

require 'test_helper'

module AgentEval
  module Services
    class RunnerServiceTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('runner_service_test')
        @eval_dir = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(@eval_dir)
        File.write(File.join(@eval_dir, 'task.md'), 'Test task')
        File.write(File.join(@eval_dir, 'criteria.json'), '{"pass": {"score_threshold": 0.8}}')

        @skill_dir = File.join(@tmp_dir, 'skills', 'test-skill')
        FileUtils.mkpath(@skill_dir)
        File.write(File.join(@skill_dir, 'SKILL.md'), 'Test skill')

        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_returns_result_for_mock_provider
        Models::Config.instance_variable_set(:@loaded, nil)

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_name: 'test-skill',
          provider_name: 'mock'
        )

        assert result[:pass]
        assert_in_delta(1.0, result[:score])
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_call_raises_when_eval_not_found
        Models::Config.instance_variable_set(:@loaded, nil)

        assert_raises(Errno::ENOENT) do
          RunnerService.call(
            eval_name: 'nonexistent',
            skill_name: 'test-skill',
            provider_name: 'mock'
          )
        end
      end

      def test_call_raises_when_skill_not_found
        Models::Config.instance_variable_set(:@loaded, nil)

        assert_raises(RuntimeError) do
          RunnerService.call(
            eval_name: 'test-eval',
            skill_name: 'nonexistent',
            provider_name: 'mock'
          )
        end
      end

      def test_call_raises_when_provider_not_found
        Models::Config.instance_variable_set(:@loaded, nil)

        assert_raises(RuntimeError) do
          RunnerService.call(
            eval_name: 'test-eval',
            skill_name: 'test-skill',
            provider_name: 'nonexistent'
          )
        end
      end

      def test_call_resolves_eval_with_full_path
        Models::Config.instance_variable_set(:@loaded, nil)

        result = RunnerService.call(
          eval_name: 'evals/test-eval',
          skill_name: 'test-skill',
          provider_name: 'mock'
        )

        assert result[:pass]
      end
    end
  end
end
