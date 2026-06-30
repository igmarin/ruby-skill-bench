# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class AgentSpawnerServiceTest < Minitest::Test
      def setup
        @evaluation = Struct.new(:task, :path).new('Test task', '/path/to/eval')
        @system_prompt = 'You are an expert'
        @provider = Struct.new(:name, :runtime, :llm, :merged_config).new('mock', 'mock', 'mock', {})
        @config = {}
      end

      def test_call_returns_mock_result_for_mock_provider
        result = AgentSpawnerService.call(@evaluation, @system_prompt, @provider, @config)

        assert_equal :success, result[:status]
        assert_equal 'mock result', result[:result]
        assert_equal [], result[:iterations]
      end

      def test_call_returns_zero_usage_for_mock_provider
        result = AgentSpawnerService.call(@evaluation, @system_prompt, @provider, @config)

        assert_equal({ prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }, result[:usage])
      end

      def test_call_surfaces_aggregated_agent_usage_for_real_provider
        tmp = Dir.mktmpdir('agent_spawner_test')
        begin
          File.write(File.join(tmp, 'app.rb'), "# frozen_string_literal: true\n")
          evaluation = Struct.new(:task, :path).new('Test task', tmp)
          provider = Struct.new(:name, :runtime, :llm, :merged_config).new('openai', 'openai', 'gpt-4o', {})
          config = { api_key: 'fake-key', model: 'gpt-4o' }

          Agent::ReactAgent.stubs(:call).returns(
            {
              success: true,
              response: {
                content: 'done',
                iterations: [],
                usage: { prompt_tokens: 100, completion_tokens: 50, total_tokens: 150 }
              }
            }
          )
          Execution::Sandbox.stubs(:capture_diff).returns('No code changes made.')

          result = AgentSpawnerService.call(evaluation, @system_prompt, provider, config)

          assert_equal :success, result[:status]
          assert_equal({ prompt_tokens: 100, completion_tokens: 50, total_tokens: 150 }, result[:usage])
        ensure
          FileUtils.rm_rf(tmp)
        end
      end

      def test_call_returns_zero_usage_on_rescue
        evaluation = Struct.new(:task, :path).new('Test task', '/nonexistent/path/for/spawn')
        provider = Struct.new(:name, :runtime, :llm, :merged_config).new('openai', 'openai', 'gpt-4o', {})
        config = { api_key: 'fake-key', model: 'gpt-4o' }

        result = AgentSpawnerService.call(evaluation, @system_prompt, provider, config)

        assert_equal :error, result[:status]
        assert_equal({ prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }, result[:usage])
      end
    end
  end
end
