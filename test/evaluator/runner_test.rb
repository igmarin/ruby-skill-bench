# frozen_string_literal: true

require 'test_helper'
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

      AgentRunner.expects(:call).never

      result = Runner.call(
        eval_folder_path: 'tmp/custom-evals/unmapped-task',
        base_path: @base_path
      )

      refute result[:success]
      assert_equal 'multiple (batch run)', result[:response][:source_path]
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

      AgentRunner.expects(:call).with(
        has_entries(mode: :baseline)
      ).returns(%w[baseline_output baseline_diff]).once

      AgentRunner.expects(:call).with(
        has_entries(mode: :context, source_path: source_path)
      ).returns(%w[context_output context_diff]).once

      Judge.expects(:call).returns(judge_result).once
    end
  end
end
