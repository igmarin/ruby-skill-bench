# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Cli
    class RunCommandTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('cli_run_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)

        FileUtils.mkdir_p('evals/test-eval')
        File.write('evals/test-eval/task.md', 'Test task')
        File.write('evals/test-eval/criteria.json', valid_criteria_json)

        FileUtils.mkdir_p('skills/test-skill')
        File.write('skills/test-skill/SKILL.md', 'Test skill')

        config = {
          provider: 'mock',
          max_execution_time: 30,
          config: {}
        }
        File.write('skill-bench.json', JSON.generate(config))

        SkillBench::Evaluation::Runner.stubs(:call).returns({
                                                              success: true,
                                                              response: { report: build_report_struct }
                                                            })
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_with_eval_and_skill
        exit_code = RunCommand.call(['test-eval', '--skill=test-skill'])

        assert_equal 0, exit_code
      end

      def test_call_with_full_path_eval
        exit_code = RunCommand.call(['evals/test-eval', '--skill=test-skill'])

        assert_equal 0, exit_code
      end

      def test_call_without_eval_returns_error
        exit_code = RunCommand.call(['--skill=test-skill'])

        assert_equal 1, exit_code
      end

      def test_call_without_skill_returns_error
        exit_code = RunCommand.call(['test-eval'])

        assert_equal 1, exit_code
      end

      def test_call_with_multiple_skills
        FileUtils.mkdir_p('skills/second-skill')
        File.write('skills/second-skill/SKILL.md', 'Second skill')

        SkillBench::Evaluation::Runner.expects(:call).with do |args|
          args[:skill_context].include?('Test skill') && args[:skill_context].include?('Second skill')
        end.returns({
                      success: true,
                      response: { report: build_report_struct }
                    })

        exit_code = RunCommand.call(['test-eval', '--skill=test-skill', '--skill=second-skill'])

        assert_equal 0, exit_code
      end

      def test_all_flag_dispatches_to_batch_runner
        SkillBench::Services::BatchRunnerService.expects(:call).returns(batch_aggregate(failed: 0))

        exit_code = RunCommand.call(['--all', '--skill=test-skill'])

        assert_equal 0, exit_code
      end

      def test_evals_dir_flag_dispatches_to_batch_runner_with_dir
        SkillBench::Services::BatchRunnerService.expects(:call).with do |kw|
          kw[:evals_dir] == 'custom-evals'
        end.returns(batch_aggregate(failed: 0))

        exit_code = RunCommand.call(['--evals-dir=custom-evals', '--skill=test-skill'])

        assert_equal 0, exit_code
      end

      def test_batch_exit_code_nonzero_when_any_eval_fails
        SkillBench::Services::BatchRunnerService.stubs(:call).returns(batch_aggregate(failed: 1))

        exit_code = RunCommand.call(['--all', '--skill=test-skill'])

        assert_equal 1, exit_code
      end

      def test_batch_without_skill_returns_error
        SkillBench::Services::BatchRunnerService.expects(:call).never

        exit_code = RunCommand.call(['--all'])

        assert_equal 1, exit_code
      end

      private

      def batch_aggregate(failed:)
        results = [{ success: true, eval_name: 'evals/eval-a', response: { report: build_report_struct } }]
        results << { success: false, eval_name: 'evals/eval-b', response: { error: { message: 'boom' } } } if failed.positive?
        passed = results.size - failed
        { results: results, summary: { total: results.size, passed: passed, failed: failed } }
      end

      def build_report_struct
        Struct.new(:verdict, :baseline_total, :context_total, :deltas, keyword_init: true).new(
          verdict: true, baseline_total: 30, context_total: 80, deltas: { 'correctness' => 16 }
        )
      end

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
