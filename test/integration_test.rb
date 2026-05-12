# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  class IntegrationTest < Minitest::Test
    def setup
      @original_dir = Dir.pwd
      @tmp_dir = Dir.mktmpdir('integration_test')
      Dir.chdir(@tmp_dir)

      FileUtils.mkdir_p('evals/integration-eval')
      File.write('evals/integration-eval/task.md', 'Create a simple Ruby service object')
      File.write('evals/integration-eval/criteria.json', valid_criteria_json)

      FileUtils.mkdir_p('skills/integration-skill')
      File.write('skills/integration-skill/SKILL.md', '# Service Object Pattern')

      File.write('skill-bench.json', JSON.generate({
                                                     provider: 'mock',
                                                     max_execution_time: 30,
                                                     config: {}
                                                   }))
    end

    def teardown
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@tmp_dir)
    end

    def test_full_eval_pipeline
      EvaluationRunner.expects(:call).with do |params|
        params[:task] == 'Create a simple Ruby service object' &&
          params[:skill_context].include?('Service Object Pattern') &&
          params[:baseline_output].is_a?(String) &&
          params[:context_output].is_a?(String) &&
          params.key?(:judge_params)
      end.returns({
                    success: true,
                    response: {
                      report: Struct.new(:verdict, :baseline_total, :context_total, :deltas, :criteria, keyword_init: true).new(
                        verdict: true,
                        baseline_total: 30,
                        context_total: 80,
                        deltas: { 'correctness' => 16, 'skill_adherence' => 17 },
                        criteria: build_criteria
                      )
                    }
                  })

      result = Services::RunnerService.call(
        eval_name: 'integration-eval',
        skill_names: ['integration-skill']
      )

      assert result[:success]
      report = result[:response][:report]

      assert report.verdict
      assert_equal 80, report.context_total
    end

    def test_full_pipeline_passes_judge_params_for_non_standard_provider
      File.write('skill-bench.json', JSON.generate({
                                                     provider: 'deepseek',
                                                     max_execution_time: 30,
                                                     config: { api_key: 'sk-test-key', model: 'deepseek-chat' }
                                                   }))

      # The agent uses deepseek client which will try to make a real HTTP call.
      # Stub the DeepSeek client class method to return a mock success response.
      SkillBench::Clients::Providers::DeepSeek.stubs(:call).returns(
        { success: true, result: 'agent output', usage: {}, response: { message: { content: 'agent output' } }, status: 'success' }
      )

      EvaluationRunner.expects(:call).with do |params|
        params[:task] == 'Create a simple Ruby service object' &&
          params[:skill_context].include?('Service Object Pattern') &&
          params[:baseline_output].is_a?(String) &&
          params[:context_output].is_a?(String) &&
          params.key?(:judge_params) &&
          params[:judge_params][:api_key] == 'sk-test-key' &&
          params[:judge_params][:model] == 'deepseek-chat' &&
          params[:judge_params][:provider] == :deepseek
      end.returns({
                    success: true,
                    response: {
                      report: Struct.new(:verdict, :baseline_total, :context_total, :deltas, :criteria, keyword_init: true).new(
                        verdict: true,
                        baseline_total: 30,
                        context_total: 80,
                        deltas: { 'correctness' => 16, 'skill_adherence' => 17 },
                        criteria: build_criteria
                      )
                    }
                  })

      result = Services::RunnerService.call(
        eval_name: 'integration-eval',
        skill_names: ['integration-skill']
      )

      assert result[:success]
      report = result[:response][:report]

      assert report.verdict
      assert_equal 80, report.context_total
    end

    private

    def valid_criteria_json
      {
        context: 'Evaluate service object skill',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def build_criteria
      dimensions = [
        Dimension.new(name: 'correctness', description: '', max_score: 30),
        Dimension.new(name: 'skill_adherence', description: '', max_score: 25)
      ]
      Criteria.new(path: '/dev/null').tap do |c|
        c.instance_variable_set(:@context, '')
        c.instance_variable_set(:@pass_threshold, 70)
        c.instance_variable_set(:@minimum_delta, 10)
        c.instance_variable_set(:@dimensions, dimensions)
      end
    end
  end
end
