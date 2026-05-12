# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Services
    class RunnerServiceTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @original_env = ENV.to_h
        ENV.delete('SKILL_BENCH_OPENAI_API_KEY')
        ENV.delete('OPENAI_API_KEY')

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
        ENV.clear
        ENV.update(@original_env)
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
          skill_names: ['test-skill']
        )

        assert result[:success]
        assert result[:response][:report].verdict
      end

      def test_success_result_includes_metadata
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
          skill_names: ['test-skill']
        )

        assert result[:success]
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_call_raises_when_eval_not_found
        write_mock_config

        assert_raises(Errno::ENOENT) do
          RunnerService.call(
            eval_name: 'nonexistent',
            skill_names: ['test-skill']
          )
        end
      end

      def test_call_raises_when_skill_not_found
        write_mock_config

        assert_raises(ArgumentError) do
          RunnerService.call(
            eval_name: 'test-eval',
            skill_names: ['nonexistent']
          )
        end
      end

      def test_call_raises_when_config_not_found
        Models::Config.instance_variable_set(:@loaded, nil)

        assert_raises(Errno::ENOENT) do
          RunnerService.call(
            eval_name: 'test-eval',
            skill_names: ['test-skill']
          )
        end
      end

      def test_call_returns_config_error_when_api_key_missing
        write_openai_config_without_key

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        refute result[:success]
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_includes result[:response][:error][:message], 'API key not found'
      end

      def test_call_returns_error_result_with_metadata_on_agent_failure
        write_openai_config

        SkillBench::Clients::ProviderRegistry.stubs(:for).returns(FakeFailingClient)

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        refute result[:success]
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_includes result[:response][:error][:message], 'Baseline'
      end

      def test_call_enriches_evaluation_runner_error_with_metadata
        write_mock_config

        SkillBench::EvaluationRunner.expects(:call).returns({
                                                              success: false,
                                                              response: { error: { message: 'Judge error' } }
                                                            })

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        refute result[:success]
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
        assert_includes result[:response][:error][:message], 'Judge error'
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
          skill_names: ['test-skill']
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

      def write_openai_config
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.generate({
                                                                        provider: 'openai',
                                                                        max_execution_time: 30,
                                                                        config: { api_key: 'fake-key' }
                                                                      }))
      end

      def write_openai_config_without_key
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.generate({
                                                                        provider: 'openai',
                                                                        max_execution_time: 30,
                                                                        config: { api_key: nil }
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

    class FakeFailingClient
      def self.call(**_kwargs)
        {
          success: false,
          response: { error: { message: 'connection refused' } },
          result: nil,
          usage: {}
        }
      end
    end
  end
end
