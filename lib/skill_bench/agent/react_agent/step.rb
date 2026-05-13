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
        # @return [Hash] Step outcome containing :continue (boolean), :result (hash, if finished), and :messages.
        def self.call(messages, config)
          messages = messages.dup
          client_result = Client.call(
            system_prompt: config[:system_prompt],
            messages: messages,
            tools: Tools.definitions,
            **config[:client_params]
          )

          return { continue: false, result: client_result } unless client_result[:success]

          response_msg = client_result.dig(:response, :message)
          return { continue: false, result: { success: false, response: { error: { message: 'Empty response from LLM' } } } } unless response_msg

          messages << response_msg

          tool_calls = response_msg['tool_calls']
          content = response_msg['content']

          return { continue: false, result: { success: true, response: { content: content } } } if Array(tool_calls).empty?

          if content.to_s.strip.length.positive?
            warn "\n=== Agent Thought ==="
            warn content
          end

          messages.concat(ToolExecutor.call(tool_calls, config[:working_dir], config[:container_id]))

          { continue: true, messages: messages }
        end
      end
    end
  end
end
