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

        SkillBench::EvaluationRunner.stubs(:call).returns({
                                                            success: true,
                                                            response: { report: Struct.new(:verdict, keyword_init: true).new(verdict: true) }
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
