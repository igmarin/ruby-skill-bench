# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class LoopRunnerTest < Minitest::Test
    def test_call_returns_success_when_agent_completes
      # Arrange
      Client.expects(:call).returns(
        { success: true, response: { message: { 'content' => 'Final Answer' } } }
      )

      # Act
      result = Agent::ReactAgent::LoopRunner.call('Initial', 10, { client_params: {} })

      # Assert
      assert result[:success]
      assert_equal 'Final Answer', result[:response][:content]
    end

    def test_call_executes_tools_and_loops
      # Arrange
      Client.expects(:call).twice.returns(
        {
          success: true,
          response: {
            message: {
              'content' => 'Thinking...',
              'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'run_command', 'arguments' => '{"command":"echo 1"}' } }]
            }
          }
        }
      ).then.returns(
        { success: true, response: { message: { 'content' => 'Final Answer after tool' } } }
      )

      Tools.expects(:execute).with('run_command', '{"command":"echo 1"}', anything, nil).returns('Tool Result')

      # Act
      result = Agent::ReactAgent::LoopRunner.call('Initial', 10, { working_dir: Dir.pwd, client_params: {} })

      # Assert
      assert result[:success]
      assert_equal 'Final Answer after tool', result[:response][:content]
    end

    def test_call_returns_error_on_max_iterations
      # Arrange
      Client.stubs(:call).returns(
        {
          success: true,
          response: {
            message: {
              'content' => 'Thinking...',
              'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'run_command', 'arguments' => '{"command":"echo 1"}' } }]
            }
          }
        }
      )

      Tools.stubs(:execute).returns('Tool Result')

      # Act
      result = Agent::ReactAgent::LoopRunner.call('Initial', 2, { working_dir: Dir.pwd, client_params: {} })

      # Assert
      refute result[:success]
      assert_match(/Reached max iterations/, result[:response][:error][:message])
    end

    def test_call_returns_iterations_in_response
      # Arrange
      Client.expects(:call).twice.returns(
        {
          success: true,
          response: {
            message: {
              'content' => 'Step 1 thought',
              'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"a"}' } }]
            }
          }
        }
      ).then.returns(
        { success: true, response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } } }
      )

      Agent::ReactAgent::ToolExecutor.expects(:call).returns([{ role: 'tool', tool_call_id: 'call_1', content: 'file content' }])

      # Act
      result = Agent::ReactAgent::LoopRunner.call('Initial', 10, { working_dir: Dir.pwd, client_params: {} })

      # Assert structure
      assert result[:success]
      assert result[:response][:iterations]
      assert_equal 2, result[:response][:iterations].length
    end

    def test_call_iteration_fields_are_populated
      Client.expects(:call).twice.returns(
        {
          success: true,
          response: {
            message: {
              'content' => 'Step 1 thought',
              'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'read_file', 'arguments' => '{"path":"a"}' } }]
            }
          }
        }
      ).then.returns(
        { success: true, response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } } }
      )

      Agent::ReactAgent::ToolExecutor.expects(:call).returns([{ role: 'tool', tool_call_id: 'call_1', content: 'file content' }])

      result = Agent::ReactAgent::LoopRunner.call('Initial', 10, { working_dir: Dir.pwd, client_params: {} })
      iterations = result[:response][:iterations]

      first = iterations.first

      assert_equal 1, first[:step_number]
      assert_equal 'Step 1 thought', first[:thought]
      assert_equal %w[read_file], first[:tools_used]
      assert_equal 'file content', first[:observation_summary]

      last = iterations.last

      assert_equal 2, last[:step_number]
      assert_equal 'Final Answer', last[:thought]
      assert_equal [], last[:tools_used]
      assert_equal '', last[:observation_summary]
    end

    def test_call_returns_iterations_on_max_iterations_error
      Client.stubs(:call).returns(
        {
          success: true,
          response: {
            message: {
              'content' => 'Thinking...',
              'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'run_command', 'arguments' => '{"command":"echo 1"}' } }]
            }
          }
        }
      )

      Tools.stubs(:execute).returns('Tool Result')

      result = Agent::ReactAgent::LoopRunner.call('Initial', 2, { working_dir: Dir.pwd, client_params: {} })

      refute result[:success]
      assert result[:response][:iterations]
      assert_equal 2, result[:response][:iterations].length
    end

    def test_call_accumulates_usage_across_iterations
      Client.expects(:call).twice.returns(
        {
          success: true,
          usage: { prompt_tokens: 10, completion_tokens: 4, total_tokens: 14 },
          response: {
            message: {
              'content' => 'Thinking...',
              'tool_calls' => [{ 'id' => 'call_1', 'function' => { 'name' => 'run_command', 'arguments' => '{"command":"echo 1"}' } }]
            }
          }
        }
      ).then.returns(
        {
          success: true,
          usage: { prompt_tokens: 6, completion_tokens: 2, total_tokens: 8 },
          response: { message: { 'content' => 'Final Answer', 'tool_calls' => [] } }
        }
      )

      Tools.stubs(:execute).returns('Tool Result')

      result = Agent::ReactAgent::LoopRunner.call('Initial', 10, { working_dir: Dir.pwd, client_params: {} })
      usage = result[:response][:usage]

      assert_equal 16, usage[:prompt_tokens]
      assert_equal 6, usage[:completion_tokens]
      assert_equal 22, usage[:total_tokens]
    end

    def test_call_usage_defaults_to_zero_without_client_usage
      Client.expects(:call).returns(
        { success: true, response: { message: { 'content' => 'Final Answer' } } }
      )

      result = Agent::ReactAgent::LoopRunner.call('Initial', 10, { client_params: {} })

      assert_equal({ prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }, result[:response][:usage])
    end
  end
end
