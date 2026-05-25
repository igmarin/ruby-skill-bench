# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class CompareCommandTest < Minitest::Test
    def test_help_flag_prints_help
      exit_code = Cli::CompareCommand.call(['-h'])

      assert_equal 0, exit_code
    end

    def test_missing_skill_name
      exit_code = Cli::CompareCommand.call([])

      assert_equal 1, exit_code
    end

    def test_missing_variant_a
      stdout_orig = $stdout
      $stdout = StringIO.new
      begin
        exit_code = Cli::CompareCommand.call(['plan-tests', '--variant-b', 'pack:hanami', '--eval', 'evals/test'])
      ensure
        $stdout = stdout_orig
      end

      assert_equal 1, exit_code
    end

    def test_missing_variant_b
      stdout_orig = $stdout
      $stdout = StringIO.new
      begin
        exit_code = Cli::CompareCommand.call(['plan-tests', '--variant-a', 'pack:rails', '--eval', 'evals/test'])
      ensure
        $stdout = stdout_orig
      end

      assert_equal 1, exit_code
    end

    def test_missing_eval
      stdout_orig = $stdout
      $stdout = StringIO.new
      begin
        exit_code = Cli::CompareCommand.call(['plan-tests', '--variant-a', 'pack:rails', '--variant-b', 'pack:hanami'])
      ensure
        $stdout = stdout_orig
      end

      assert_equal 1, exit_code
    end
  end
end
