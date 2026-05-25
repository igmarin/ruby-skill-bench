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
      exit_code = Cli::CompareCommand.call(['plan-tests', '--variant-b', 'pack:hanami', '--eval', 'evals/test'])
      $stdout = stdout_orig

      assert_equal 1, exit_code
    end

    def test_missing_variant_b
      stdout_orig = $stdout
      $stdout = StringIO.new
      exit_code = Cli::CompareCommand.call(['plan-tests', '--variant-a', 'pack:rails', '--eval', 'evals/test'])
      $stdout = stdout_orig

      assert_equal 1, exit_code
    end

    def test_missing_eval
      stdout_orig = $stdout
      $stdout = StringIO.new
      exit_code = Cli::CompareCommand.call(['plan-tests', '--variant-a', 'pack:rails', '--variant-b', 'pack:hanami'])
      $stdout = stdout_orig

      assert_equal 1, exit_code
    end

    def test_parse_variant_pack
      command = Cli::CompareCommand.new([])
      result = command.send(:parse_variant, 'pack:rails')

      assert_equal({ type: :pack, name: 'rails' }, result)
    end

    def test_parse_variant_path
      command = Cli::CompareCommand.new([])
      result = command.send(:parse_variant, '/path/to/skill')

      assert_equal({ type: :path, path: '/path/to/skill' }, result)
    end
  end
end
