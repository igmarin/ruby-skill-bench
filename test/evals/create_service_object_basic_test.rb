# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'tempfile'

module SkillBench
  class CreateServiceObjectBasicEvalTest < Minitest::Test
    EVAL_DIR = File.expand_path('../../evals/skills/create-service-object/basic', __dir__)

    def test_eval_loads_and_names_the_fixture_files
      evaluation = Models::Eval.load(EVAL_DIR)

      assert_includes evaluation.task, 'orders_controller.rb'
      assert_includes evaluation.task, 'orders_controller_test.rb'
      assert_includes evaluation.task, 'ProcessOrder'
    end

    def test_eval_ships_a_fat_controller_without_the_extracted_service
      assert_path_exists File.join(EVAL_DIR, 'orders_controller.rb')
      assert_path_exists File.join(EVAL_DIR, 'orders_controller_test.rb')
      refute_path_exists File.join(EVAL_DIR, 'process_order.rb'),
                         'starting fixture must not already contain ProcessOrder'
    end

    def test_starting_controller_tests_pass
      stdout, stderr, status = Open3.capture3('ruby', 'orders_controller_test.rb', chdir: EVAL_DIR)

      assert_predicate status, :success?, "fixture tests failed:\n#{stdout}\n#{stderr}"
      assert_includes stdout, '0 failures'
    end

    def test_skill_example_is_valid_ruby_with_yard_on_entry_points
      skill = File.read(File.expand_path('../../skills/create-service-object/SKILL.md', __dir__))
      example = skill[/```ruby\n(.*?)```/m, 1]

      refute_nil example, 'SKILL.md must include a ruby example'

      %w[sku quantity paid].each do |name|
        assert_includes example, "@param #{name}"
      end
      assert_equal 2, example.scan('@return').size, 'self.call and #call each need @return'

      Tempfile.create(['process_order', '.rb']) do |file|
        file.write(example)
        file.flush
        _stdout, stderr, status = Open3.capture3('ruby', '-c', file.path)

        assert_predicate status, :success?, stderr
      end
    end
  end
end
