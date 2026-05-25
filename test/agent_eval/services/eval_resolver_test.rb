# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class EvalResolverTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('eval_resolver_test')
        @eval_dir = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(@eval_dir)
        File.write(File.join(@eval_dir, 'task.md'), 'Test task')
        File.write(File.join(@eval_dir, 'criteria.json'), valid_criteria_json)
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_resolves_eval_by_name
        result = EvalResolver.call('test-eval')

        assert_equal 'test-eval', result.name
        assert_equal 'Test task', result.task
      end

      def test_call_resolves_eval_by_path
        result = EvalResolver.call('evals/test-eval')

        assert_equal 'test-eval', result.name
        assert_equal 'Test task', result.task
      end

      def test_call_raises_when_eval_not_found
        assert_raises(Errno::ENOENT) do
          EvalResolver.call('nonexistent')
        end
      end

      private

      def valid_criteria_json
        {
          context: 'Evaluate test',
          dimensions: [
            { name: 'correctness', max_score: 30 },
            { name: 'skill_adherence', max_score: 25 },
            { name: 'code_quality', max_score: 20 },
            { name: 'test_coverage', max_score: 15 },
            { name: 'documentation', max_score: 10 }
          ],
          pass_threshold: 70,
          minimum_delta: 10
        }.to_json
      end
    end
  end
end
