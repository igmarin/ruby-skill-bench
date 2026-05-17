# frozen_string_literal: true

require_relative 'formatting_helpers'

module SkillBench
  module Services
    # Formats the dimension scoring table, totals, trend, and verdict for a DeltaReport.
    class DeltaTableFormatter
      extend FormattingHelpers

      # Formats the delta report scoring section.
      #
      # @param report [SkillBench::DeltaReport] The delta report.
      # @param result [Hash, nil] Eval result envelope (used for trend data).
      # @return [String] Formatted table, totals, trend, and verdict.
      def self.format(report, result = nil)
        lines = [
          '  DIMENSION                BASELINE   CONTEXT    DELTA',
          '  ──────────────────────── ───────── ───────── ───────'
        ]

        report.deltas.each do |name, delta|
          lines << format_dimension_row(name, delta, report)
        end

        lines << '  ──────────────────────── ───────── ───────── ───────'
        lines << format_total_row(report)
        lines << ''
        trend = result[:trend] if result
        lines << format_trend(trend) if trend

        status = report.verdict ? 'PASS' : 'FAIL'
        criteria = report.criteria
        threshold = criteria.pass_threshold
        delta_threshold = criteria.minimum_delta
        lines << "  VERDICT: #{status} (threshold: #{threshold}, minimum delta: #{delta_threshold})"
        lines << ('═' * 55)

        lines.join("\n")
      end

      private_class_method def self.format_dimension_row(name, delta, report)
        dim = report.criteria.dimensions.find { |d| d.name == name }
        max_score = dim&.max_score || ''
        humanized = humanize(name)
        label = dim ? "#{humanized} (#{max_score})" : humanized
        baseline_score = report.baseline_scores[name]
        context_score = report.context_scores[name]
        Kernel.format('  %<label>-24s %<baseline>9s %<context>9s %<delta>7s',
                      label: label, baseline: baseline_score, context: context_score,
                      delta: delta_str(delta))
      end

      private_class_method def self.format_total_row(report)
        Kernel.format('  %<label>-24s %<baseline>9s %<context>9s %<delta>7s',
                      label: 'TOTAL', baseline: "#{report.baseline_total}/100",
                      context: "#{report.context_total}/100",
                      delta: delta_str(report.deltas.values.sum))
      end

      private_class_method def self.format_trend(trend)
        return nil unless trend

        baseline_icon = trend_icon(trend[:baseline_trend])
        context_icon = trend_icon(trend[:context_trend])
        baseline_delta = trend[:baseline_delta]
        context_delta = trend[:context_delta]
        "  TREND: baseline #{baseline_icon} (#{delta_str(baseline_delta)}), context #{context_icon} (#{delta_str(context_delta)})"
      end
    end
  end
end
