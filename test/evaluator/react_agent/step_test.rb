# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class ReactAgent
    class StepTest < Minitest::Test
      def setup
        @config = {
          system_prompt: 'System',
          client_params: {},
          working_dir: Dir.pwd
        }
        @messages = [{ role: 'user', content: 'Initial' }]
      end

      def test_call_passes_provider_from_client_params
        config = @config.merge(client_params: { provider: :deepseek, api_key: 'test' })

        Client.expects(:call).with(
          system_prompt: 'System',
          messages: [{ role: 'user', content: 'Initial' }],
          tools: Tools.definitions,
          provider: :deepseek,
          api_key: 'test'
        ).returns(
          { success: true, response: { message: { 'content' => 'ok', 'tool_calls' => [] } } }
        )

        Agent::ReactAgent::Step.call(@messages, config)
      end

      def test_call_returns_continue_false_on_client_failure
        Client.expects(:call).returns({ success: false, response: { error: { message: 'API Error' } } })

        result = Agent::ReactAgent::Step.call(@messages, @config)

        refute result[:continue]
        refute result[:result][:success]
        assert_equal 'API Error', result[:result][:response][:error][:message]
      end

      def test_call_returns_continue_false_when_no_tool_calls
        Client.expects(:call).returns(
          { success: true, response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } } }
        )

        result = Agent::ReactAgent::Step.call(@messages, @config)

        refute result[:continue]
        assert result[:result][:success]
        assert_equal 'Final Answer', result[:result][:response][:content]
      end

      def test_call_returns_continue_true_and_executes_tools
        Client.expects(:call).returns(
          {
            success: true,
            response: {
              message: {
                'content' => 'Thinking...',
                'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"a"}' } }]
              }
            }
          }
        )

        Agent::ReactAgent::ToolExecutor.expects(:call).returns([{ role: 'tool', tool_call_id: 'call_1', content: 'result' }])

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert result[:continue]
        assert_equal 3, result[:messages].length # user, assistant, tool
        assert_equal 'tool', result[:messages].last[:role]
        assert_equal 'result', result[:messages].last[:content]
      end

      def test_call_returns_iteration_metadata_when_no_tool_calls
        Client.expects(:call).returns(
          { success: true, response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } } }
        )

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert result[:iteration]
        assert_equal 'Final Answer', result[:iteration][:thought]
        assert_equal [], result[:iteration][:tools_used]
        assert_equal '', result[:iteration][:observation_summary]
      end

      def test_call_returns_iteration_metadata_with_tools
        Client.expects(:call).returns(
          {
            success: true,
            response: {
              message: {
                'content' => 'Let me check...',
                'tool_calls' => [
                  { 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"a"}' } },
                  { 'id' => 'call_2', 'function' => { 'name' => 'run_command', 'arguments' => '{"command":"ls"}' } }
                ]
              }
            }
          }
        )

        Agent::ReactAgent::ToolExecutor.expects(:call).returns([
                                                                 { role: 'tool', tool_call_id: 'call_1', content: 'file_a_content' },
                                                                 { role: 'tool', tool_call_id: 'call_2', content: 'file_list' }
                                                               ])

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert result[:iteration]
        assert_equal 'Let me check...', result[:iteration][:thought]
        assert_equal %w[read_file run_command], result[:iteration][:tools_used]
        assert_equal 'file_a_content, file_list', result[:iteration][:observation_summary]
      end

      def test_call_returns_iteration_metadata_on_client_failure
        Client.expects(:call).returns({ success: false, response: { error: { message: 'API Error' } } })

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert result[:iteration]
        assert_equal '', result[:iteration][:thought]
        assert_equal [], result[:iteration][:tools_used]
        assert_equal 'API Error', result[:iteration][:observation_summary]
      end

      def test_call_includes_usage_on_finish
        Client.expects(:call).returns(
          {
            success: true,
            usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 },
            response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } }
          }
        )

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert_equal({ prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 }, result[:usage])
      end

      def test_call_includes_usage_when_executing_tools
        Client.expects(:call).returns(
          {
            success: true,
            usage: { prompt_tokens: 7, completion_tokens: 3, total_tokens: 10 },
            response: {
              message: {
                'content' => 'Thinking...',
                'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"a"}' } }]
              }
            }
          }
        )

        Agent::ReactAgent::ToolExecutor.expects(:call).returns([{ role: 'tool', tool_call_id: 'call_1', content: 'result' }])

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert result[:continue]
        assert_equal({ prompt_tokens: 7, completion_tokens: 3, total_tokens: 10 }, result[:usage])
      end

      def test_call_usage_defaults_to_empty_hash_when_client_omits_it
        Client.expects(:call).returns(
          { success: true, response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } } }
        )

        result = Agent::ReactAgent::Step.call(@messages, @config)

        assert_equal({}, result[:usage])
      end
    end
  end
end
