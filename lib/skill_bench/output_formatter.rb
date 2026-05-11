# frozen_string_literal: true

require 'json'
require 'cgi'

module SkillBench
  # Handles formatting output for different use cases (human, CI, etc.)
  class OutputFormatter
    # Format the eval result for output
    # @param result [Hash] Eval result with keys like :eval_name, :pass, :score, etc.
    # @param format [Symbol] Output format (:human, :json, :junit)
    # @return [String] Formatted output string
    def self.format(result, format: :human)
      case format
      when :json
        format_json(result)
      when :junit
        format_junit(result)
      else
        format_human(result)
      end
    end

    # Determine exit code based on eval result.
    #
    # @param result [Hash] Eval result with :pass or :success/:response keys.
    # @return [Integer] 0 if passed, 1 if failed
    def self.exit_code(result)
      return 0 if result[:pass]
      return 1 unless result[:success]

      report = result.dig(:response, :report)
      report&.verdict ? 0 : 1
    end

    # Format result as human-readable text.
    #
    # @param result [Hash] Eval result in old or new format.
    # @return [String] Human-readable formatted string.
    def self.format_human(result)
      report = result.dig(:response, :report)
      return format_legacy_human(result) unless delta_report?(report)

      format_delta_report(result, report)
    end
    private_class_method :format_human

    # Checks whether a report object is a DeltaReport.
    #
    # @param report [Object] The report to inspect.
    # @return [Boolean] true when the report has DeltaReport attributes.
    def self.delta_report?(report)
      report.respond_to?(:deltas) && report.respond_to?(:criteria) &&
        report.respond_to?(:baseline_scores) && report.respond_to?(:context_scores)
    end
    private_class_method :delta_report?

    # Formats a legacy result hash.
    #
    # @param result [Hash] Legacy eval result.
    # @return [String] Human-readable formatted string.
    def self.format_legacy_human(result)
      status = result[:pass] ? 'PASSED' : 'FAILED'
      lines = [
        '=' * 60,
        "Eval: #{result[:eval_name] || ''}",
        "Skill: #{result[:skill_name] || ''}",
        "Provider: #{result[:provider_name] || ''}",
        "Status: #{status}",
        "Score: #{result[:score]&.round(2) || 'N/A'}"
      ]
      error_msg = result.dig(:response, :error, :message)
      lines << "Error: #{error_msg}" if error_msg
      lines << ('=' * 60)
      lines.join("\n")
    end
    private_class_method :format_legacy_human

    # Formats a DeltaReport as a human-readable table.
    #
    # @param result [Hash] Eval result envelope.
    # @param report [SkillBench::DeltaReport] The delta report.
    # @return [String] Formatted table string.
    def self.format_delta_report(result, report)
      lines = [
        ('═' * 55),
        "  Eval: #{result[:eval_name] || ''}",
        "  Skill: #{result[:skill_name] || ''}",
        "  Provider: #{result[:provider_name] || ''}",
        ('═' * 55),
        ''
      ]

      lines << '  DIMENSION                BASELINE   CONTEXT    DELTA'
      lines << '  ──────────────────────── ───────── ───────── ───────'

      report.deltas.each do |name, delta|
        lines << format_dimension_row(name, delta, report)
      end

      lines << '  ──────────────────────── ───────── ───────── ───────'
      lines << format_total_row(report)
      lines << ''
      lines << format_trend(result[:trend]) if result[:trend]

      status = report.verdict ? 'PASS' : 'FAIL'
      threshold = report.criteria.pass_threshold
      delta = report.criteria.minimum_delta
      lines << "  VERDICT: #{status} (threshold: #{threshold}, minimum delta: #{delta})"
      lines << ('═' * 55)

      lines.join("\n")
    end
    private_class_method :format_delta_report

    # Formats a single dimension row for the delta report table.
    #
    # @param name [String] The dimension name.
    # @param delta [Numeric] The delta value.
    # @param report [SkillBench::DeltaReport] The delta report.
    # @return [String] Formatted row string.
    def self.format_dimension_row(name, delta, report)
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
    private_class_method :format_dimension_row

    # Formats the total row for the delta report table.
    #
    # @param report [SkillBench::DeltaReport] The delta report.
    # @return [String] Formatted total row string.
    def self.format_total_row(report)
      Kernel.format('  %<label>-24s %<baseline>9s %<context>9s %<delta>7s',
                    label: 'TOTAL', baseline: "#{report.baseline_total}/100",
                    context: "#{report.context_total}/100",
                    delta: delta_str(report.deltas.values.sum))
    end
    private_class_method :format_total_row

    # Formats a numeric delta with a +/- sign.
    #
    # @param delta [Numeric] The delta value.
    # @return [String] Formatted delta string.
    def self.delta_str(delta)
      delta >= 0 ? "+#{delta}" : delta.to_s
    end
    private_class_method :delta_str

    # Formats the trend line for display.
    #
    # @param trend [Hash] Trend data with :baseline_trend, :context_trend, :baseline_delta, :context_delta.
    # @return [String, nil] Formatted trend line or nil.
    def self.format_trend(trend)
      return nil unless trend

      baseline_icon = trend_icon(trend[:baseline_trend])
      context_icon = trend_icon(trend[:context_trend])
      baseline_delta = trend[:baseline_delta]
      context_delta = trend[:context_delta]
      "  TREND: baseline #{baseline_icon} (#{delta_str(baseline_delta)}), context #{context_icon} (#{delta_str(context_delta)})"
    end
    private_class_method :format_trend

    # Returns the Unicode arrow icon for a trend direction.
    #
    # @param direction [Symbol] :improved, :regressed, or :unchanged.
    # @return [String] Arrow icon.
    def self.trend_icon(direction)
      { improved: '↑', regressed: '↓', unchanged: '→' }.fetch(direction, '?')
    end
    private_class_method :trend_icon

    # Converts a snake_case name to Title Case.
    #
    # @param name [String] The dimension name.
    # @return [String] Human-readable name.
    def self.humanize(name)
      name.to_s.split('_').map(&:capitalize).join(' ')
    end
    private_class_method :humanize

    # Format result as JSON
    # @param result [Hash] Eval result
    # @return [String] JSON-formatted string
    def self.format_json(result)
      JSON.pretty_generate(result)
    end
    private_class_method :format_json

    # Format result as JUnit XML
    # @param result [Hash] Eval result
    # @return [String] JUnit XML-formatted string
    def self.format_junit(result)
      status = result[:pass] ? 'passed' : 'failed'
      eval_name = CGI.escapeHTML(result[:eval_name].to_s)
      score = CGI.escapeHTML(result[:score].to_s)
      failure_xml = result[:pass] ? '' : "<failure message=\"Score: #{score}\">Eval #{status}</failure>"
      <<~XML
        <?xml version="1.0"?>
        <testsuite name="SkillBench" tests="1" failures="#{result[:pass] ? 0 : 1}">
          <testcase name="#{eval_name}" classname="SkillBench">
            #{failure_xml}
          </testcase>
        </testsuite>
      XML
    end
    private_class_method :format_junit
  end
end
