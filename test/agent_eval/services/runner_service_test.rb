# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Services
    class RunnerServiceTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('runner_service_test')
        @eval_dir = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(@eval_dir)
        File.write(File.join(@eval_dir, 'task.md'), 'Test task')
        File.write(File.join(@eval_dir, 'criteria.json'), valid_criteria_json)

        @skill_dir = File.join(@tmp_dir, 'skills', 'test-skill')
        FileUtils.mkpath(@skill_dir)
        File.write(File.join(@skill_dir, 'SKILL.md'), 'Test skill')

        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_returns_result_for_mock_provider
        write_mock_config

        SkillBench::EvaluationRunner.expects(:call).returns({
                                                              success: true,
                                                              response: {
                                                                report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                                                                   keyword_init: true).new(
                                                                                     verdict: true,
                                                                                     baseline_total: 30,
                                                                                     context_total: 80,
                                                                                     deltas: { 'correctness' => 16 }
                                                                                   )
                                                              }
                                                            })

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_name: 'test-skill'
        )

        assert result[:success]
        assert result[:response][:report].verdict
      end

      def test_call_raises_when_eval_not_found
        write_mock_config

        assert_raises(Errno::ENOENT) do
          RunnerService.call(
            eval_name: 'nonexistent',
            skill_name: 'test-skill'
          )
        end
      end

      def test_call_raises_when_skill_not_found
        write_mock_config

        assert_raises(ArgumentError) do
          RunnerService.call(
            eval_name: 'test-eval',
            skill_name: 'nonexistent'
          )
        end
      end

      def test_call_raises_when_config_not_found
        Models::Config.instance_variable_set(:@loaded, nil)

        assert_raises(Errno::ENOENT) do
          RunnerService.call(
            eval_name: 'test-eval',
            skill_name: 'test-skill'
          )
        end
      end

      def test_call_resolves_eval_with_full_path
        write_mock_config

        SkillBench::EvaluationRunner.expects(:call).returns({
                                                              success: true,
                                                              response: {
                                                                report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                                                                   keyword_init: true).new(
                                                                                     verdict: true, baseline_total: 30, context_total: 80, deltas: {}
                                                                                   )
                                                              }
                                                            })

        result = RunnerService.call(
          eval_name: 'evals/test-eval',
          skill_name: 'test-skill'
        )

        assert result[:success]
      end

      private

      def write_mock_config
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.generate({
                                                                        provider: 'mock',
                                                                        max_execution_time: 30,
                                                                        config: {}
                                                                      }))
      end

      def valid_criteria_json
        {
          context: 'Evaluate test',
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
    end
  end
end
