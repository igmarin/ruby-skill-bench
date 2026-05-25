# frozen_string_literal: true

require_relative '../execution/sandbox'
require_relative '../agent/react_agent'

module SkillBench
  module Services
    # Spawns and executes LLM agents for evaluation.
    class AgentSpawnerService
      # Spawns the LLM agent with the given system prompt.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param system_prompt [String] The system prompt for the agent
      # @param provider [Object] The resolved provider
      # @param config [Hash, nil] Provider config
      # @return [Hash] Agent response with result, status, runtime, usage, raw_response, iterations
      def self.call(evaluation, system_prompt, provider, config)
        new(evaluation, system_prompt, provider, config).call
      end

      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param system_prompt [String] The system prompt for the agent
      # @param provider [Object] The resolved provider
      # @param config [Hash, nil] Provider config
      def initialize(evaluation, system_prompt, provider, config)
        @evaluation = evaluation
        @system_prompt = system_prompt
        @provider = provider
        @config = config
      end

      # Spawns the LLM agent with the given system prompt.
      #
      # @return [Hash] Agent response with result, status, runtime, usage, raw_response, iterations
      def call
        return { result: 'mock result', status: :success, iterations: [] } if @provider.name == 'mock'

        client_params = build_client_params
        max_iterations = @config&.[](:max_iterations) || @config&.[]('max_iterations') || 25

        Execution::Sandbox.run(@evaluation.path) do |sandbox|
          agent_result = Agent::ReactAgent.call(
            system_prompt: @system_prompt,
            initial_prompt: @evaluation.task,
            working_dir: sandbox.path,
            container_id: sandbox.container_id,
            client_params: client_params,
            max_iterations: max_iterations
          )

          status = agent_result[:success] ? :success : :error
          final_answer = agent_result.dig(:response, :content) || ''
          diff = Execution::Sandbox.capture_diff(sandbox.path)
          iterations = agent_result.dig(:response, :iterations) || []

          output = [final_answer, diff].reject(&:empty?).join("\n\n")

          {
            result: output,
            status: status,
            runtime: @provider.runtime,
            usage: {},
            raw_response: agent_result,
            iterations: iterations
          }
        end
      end

      private

      # Builds client parameters for the ReactAgent.
      #
      # @return [Hash] Client parameters
      def build_client_params
        config = @config || safe_merged_config
        return {} unless config

        params = config.dup
        params[:model] ||= @provider.llm
        params[:provider] = @provider.runtime.to_sym
        params
      rescue StandardError
        {}
      end

      # Safely calls merged_config, returning nil on any error.
      #
      # @return [Hash, nil] The merged config or nil
      def safe_merged_config
        @provider.merged_config
      rescue StandardError
        nil
      end
    end
  end
end
