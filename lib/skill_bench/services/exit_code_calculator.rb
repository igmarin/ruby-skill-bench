# frozen_string_literal: true

module SkillBench
  module Services
    # Calculates the exit code based on comparison results.
    class ExitCodeCalculator
      # Calculates the exit code from comparison results.
      #
      # @param result_a [Hash] First evaluation result
      # @param result_b [Hash] Second evaluation result
      # @return [Integer] 0 if both pass, 1 otherwise
      def self.call(result_a, result_b)
        new(result_a, result_b).call
      end

      # @param result_a [Hash] First evaluation result
      # @param result_b [Hash] Second evaluation result
      def initialize(result_a, result_b)
        @result_a = result_a
        @result_b = result_b
      end

      # Calculates the exit code from comparison results.
      #
      # @return [Integer] 0 if both pass, 1 otherwise
      def call
        passed_a = @result_a.dig(:response, :report, :verdict) == 'PASS'
        passed_b = @result_b.dig(:response, :report, :verdict) == 'PASS'
        passed_a && passed_b ? 0 : 1
      end
    end
  end
end
