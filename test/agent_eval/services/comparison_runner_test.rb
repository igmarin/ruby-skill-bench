# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ComparisonRunnerTest < Minitest::Test
      def setup
        @variant_a = { type: :path, path: '/path/to/skill-a' }
        @variant_b = { type: :path, path: '/path/to/skill-b' }
        @skill_name = 'test-skill'
        @eval_path = 'evals/test'
      end

      def test_call_runs_both_variants
        Services::RunnerService.stubs(:call).returns(success: true, response: {}).twice

        result = ComparisonRunner.call(@variant_a, @variant_b, @skill_name, @eval_path)

        assert result.key?(:result_a)
        assert result.key?(:result_b)
      end

      def test_call_passes_eval_path_to_runner
        Services::VariantResolver.stubs(:call).returns(['/path/to/skill']).twice
        Services::RunnerService.stubs(:call).with do |kwargs|
          kwargs[:eval_name] == @eval_path
        end.returns(success: true, response: {}).twice

        ComparisonRunner.call(@variant_a, @variant_b, @skill_name, @eval_path)
      end
    end
  end
end
