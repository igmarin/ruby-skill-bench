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

      Judge::Judge.expects(:call).with(prompt: 'Baseline prompt', client_params: {}).returns(judge_baseline)
      Judge::Judge.expects(:call).with(prompt: 'Context prompt', client_params: {}).returns(judge_context)

      Judge::Prompt.expects(:call).with(
        task: 'Test task',
        criteria: criteria,
        skill_context: nil,
        agent_output: baseline_output
      ).returns({ success: true, response: { prompt: 'Baseline prompt' } })

      Judge::Prompt.expects(:call).with(
        task: 'Test task',
        criteria: criteria,
        skill_context: 'Skill context',
        agent_output: context_output
      ).returns({ success: true, response: { prompt: 'Context prompt' } })

      result = Evaluation::Runner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: 'Skill context',
        baseline_output: baseline_output,
        context_output: context_output,
        judge_params: {}
      )

      assert result[:success]
      report = result[:response][:report]

      assert report.verdict
      assert_equal 80, report.context_total
      assert_equal 30, report.baseline_total
      assert_equal 50, report.deltas.values.sum
    end

    def test_passes_judge_params_to_judge
      criteria = build_criteria
      judge_params = { api_key: 'test-key', model: 'deepseek-chat', provider: :deepseek }

      Judge::Prompt.expects(:call).twice.returns({ success: true, response: { prompt: 'Prompt' } })
      Judge::Judge.expects(:call).with(prompt: 'Prompt', client_params: judge_params).twice.returns({
                                                                                                      success: true,
                                                                                                      response: { judge_response: build_judge_response(10, 8, 6, 4, 2) }
                                                                                                    })

      result = Evaluation::Runner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: '',
        baseline_output: 'output',
        context_output: 'output',
        judge_params: judge_params
      )

      assert result[:success]
    end

    def test_returns_error_when_judge_fails
      criteria = build_criteria
      # Both judges now run concurrently, so stub the shared prompt/judge
      # paths instead of expecting a single short-circuited call.
      Judge::Prompt.stubs(:call).returns({ success: true, response: { prompt: 'Prompt' } })
      Judge::Judge.stubs(:call).returns({ success: false, response: { error: { message: 'Judge failed' } } })

      result = Evaluation::Runner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: '',
        baseline_output: 'output',
        context_output: 'output',
        judge_params: {}
      )

      refute result[:success]
      assert_match(/Judge failed/, result[:response][:error][:message])
    end

    def test_surfaces_baseline_error_with_precedence_when_both_judges_fail
      criteria = build_criteria
      stub_prompt_paths
      Judge::Judge.stubs(:call).with { |args| args[:prompt] == 'Baseline prompt' }
                               .returns({ success: false, response: { error: { message: 'Baseline judge failed' } } })
      Judge::Judge.stubs(:call).with { |args| args[:prompt] == 'Context prompt' }
                               .returns({ success: false, response: { error: { message: 'Context judge failed' } } })

      result = run_with_distinct_outputs(criteria)

      refute result[:success]
      # The sequential code returned the baseline failure first and never ran
      # the context judge; the concurrent code must keep that precedence even
      # though both judges now execute.
      assert_match(/Baseline judge failed/, result[:response][:error][:message])
      refute_match(/Context judge failed/, result[:response][:error][:message])
    end

    def test_surfaces_context_error_when_only_context_judge_fails
      criteria = build_criteria
      stub_prompt_paths
      Judge::Judge.stubs(:call).with { |args| args[:prompt] == 'Baseline prompt' }
                               .returns({ success: true, response: { judge_response: build_judge_response(10, 8, 6, 4, 2) } })
      Judge::Judge.stubs(:call).with { |args| args[:prompt] == 'Context prompt' }
                               .returns({ success: false, response: { error: { message: 'Context judge failed' } } })

      result = run_with_distinct_outputs(criteria)

      refute result[:success]
      assert_match(/Context judge failed/, result[:response][:error][:message])
    end

    def test_handles_non_hash_judge_params
      criteria = build_criteria
      Judge::Prompt.stubs(:call).returns({ success: true, response: { prompt: 'Prompt' } })
      Judge::Judge.stubs(:call).returns({
                                          success: true,
                                          response: { judge_response: build_judge_response(10, 8, 6, 4, 2) }
                                        })
      DeltaReport.stubs(:call).returns({
                                         success: true,
                                         response: { delta_report: Struct.new(:verdict, :baseline_total,
                                                                              :context_total, :deltas, :criteria, keyword_init: true).new(verdict: true,
                                                                                                                                          baseline_total: 30, context_total: 80, deltas: {},
                                                                                                                                          criteria: build_criteria) }
                                       })

      result = Evaluation::Runner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: '',
        baseline_output: 'output',
        context_output: 'output',
        judge_params: 'invalid'
      )

      assert result[:success]
    end

    private

    def stub_prompt_paths
      Judge::Prompt.stubs(:call).with { |args| args[:skill_context].nil? }
                                .returns({ success: true, response: { prompt: 'Baseline prompt' } })
      Judge::Prompt.stubs(:call).with { |args| args[:skill_context] == 'Skill context' }
                                .returns({ success: true, response: { prompt: 'Context prompt' } })
    end

    def run_with_distinct_outputs(criteria)
      Evaluation::Runner.call(
        task: 'Test task',
        criteria: criteria,
        skill_context: 'Skill context',
        baseline_output: 'Baseline diff',
        context_output: 'Context diff',
        judge_params: {}
      )
    end

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
      Judge::Response.new(json: '').tap do |jr|
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
