# frozen_string_literal: true

require 'test_helper'
require 'open3'

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
  end
end
