# frozen_string_literal: true

require_relative '../output_formatter'

module SkillBench
  module Cli
    # Prints the result of a `skill-bench run` command.
    class ResultPrinter
      # Prints the result and returns the appropriate exit code.
      #
      # @param result [Hash] Result from ScoringService
      # @param format [Symbol] Output format (:human, :json, :junit)
      # @return [Integer] Exit code (0 for pass, 1 for fail)
      def self.call(result, format: :human)
        puts OutputFormatter.format(result, format: format)
        OutputFormatter.exit_code(result)
      end
    end
  end
end
