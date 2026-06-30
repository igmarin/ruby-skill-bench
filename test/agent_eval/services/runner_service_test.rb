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

        SkillBench::Evaluation::Runner.expects(:call).returns({
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

        SkillBench::Evaluation::Runner.expects(:call).returns({
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

        # Mock the evaluation runner to avoid real HTTP calls
        SkillBench::Evaluation::Runner.expects(:call).returns({
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

        # With the new error handling in ProviderResolver, missing config falls back to mock
        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        # Should use mock provider
        assert_equal 'mock', result[:provider_name]
        assert result[:success]
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

        SkillBench::Evaluation::Runner.expects(:call).returns({
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

        SkillBench::Evaluation::Runner.expects(:call).returns({
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

      def test_returns_error_when_skill_context_is_empty
        write_mock_config

        FileUtils.rm_rf(File.join(@skill_dir, 'SKILL.md'))
        File.write(File.join(@skill_dir, 'SKILL.md'), '')

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Skill context is empty'
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
      end

      def test_uses_context_hydrator_for_skill_bundle_xml_mode
        write_mock_config

        File.write(File.join(@eval_dir, 'metadata.json'), {
          'context_mode' => 'skill_bundle_xml'
        }.to_json)

        source_dir = File.join(@eval_dir, 'source')
        FileUtils.mkdir_p(source_dir)
        File.write(File.join(source_dir, 'app.rb'), '# frozen_string_literal: true')

        SkillBench::Execution::ContextHydrator.expects(:call).with do |args|
          args[:source_path] == 'evals/test-eval/source' && args[:base_path].is_a?(Pathname)
        end.returns({
                      success: true,
                      response: { context: '<agent_context><file path="app.rb">content</file></agent_context>' }
                    })

        SkillBench::Evaluation::Runner.expects(:call).returns({
                                                                success: true,
                                                                response: {
                                                                  report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                                                                     keyword_init: true).new(
                                                                                       verdict: true, baseline_total: 30, context_total: 80, deltas: {}
                                                                                     )
                                                                }
                                                              })

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        assert result[:success]
      end

      def test_falls_back_to_skill_md_when_source_dir_missing
        write_mock_config

        File.write(File.join(@eval_dir, 'metadata.json'), {
          'context_mode' => 'skill_bundle_xml'
        }.to_json)

        SkillBench::Execution::ContextHydrator.expects(:call).never

        SkillBench::Evaluation::Runner.expects(:call).returns({
                                                                success: true,
                                                                response: {
                                                                  report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                                                                     keyword_init: true).new(
                                                                                       verdict: true, baseline_total: 30, context_total: 80, deltas: {}
                                                                                     )
                                                                }
                                                              })

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        assert result[:success]
      end

      def test_call_returns_baseline_and_context_iterations
        write_openai_config
        stub_react_agent_with_iterations
        stub_trend_tracker

        SkillBench::Evaluation::Runner.expects(:call).returns({
                                                                success: true,
                                                                response: {
                                                                  report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                                                                     keyword_init: true).new(
                                                                                       verdict: true, baseline_total: 30, context_total: 80, deltas: {}
                                                                                     )
                                                                }
                                                              })

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        assert result[:success]
        assert result[:response][:baseline_iterations]
        assert result[:response][:context_iterations]
        assert_equal 2, result[:response][:baseline_iterations].length
        assert_equal 1, result[:response][:context_iterations].length

        first_baseline = result[:response][:baseline_iterations].first

        assert_equal 1, first_baseline[:step_number]
        assert_equal 'Read task', first_baseline[:thought]
        assert_equal %w[read_file], first_baseline[:tools_used]
      end

      def test_call_includes_diff_in_agent_output
        write_openai_config
        stub_react_agent_with_iterations
        stub_trend_tracker

        captured = { baseline: nil, context: nil }
        SkillBench::Evaluation::Runner.stubs(:call).with do |params|
          captured[:baseline] = params[:baseline_output]
          captured[:context] = params[:context_output]
          true
        end.returns({
                      success: true,
                      response: {
                        report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                           keyword_init: true).new(
                                             verdict: true, baseline_total: 30, context_total: 80, deltas: {}
                                           )
                      }
                    })

        RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        assert_includes captured[:baseline], 'Agent result'
        assert_includes captured[:baseline], '+added line'
        assert_includes captured[:context], 'Agent result'
      end

      def test_runs_baseline_and_context_with_distinct_outputs
        write_openai_config
        stub_trend_tracker

        Agent::ReactAgent.stubs(:call).with { |params| baseline_prompt?(params[:system_prompt]) }.returns(
          { success: true, response: { content: 'BASELINE ANSWER', iterations: [] } }
        )
        Agent::ReactAgent.stubs(:call).with { |params| !baseline_prompt?(params[:system_prompt]) }.returns(
          { success: true, response: { content: 'CONTEXT ANSWER', iterations: [] } }
        )
        Execution::Sandbox.stubs(:capture_diff).returns('No code changes made.')

        captured = { baseline: nil, context: nil }
        SkillBench::Evaluation::Runner.stubs(:call).with do |params|
          captured[:baseline] = params[:baseline_output]
          captured[:context] = params[:context_output]
          true
        end.returns({
                      success: true,
                      response: {
                        report: Struct.new(:verdict, :baseline_total, :context_total, :deltas,
                                           keyword_init: true).new(
                                             verdict: true, baseline_total: 30, context_total: 80, deltas: {}
                                           )
                      }
                    })

        result = RunnerService.call(
          eval_name: 'test-eval',
          skill_names: ['test-skill']
        )

        # Both runs must execute and stay correctly attributed; this fails if
        # either run is dropped or both collapse onto the same prompt path.
        assert result[:success]
        assert_includes captured[:baseline], 'BASELINE ANSWER'
        assert_includes captured[:context], 'CONTEXT ANSWER'
        refute_includes captured[:baseline], 'CONTEXT ANSWER'
        refute_includes captured[:context], 'BASELINE ANSWER'
      end

      private

      def stub_react_agent_with_iterations
        baseline_iterations = [
          { step_number: 1, thought: 'Read task', tools_used: %w[read_file], observation_summary: 'content' },
          { step_number: 2, thought: 'Done', tools_used: [], observation_summary: '' }
        ]
        context_iterations = [
          { step_number: 1, thought: 'Final', tools_used: [], observation_summary: '' }
        ]

        # The baseline and context runs execute concurrently, so invocation
        # order is non-deterministic. Key each stub on the system prompt
        # (only the baseline prompt mentions reading the task) instead of
        # relying on call order.
        Agent::ReactAgent.stubs(:call).with { |params| baseline_prompt?(params[:system_prompt]) }.returns(
          { success: true, response: { content: 'Agent result', iterations: baseline_iterations } }
        )
        Agent::ReactAgent.stubs(:call).with { |params| !baseline_prompt?(params[:system_prompt]) }.returns(
          { success: true, response: { content: 'Agent result', iterations: context_iterations } }
        )

        Execution::Sandbox.stubs(:capture_diff).returns('+added line')
      end

      def baseline_prompt?(system_prompt)
        system_prompt.to_s.include?('Your job is to read the task')
      end

      def stub_trend_tracker
        TrendTracker.any_instance.stubs(:trend_for).returns({})
        TrendTracker.any_instance.stubs(:record).returns({ success: true })
      end

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
