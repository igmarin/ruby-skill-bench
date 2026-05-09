# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class EvalCommandTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('cli_eval_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
        FileUtils.mkdir('evals')
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_new_creates_eval
        exit_code = EvalCommand.call(%w[new my-eval])

        assert_equal 0, exit_code
        assert_path_exists 'evals/my-eval/task.md'
        assert_path_exists 'evals/my-eval/criteria.json'
      end

      def test_call_new_with_runtime
        exit_code = EvalCommand.call(['new', 'my-eval', '--runtime=rails'])

        assert_equal 0, exit_code
        content = File.read('evals/my-eval/criteria.json')
        config = JSON.parse(content)

        assert_equal 'Evaluate rails task', config['context']
      end

      def test_call_new_without_name_returns_error
        exit_code = EvalCommand.call(['new'])

        assert_equal 1, exit_code
      end

      def test_call_with_help
        exit_code = EvalCommand.call(['--help'])

        assert_equal 0, exit_code
      end

      def test_call_with_nil_action_shows_help
        exit_code = EvalCommand.call([])

        assert_equal 0, exit_code
      end

      def test_call_with_unknown_action_returns_error
        exit_code = EvalCommand.call(['unknown'])

        assert_equal 1, exit_code
      end
    end
  end
end
