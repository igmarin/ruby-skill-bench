# frozen_string_literal: true

require_relative '../output_formatter'
require_relative '../services/summary_formatter'

module SkillBench
  module Cli
    # Prints the aggregate result of a batch `skill-bench run --all` command.
    #
    # Defaults to the human-readable batch summary, but can instead emit a
    # JUnit document (`format: :junit`) or a JSON gate (`summary: true`). The
    # returned exit code is always {OutputFormatter.batch_exit_code}, so CI
    # gating works identically across every output mode.
    class BatchResultPrinter
      # Prints the aggregate summary and returns the appropriate exit code.
      #
      # @param aggregate [Hash] Aggregate envelope from BatchRunnerService.
      # @param format [Symbol, nil] Output format (:junit for JUnit XML, else human).
      # @param summary [Boolean] When true, print the JSON summary gate instead.
      # @return [Integer] Exit code (0 when all pass, 1 when any fails).
      def self.call(aggregate, format: nil, summary: false)
        puts batch_output(aggregate, format: format, summary: summary)
        OutputFormatter.batch_exit_code(aggregate)
      end

      # Selects the rendered batch output for the requested mode.
      #
      # @param aggregate [Hash] Aggregate envelope from BatchRunnerService.
      # @param format [Symbol, nil] Output format (:junit for JUnit XML, else human).
      # @param summary [Boolean] When true, render the JSON summary gate.
      # @return [String] The formatted batch output.
      def self.batch_output(aggregate, format:, summary:)
        return Services::SummaryFormatter.format(aggregate) if summary
        return Services::JUnitFormatter.format_batch(aggregate) if format == :junit

        OutputFormatter.format_batch(aggregate)
      end
      private_class_method :batch_output
    end
  end
end
