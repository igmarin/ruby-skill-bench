# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'tempfile'

module SkillBench
  class WriteYardDocsBasicEvalTest < Minitest::Test
    EVAL_DIR = File.expand_path('../../evals/skills/write-yard-docs/basic', __dir__)
    SKILL_PATH = File.expand_path('../../skills/write-yard-docs/SKILL.md', __dir__)

    def test_eval_loads_and_names_the_fixture_files
      evaluation = Models::Eval.load(EVAL_DIR)

      assert_includes evaluation.task, 'price_calculator.rb'
      assert_includes evaluation.task, 'price_calculator_test.rb'
    end

    def test_eval_ships_undocumented_public_methods
      source = File.read(File.join(EVAL_DIR, 'price_calculator.rb'))

      assert_path_exists File.join(EVAL_DIR, 'price_calculator.rb')
      assert_path_exists File.join(EVAL_DIR, 'price_calculator_test.rb')
      refute_includes source, '@param'
      refute_includes source, '@return'
      refute_includes source, '@raise'
    end

    def test_starting_calculator_tests_pass
      stdout, stderr, status = Open3.capture3('ruby', 'price_calculator_test.rb', chdir: EVAL_DIR)

      assert_predicate status, :success?, "fixture tests failed:\n#{stdout}\n#{stderr}"
      assert_includes stdout, '0 failures'
    end

    def test_skill_example_is_valid_ruby_with_yard_tags
      skill = File.read(SKILL_PATH)
      example = skill[/```ruby\n(.*?)```/m, 1]

      refute_nil example, 'SKILL.md must include a ruby example'
      assert_includes example, '@param'
      assert_includes example, '@return'
      assert_includes example, '@raise'

      Tempfile.create(['yard_example', '.rb']) do |file|
        file.write(example)
        file.flush
        _stdout, stderr, status = Open3.capture3('ruby', '-c', file.path)

        assert_predicate status, :success?, stderr
      end
    end
  end
end
