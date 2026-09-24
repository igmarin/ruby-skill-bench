# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/skill_bench/runner'
require 'tmpdir'
require 'fileutils'

module SkillBench
  class RunnerTest < Minitest::Test
    def setup
      @base_path = Pathname.new(Dir.mktmpdir)
    end

    def teardown
      FileUtils.rm_rf(@base_path)
    end

    def test_top_level_entry_point_keeps_deprecated_runner_available
      assert SkillBench.const_defined?(:Runner)
    end

    def test_call_runs_baseline_and_context_and_returns_judge_scores
      create_eval_fixture('evals/skills/ruby-service-objects/basic-service-object')

      expect_single_task_run(source_path: 'skills/ruby-service-objects')

      result = Runner.call(
        eval_folder_path: 'evals/skills/ruby-service-objects/basic-service-object',
        base_path: @base_path
      )

      assert result[:success]
      assert_equal 'multiple (batch run)', result[:response][:source_path]
      task_response = result[:response][:tasks].first[:response]

      assert_includes task_response[:judge_score][:response][:content], 'baseline_score'
    end

    def test_call_with_explicit_skill_override
      create_eval_fixture('evals/workflows/rails-tdd-loop/full-feature')

      expect_single_task_run(source_path: 'skills/ruby-service-objects')

      result = Runner.call(
        eval_folder_path: 'evals/workflows/rails-tdd-loop/full-feature',
        skill_path: 'skills/ruby-service-objects',
        base_path: @base_path
      )

      assert result[:success]
      assert_equal 'skills/ruby-service-objects', result[:response][:source_path]
    end

    def test_call_fails_without_context_when_source_path_cannot_be_inferred
      create_eval_fixture('tmp/custom-evals/unmapped-task')

      Agent::Runner.expects(:call).never

      result = Runner.call(
        eval_folder_path: 'tmp/custom-evals/unmapped-task',
        base_path: @base_path
      )

      refute result[:success]
      assert_equal 'multiple (batch run)', result[:response][:source_path]
    end

    def test_discover_task_dirs_returns_root_task_without_nested_tasks
      root = @base_path.join('evals')
      create_eval_fixture('evals')
      create_eval_fixture('evals/nested')

      assert_equal [root], Runner.discover_task_dirs(root)
    end

    def test_discover_task_dirs_returns_nested_tasks_in_sorted_order
      create_eval_fixture('evals/z-last')
      create_eval_fixture('evals/a-first')

      task_dirs = Runner.discover_task_dirs(@base_path.join('evals'))
      task_names = task_dirs.map { |path| path.basename.to_s }

      assert_equal %w[a-first z-last], task_names
    end

    def test_discover_task_dirs_returns_empty_array_when_no_tasks_exist
      root = @base_path.join('evals')
      root.mkpath

      assert_empty Runner.discover_task_dirs(root)
    end

    private

    def create_eval_fixture(relative_path)
      full_path = @base_path.join(relative_path)
      full_path.mkpath
      File.write(full_path.join('task.md'), 'Test task')
      File.write(full_path.join('criteria.json'), '{}')
    end

    def expect_single_task_run(source_path:)
      judge_result = { success: true, response: { content: '{"baseline_score":60,"context_score":85,"reasoning":"context is better"}' } }

      Agent::Runner.expects(:call).with(
        has_entries(mode: :baseline)
      ).returns(%w[baseline_output baseline_diff]).once

      Agent::Runner.expects(:call).with(
        has_entries(mode: :context, source_path: source_path)
      ).returns(%w[context_output context_diff]).once

      Judge::Judge.expects(:call).returns(judge_result).once
    end
  end
end
