# frozen_string_literal: true

require_relative '../../tools'

module SkillBench
  module Agent
    class ReactAgent
      # Service object responsible for executing a list of tool calls and returning the results
      # formatted as messages to be appended to the conversation history.
      class ToolExecutor
        # Executes the provided tool calls.
        #
        # @param tool_calls [Array<Hash>] The tool calls requested by the LLM.
        # @param working_dir [String] The directory where tools should operate.
        # @param container_id [String, nil] The Docker container ID for isolated execution.
        # @return [Array<Hash>] An array of message hashes containing tool results.
        def self.call(tool_calls, working_dir, container_id = nil)
          tool_calls.map do |tool_call|
            function_name = tool_call.dig('function', 'name')
            next tool_error_message(tool_call, 'Missing function name') unless function_name

            warn "=== Calling Tool: #{function_name} ===" unless defined?(Minitest)

            result = execute_tool(tool_call, working_dir, container_id)
            if result.is_a?(Hash) && result[:role] == 'tool'
              result
            else
              error_msg = result.dig(:response, :error, :message) || 'Unknown tool error'
              tool_error_message(tool_call, error_msg)
            end
          end
        end

        # Executes a single tool call and returns the result message.
        #
        # @param tool_call [Hash] The tool call hash.
        # @param working_dir [String] The directory where tools should operate.
        # @param container_id [String, nil] The Docker container ID.
        # @return [Hash] Tool result message or error hash.
        def self.execute_tool(tool_call, working_dir, container_id)
          function_name = tool_call.dig('function', 'name')
          arguments = tool_call.dig('function', 'arguments')

          result = Tools.execute(function_name, arguments, working_dir, container_id)

          {
            role: 'tool',
            tool_call_id: tool_call['id'],
            content: result
          }
        rescue StandardError => e
          SkillBench::ErrorLogger.log_error(e, "Tool execution failed: #{function_name}")
          tool_error_result(tool_call, e.message)
        end

        # Builds a tool error message for the conversation history.
        #
        # @param tool_call [Hash] The tool call hash.
        # @param message [String] The error message.
        # @return [Hash] Tool message with error content.
        def self.tool_error_message(tool_call, message)
          {
            role: 'tool',
            tool_call_id: tool_call['id'],
            content: "Error: #{message}"
          }
        end

        # Builds an error result for a failed tool call.
        #
        # @param tool_call [Hash] The tool call hash.
        # @param message [String] The error message.
        # @return [Hash] Error result hash.
        def self.tool_error_result(tool_call, message)
          {
            success: false,
            response: {
              error: {
                message: "Tool call failed: #{message}",
                tool_call: tool_call
              }
            }
          }
        end
      end
    end
  end
end
