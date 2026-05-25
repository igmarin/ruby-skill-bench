# frozen_string_literal: true

module SkillBench
  module Services
    # Formats agent output for evaluation.
    class OutputFormatter
      # Formats agent output for evaluation.
      #
      # @param agent_result [Hash] The agent result containing the output
      # @return [String] The formatted output
      def self.call(agent_result)
        new(agent_result).call
      end

      # @param agent_result [Hash] The agent result containing the output
      def initialize(agent_result)
        @agent_result = agent_result
      end

      # Formats agent output for evaluation.
      #
      # @return [String] The formatted output
      def call
        @agent_result[:result].to_s
      end
    end
  end
end
