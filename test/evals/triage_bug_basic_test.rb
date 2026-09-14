# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'tempfile'

module SkillBench
  class TriageBugBasicEvalTest < Minitest::Test
    EVAL_DIR = File.expand_path('../../evals/skills/triage-bug/basic', __dir__)
    SKILL_PATH = File.expand_path('../../skills/triage-bug/SKILL.md', __dir__)

    def test_eval_loads_and_names_the_fixture_files
      evaluation = Models::Eval.load(EVAL_DIR)

      assert_includes evaluation.task, 'discount.rb'
      assert_includes evaluation.task, 'discount_test.rb'
      assert_includes evaluation.task, '999'
    end

    def test_eval_ships_the_integer_division_bug_without_a_regression_test
      assert_path_exists File.join(EVAL_DIR, 'discount.rb')
      assert_path_exists File.join(EVAL_DIR, 'discount_test.rb')

      stdout, stderr, status = Open3.capture3(
        'ruby', '-e', "require_relative 'discount'; print Discount.apply(cents: 999, percent: 10)",
        chdir: EVAL_DIR
      )

      assert_predicate status, :success?, stderr
      assert_equal '90', stdout, 'starting fixture must still contain the integer-division bug'
      refute_includes File.read(File.join(EVAL_DIR, 'discount_test.rb')), '999'
    end

    def test_starting_discount_tests_pass
      stdout, stderr, status = Open3.capture3('ruby', 'discount_test.rb', chdir: EVAL_DIR)

      assert_predicate status, :success?, "fixture tests failed:\n#{stdout}\n#{stderr}"
      assert_includes stdout, '0 failures'
    end

    def test_skill_example_is_valid_ruby
      skill = File.read(SKILL_PATH)
      example = skill[/```ruby\n(.*?)```/m, 1]

      refute_nil example, 'SKILL.md must include a ruby example'

      Tempfile.create(['triage_example', '.rb']) do |file|
        file.write(example)
        file.flush
        _stdout, stderr, status = Open3.capture3('ruby', '-c', file.path)

        assert_predicate status, :success?, stderr
      end
    end
  end
end
