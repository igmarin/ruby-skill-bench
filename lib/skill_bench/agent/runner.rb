# frozen_string_literal: true

require_relative '../execution/sandbox'
require_relative '../execution/context_hydrator'
require_relative 'react_agent'

module SkillBench
  module Agent
    # Responsible for executing a specific scenario (baseline or context-hydrated)
    # within an isolated sandbox. Handles the system prompt generation and agent execution.
    class Runner
      # Executes the agent run scenario.
      #
      # @param params [Hash] The configuration parameters for the run.
      # @option params [Symbol] :mode The mode to run in (`:baseline` or `:context`).
      # @option params [Pathname] :full_eval_path The path to the evaluation directory.
      # @option params [String] :task_content The task description.
      # @option params [Hash] :client_params Parameters for the LLM client.
      # @option params [String] :source_path Required if mode is `:context`.
      # @option params [Pathname] :base_path Required if mode is `:context`.
      # @return [Array<String, String>] The agent's final answer and the git diff.
      def self.call(params)
        new(params).call
      end

      # @param params [Hash] The configuration parameters for the run.
      def initialize(params)
        @mode = validate_mode(params.fetch(:mode))
        @full_eval_path = params.fetch(:full_eval_path)
        @task_content = params.fetch(:task_content)
        @client_params = params.fetch(:client_params, {})

        @source_path = params[:source_path]
        @base_path = params[:base_path]
      end

      # Runs the evaluation scenario and captures the results.
      #
      # @return [Array<String, String>] A tuple containing the final answer and the diff.
      def call
        Execution::Sandbox.run(@full_eval_path) do |sandbox|
          working_dir = sandbox.path
          agent_result = ReactAgent.call(
            client_params: @client_params,
            working_dir: working_dir,
            container_id: sandbox.container_id,
            system_prompt: build_system_prompt,
            initial_prompt: @task_content
          )

          response = agent_result[:response]
          final_answer = if agent_result[:success]
                           response&.dig(:content) || 'Error: Empty response from agent'
                         else
                           error_msg = response&.dig(:error, :message) || 'Unknown error'
                           "Error: #{error_msg}"
                         end
          [final_answer, Execution::Sandbox.capture_diff(working_dir)]
        end
      end

      private

      # Builds the appropriate system prompt based on the execution mode.
      #
      # @return [String] The system prompt for the agent.
      # @raise [RuntimeError] when context hydration fails in :context mode.
      def build_system_prompt
        case @mode
        when :baseline
          baseline_system_prompt
        when :context
          context_system_prompt
        end
      end

      def baseline_system_prompt
        <<~PROMPT
          You are an expert Ruby on Rails developer.#{' '}
          Your job is to read the task, modify the codebase using the tools provided to meet the requirements, and then explain what you did.
        PROMPT
      end

      def context_system_prompt
        hydrator_result = Execution::ContextHydrator.call(source_path: @source_path, base_path: @base_path)
        raise "Context hydration failed: #{hydrator_result.dig(:response, :error, :message)}" unless hydrator_result[:success]

        context_xml = hydrator_result[:response][:context]

        <<~PROMPT
          You are an expert Ruby on Rails developer.
          You have access to specific skill files wrapped in <agent_context> tags.
          Use these skills exactly as instructed to solve the user's task.
          Modify the codebase using the tools provided to meet the requirements, and then explain what you did.

          #{context_xml}
        PROMPT
      end

      def validate_mode(mode)
        allowed = %i[baseline context]
        return mode if allowed.include?(mode)

        raise ArgumentError, "Invalid mode: #{mode.inspect}. Allowed: #{allowed.join(', ')}"
      end
    end
  end
end
