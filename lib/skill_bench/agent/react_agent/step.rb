# frozen_string_literal: true

require_relative '../../client'
require_relative 'tool_executor'

module SkillBench
  module Agent
    class ReactAgent
      # Service object responsible for executing a single step of the ReAct loop.
      class Step
        # Executes one iteration of reasoning and potential tool usage.
        #
        # @param messages [Array<Hash>] The conversation history.
        # @param config [Hash] Configuration for this step (client params, system prompt, working dir).
        # @return [Hash] Step outcome containing :continue (boolean), :result (hash, if finished),
        #   :usage (token usage for this step), and :messages.
        def self.call(messages, config)
          messages = messages.dup
          client_result = Client.call(
            system_prompt: config[:system_prompt],
            messages: messages,
            tools: Tools.definitions,
            **config[:client_params]
          )
          usage = client_result[:usage] || {}

          unless client_result[:success]
            error_msg = client_result.dig(:response, :error, :message) || 'Unknown error'
            return {
              continue: false,
              result: client_result,
              usage: usage,
              iteration: build_iteration(thought: '', tools_used: [], observation_summary: error_msg)
            }
          end

          response_msg = client_result.dig(:response, :message)
          unless response_msg
            return {
              continue: false,
              result: { success: false, response: { error: { message: 'Empty response from LLM' } } },
              usage: usage,
              iteration: build_iteration(thought: '', tools_used: [], observation_summary: 'Empty response from LLM')
            }
          end

          messages << response_msg

          tool_calls = response_msg['tool_calls']
          content = response_msg['content']
          tool_calls_array = Array(tool_calls)
          thought = content.to_s

          if tool_calls_array.empty?
            return {
              continue: false,
              result: { success: true, response: { content: content } },
              usage: usage,
              iteration: build_iteration(thought: thought, tools_used: [], observation_summary: '')
            }
          end

          if thought.strip.length.positive?
            warn "\n=== Agent Thought ==="
            warn content
          end

          tool_results = ToolExecutor.call(tool_calls, config[:working_dir], config[:container_id])
          messages.concat(tool_results)

          tools_used = tool_calls_array.map { |tc| tc.dig('function', 'name') }.compact
          observation_summary = Array(tool_results).map { |tr| tr[:content] || tr['content'] }.compact.join(', ')

          {
            continue: true,
            messages: messages,
            usage: usage,
            iteration: build_iteration(thought: thought, tools_used: tools_used, observation_summary: observation_summary)
          }
        end

        # Builds an iteration metadata hash.
        #
        # @param thought [String] The agent's reasoning for this step.
        # @param tools_used [Array<String>] Names of tools invoked.
        # @param observation_summary [String] Summary of tool results.
        # @return [Hash] Iteration metadata.
        def self.build_iteration(thought:, tools_used:, observation_summary:)
          {
            thought: thought,
            tools_used: tools_used,
            observation_summary: observation_summary
          }
        end
      end
    end
  end
end
