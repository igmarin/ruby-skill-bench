# frozen_string_literal: true

module SkillBench
  module Services
    # Prints a formatted comparison report for two evaluation results.
    class ComparisonReporter
      # Prints the comparison report to stdout.
      #
      # @param result_a [Hash] First evaluation result
      # @param result_b [Hash] Second evaluation result
      # @param label_a [String] Label for first variant
      # @param label_b [String] Label for second variant
      # @return [nil]
      def self.call(result_a, result_b, label_a, label_b)
        new(result_a, result_b, label_a, label_b).call
      end

      # @param result_a [Hash] First evaluation result
      # @param result_b [Hash] Second evaluation result
      # @param label_a [String] Label for first variant
      # @param label_b [String] Label for second variant
      def initialize(result_a, result_b, label_a, label_b)
        @result_a = result_a
        @result_b = result_b
        @label_a = label_a
        @label_b = label_b
      end

      # Prints the comparison report to stdout.
      #
      # @return [nil]
      def call
        puts "\n=== Comparison Report ==="
        puts "| Dimension | #{@label_a} | #{@label_b} | Delta |"
        puts '|-----------|----------|----------|-------|'

        report_a = @result_a.dig(:response, :report)
        report_b = @result_b.dig(:response, :report)
        return unless report_a && report_b

        print_dimension_scores(report_a, report_b)
        print_total_scores(report_a, report_b)
        print_verdicts(report_a, report_b)
      end

      private

      # Prints dimension score comparison.
      #
      # @param report_a [Object] First evaluation report
      # @param report_b [Object] Second evaluation report
      def print_dimension_scores(report_a, report_b)
        report_b_by_name = report_b.dimensions.to_h { |d| [d.name, d] }

        report_a.dimensions.each do |dim|
          score_a = dim.score
          score_b = report_b_by_name[dim.name]&.score || 0
          delta = score_a - score_b
          puts format('| %<name>-9s | %<a>8.1f | %<b>8.1f | %<delta>+5.1f |',
                      name: dim.name, a: score_a, b: score_b, delta: delta.to_f)
        end
      end

      # Prints total score comparison.
      #
      # @param report_a [Object] First evaluation report
      # @param report_b [Object] Second evaluation report
      def print_total_scores(report_a, report_b)
        total_a = report_a.total
        total_b = report_b.total
        return unless total_a && total_b

        delta = total_a - total_b
        puts format('| %<name>-9s | %<a>8.1f | %<b>8.1f | %<delta>+5.1f |',
                    name: 'TOTAL', a: total_a.to_f, b: total_b.to_f, delta: delta.to_f)
      end

      # Prints verdict comparison.
      #
      # @param report_a [Object] First evaluation report
      # @param report_b [Object] Second evaluation report
      def print_verdicts(report_a, report_b)
        verdict_a = format_verdict(report_a.verdict)
        verdict_b = format_verdict(report_b.verdict)
        puts "| A: #{verdict_a} | B: #{verdict_b} |"
      end

      def format_verdict(verdict)
        case verdict
        when true then 'PASS'
        when false then 'FAIL'
        else verdict.to_s
        end
      end
    end
  end
end
