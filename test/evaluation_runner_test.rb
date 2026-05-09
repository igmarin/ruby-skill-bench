# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class EvaluationRunnerTest < Minitest::Test
    def test_orchestrates_baseline_context_and_judging
      criteria = build_criteria
      baseline_output = 'Baseline git diff'
      context_output = 'Context git diff'

      judge_baseline = {
        success: true,
        response: { judge_response: build_judge_response(10, 8, 6, 4, 2) }
      }
      judge_context = {
        success: true,
        response: { judge_response: build_judge_response(25, 20, 15, 12, 8) }
      }

      Judge.expects(:call).with(prompt: 'Baseline prompt').returns(judge_baseline)
      Judge.expects(:call).with(prompt: 'Context prompt').returns(judge_context)

      JudgePrompt.expects(:call).with(
        task: 'Test task',
        criteria: criteria,
        skill_context: '',
        agent_output: baseline_output
      ).returns({ success: true, response: { prompt: 'Baseline prompt' } })

      JudgePrompt.expects(:call).with(
        task: 'Test task',
        criteria: criteria,
        skill_context: 'Skill context',
        agent_output: context_output
      ).returns({ success: true, response: { prompt: 'Context prompt' } })

      result = EvaluationRunner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: 'Skill context',
        baseline_output: baseline_output,
        context_output: context_output
      )

      assert result[:success]
      report = result[:response][:report]

      assert report.verdict
      assert_equal 80, report.context_total
      assert_equal 30, report.baseline_total
      assert_equal 50, report.deltas.values.sum
    end

    def test_returns_error_when_judge_fails
      criteria = build_criteria

      JudgePrompt.expects(:call).returns({ success: true, response: { prompt: 'Prompt' } })
      Judge.expects(:call).returns({ success: false, response: { error: { message: 'Judge failed' } } })

      result = EvaluationRunner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: '',
        baseline_output: 'output',
        context_output: 'output'
      )

      refute result[:success]
      assert_match(/Judge failed/, result[:response][:error][:message])
    end

    private

    def build_criteria
      dimensions = [
        Dimension.new(name: 'correctness', description: '', max_score: 30),
        Dimension.new(name: 'skill_adherence', description: '', max_score: 25),
        Dimension.new(name: 'code_quality', description: '', max_score: 20),
        Dimension.new(name: 'test_coverage', description: '', max_score: 15),
        Dimension.new(name: 'documentation', description: '', max_score: 10)
      ]
      Criteria.new(path: '/dev/null').tap do |c|
        c.instance_variable_set(:@context, '')
        c.instance_variable_set(:@pass_threshold, 70)
        c.instance_variable_set(:@minimum_delta, 10)
        c.instance_variable_set(:@dimensions, dimensions)
      end
    end

    def build_judge_response(correctness, skill, quality, coverage, docs)
      JudgeResponse.new(json: '').tap do |jr|
        jr.instance_variable_set(:@dimensions, {
                                   'correctness' => { score: correctness, max_score: 30, reasoning: '' },
                                   'skill_adherence' => { score: skill, max_score: 25, reasoning: '' },
                                   'code_quality' => { score: quality, max_score: 20, reasoning: '' },
                                   'test_coverage' => { score: coverage, max_score: 15, reasoning: '' },
                                   'documentation' => { score: docs, max_score: 10, reasoning: '' }
                                 })
        jr.instance_variable_set(:@overall_reasoning, '')
      end
    end
  end
end
