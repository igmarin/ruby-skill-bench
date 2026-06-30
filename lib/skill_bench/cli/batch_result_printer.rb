# frozen_string_literal: true

require_relative '../output_formatter'

module SkillBench
  module Cli
    # Prints the aggregate result of a batch `skill-bench run --all` command.
    class BatchResultPrinter
      # Prints the aggregate summary and returns the appropriate exit code.
      #
      # @param aggregate [Hash] Aggregate envelope from BatchRunnerService
      # @return [Integer] Exit code (0 when all pass, 1 when any fails)
      def self.call(aggregate)
        puts OutputFormatter.format_batch(aggregate)
        OutputFormatter.batch_exit_code(aggregate)
      end
    end
  end
end
