# frozen_string_literal: true

require_relative '../services/compare_option_parser'
require_relative '../services/variant_parser'
require_relative '../services/comparison_runner'
require_relative '../services/comparison_reporter'
require_relative '../services/exit_code_calculator'

module SkillBench
  module Cli
    # Handles the `skill-bench compare` command.
    # Runs the same eval with two skill variants and reports the comparison.
    class CompareCommand
      # Parses argv and executes the comparison.
      #
      # @param argv [Array<String>] Raw CLI arguments
      # @return [Integer] Exit code
      def self.call(argv)
        new(argv).call
      end

      # @param argv [Array<String>] Raw CLI arguments
      def initialize(argv)
        @argv = argv
      end

      # Parses options, runs both variants, and prints a comparison report.
      #
      # @return [Integer] Exit code (0 if both pass, 1 otherwise)
      def call
        options = Services::CompareOptionParser.call(@argv)

        skill_name = @argv.shift
        return error_missing_skill unless skill_name
        return error_missing_variant_a unless options[:variant_a]
        return error_missing_variant_b unless options[:variant_b]
        return error_missing_eval unless options[:eval]

        variant_a = Services::VariantParser.call(options[:variant_a])
        variant_b = Services::VariantParser.call(options[:variant_b])

        puts "--- Running Variant A: #{options[:variant_a]} ---"
        puts "--- Running Variant B: #{options[:variant_b]} ---"

        results = Services::ComparisonRunner.call(
          variant_a,
          variant_b,
          skill_name,
          options[:eval]
        )

        Services::ComparisonReporter.call(
          results[:result_a],
          results[:result_b],
          options[:variant_a],
          options[:variant_b]
        )

        Services::ExitCodeCalculator.call(results[:result_a], results[:result_b])
      rescue SkillBench::HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      private

      def error_missing_skill
        warn 'Error: skill name is required'
        warn 'Usage: skill-bench compare <skill-name> --variant-a <spec> --variant-b <spec> --eval <path>'
        1
      end

      def error_missing_variant_a
        warn 'Error: --variant-a is required'
        1
      end

      def error_missing_variant_b
        warn 'Error: --variant-b is required'
        1
      end

      def error_missing_eval
        warn 'Error: --eval is required'
        1
      end
    end
  end
end
