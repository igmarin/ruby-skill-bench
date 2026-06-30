# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class BatchRunnerServiceTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('batch_runner_test')
        Dir.chdir(@tmp_dir)
        create_eval('eval-a')
        create_eval('eval-b')
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_discovers_multiple_eval_dirs_and_aggregates_results
        RunnerService.stubs(:call).returns(pass_result)

        aggregate = BatchRunnerService.call(evals_dir: 'evals', skill_names: ['test-skill'])

        assert_equal 2, aggregate[:results].size
        assert_equal 2, aggregate[:summary][:total]
      end

      def test_summary_counts_passed_and_failed
        RunnerService.stubs(:call).with { |kw| kw[:eval_name].end_with?('eval-a') }.returns(pass_result)
        RunnerService.stubs(:call).with { |kw| kw[:eval_name].end_with?('eval-b') }.returns(fail_result)

        aggregate = BatchRunnerService.call(evals_dir: 'evals', skill_names: ['test-skill'])

        assert_equal 2, aggregate[:summary][:total]
        assert_equal 1, aggregate[:summary][:passed]
        assert_equal 1, aggregate[:summary][:failed]
      end

      def test_counts_error_results_as_failures
        RunnerService.stubs(:call).returns(error_result)

        aggregate = BatchRunnerService.call(evals_dir: 'evals', skill_names: ['test-skill'])

        assert_equal 0, aggregate[:summary][:passed]
        assert_equal 2, aggregate[:summary][:failed]
      end

      def test_forwards_skill_pack_and_manifest_to_runner_service
        RunnerService.expects(:call).with do |kw|
          kw[:skill_names] == ['test-skill'] && kw[:pack] == 'my-pack' && kw[:registry_manifest] == 'reg.json'
        end.at_least_once.returns(pass_result)

        BatchRunnerService.call(
          evals_dir: 'evals',
          skill_names: ['test-skill'],
          pack: 'my-pack',
          registry_manifest: 'reg.json'
        )
      end

      def test_raises_when_no_evals_found
        assert_raises(ArgumentError) do
          BatchRunnerService.call(evals_dir: 'nonexistent', skill_names: ['test-skill'])
        end
      end

      private

      def create_eval(name)
        dir = File.join('evals', name)
        FileUtils.mkpath(dir)
        File.write(File.join(dir, 'task.md'), "Task #{name}")
      end

      def pass_result
        { success: true, response: { report: verdict_report(true) } }
      end

      def fail_result
        { success: true, response: { report: verdict_report(false) } }
      end

      def error_result
        { success: false, response: { error: { message: 'boom' } } }
      end

      def verdict_report(verdict)
        Struct.new(:verdict).new(verdict)
      end
    end
  end
end
