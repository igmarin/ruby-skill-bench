# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'tempfile'

module SkillBench
  class RefactorProcessBasicEvalTest < Minitest::Test
    EVAL_DIR = File.expand_path('../../evals/skills/refactor-process/basic', __dir__)
    SKILL_PATH = File.expand_path('../../skills/refactor-process/SKILL.md', __dir__)

    def test_eval_loads_and_names_the_fixture_files
      evaluation = Models::Eval.load(EVAL_DIR)

      assert_includes evaluation.task, 'order_processor.rb'
      assert_includes evaluation.task, 'order_processor_test.rb'
    end

    def test_eval_ships_duplicated_processors_without_extracted_helpers
      source = File.read(File.join(EVAL_DIR, 'order_processor.rb'))

      assert_path_exists File.join(EVAL_DIR, 'order_processor.rb')
      assert_path_exists File.join(EVAL_DIR, 'order_processor_test.rb')
      assert_equal 2, source.scan('sku required').size
      assert_equal 2, source.scan('quantity must be positive').size
      refute_includes source, 'def validate'
      refute_includes source, 'def price'
    end

    def test_starting_processor_tests_pass
      stdout, stderr, status = Open3.capture3('ruby', 'order_processor_test.rb', chdir: EVAL_DIR)

      assert_predicate status, :success?, "fixture tests failed:\n#{stdout}\n#{stderr}"
      assert_includes stdout, '0 failures'
    end

    def test_skill_example_is_valid_ruby
      skill = File.read(SKILL_PATH)
      example = skill[/```ruby\n(.*?)```/m, 1]

      refute_nil example, 'SKILL.md must include a ruby example'

      Tempfile.create(['refactor_example', '.rb']) do |file|
        file.write(example)
        file.flush
        _stdout, stderr, status = Open3.capture3('ruby', '-c', file.path)

        assert_predicate status, :success?, stderr
      end
    end
  end
end
