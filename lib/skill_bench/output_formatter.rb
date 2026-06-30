# frozen_string_literal: true

require_relative 'services/iteration_formatter'
require_relative 'services/delta_table_formatter'
require_relative 'services/feedback_generator'
require_relative 'services/json_formatter'
require_relative 'services/junit_formatter'

module SkillBench
  # Handles formatting output for different use cases (human, CI, etc.).
  # Delegates all presentation logic to focused service objects under
  # {SkillBench::Services}.
  class OutputFormatter
    # Format the eval result for output.
    #
    # @param result [Hash] Eval result with keys like :eval_name, :pass, :score, etc.
    # @param format [Symbol] Output format (:human, :json, :junit)
    # @return [String] Formatted output string
    def self.format(result, format: :human)
      case format
      when :json
        Services::JsonFormatter.format(result)
      when :junit
        Services::JUnitFormatter.format(result)
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

    # Format an aggregate batch result for human output.
    #
    # Renders one PASS/FAIL line per eval plus a final summary line.
    #
    # @param aggregate [Hash] Aggregate envelope with :results and :summary.
    # @return [String] Human-readable batch summary.
    def self.format_batch(aggregate)
      lines = aggregate[:results].map { |result| batch_result_line(result) }
      lines << ''
      lines << batch_summary_line(aggregate[:summary])
      lines.join("\n")
    end

    # Determine the exit code for an aggregate batch result.
    #
    # @param aggregate [Hash] Aggregate envelope with a :summary.
    # @return [Integer] 0 when every eval passed, 1 when any failed.
    def self.batch_exit_code(aggregate)
      aggregate.dig(:summary, :failed).to_i.positive? ? 1 : 0
    end

    # Builds a single PASS/FAIL line for one eval result.
    #
    # @param result [Hash] A single-eval result envelope.
    # @return [String] A formatted verdict line.
    def self.batch_result_line(result)
      status = exit_code(result).zero? ? 'PASS' : 'FAIL'
      line = "#{status}  #{result[:eval_name]}"
      error = result.dig(:response, :error, :message)
      error ? "#{line} — #{error}" : line
    end
    private_class_method :batch_result_line

    # Builds the trailing summary line for a batch run.
    #
    # @param summary [Hash] Summary with :passed, :failed and :total counts.
    # @return [String] A formatted summary line.
    def self.batch_summary_line(summary)
      "Summary: #{summary[:passed]} passed / #{summary[:failed]} failed (#{summary[:total]} total)"
    end
    private_class_method :batch_summary_line

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

    # Formats a DeltaReport as a human-readable report.
    #
    # @param result [Hash] Eval result envelope.
    # @param report [SkillBench::DeltaReport] The delta report.
    # @return [String] Formatted report string.
    def self.format_delta_report(result, report)
      lines = [
        ('═' * 55),
        "  Eval: #{result[:eval_name] || ''}",
        "  Skill: #{result[:skill_name] || ''}",
        "  Provider: #{result[:provider_name] || ''}",
        build_usage_line(result),
        ('═' * 55),
        ''
      ]

      lines.concat(build_iteration_lines(result))
      lines << Services::DeltaTableFormatter.format(report, result)

      feedback_result = Services::FeedbackGenerator.call(report)
      if feedback_result[:success]
        output = feedback_result.dig(:response, :output)
        lines << output unless output.empty?
      end

      lines.join("\n")
    end
    private_class_method :format_delta_report

    # Builds the token/cost summary line for the report header.
    #
    # @param result [Hash] Eval result envelope; reads :tokens and :cost.
    # @return [String] A formatted "Tokens / Est. Cost" line.
    def self.build_usage_line(result)
      tokens = result[:tokens] || {}
      total = tokens[:total_tokens] || tokens['total_tokens'] || 0
      cost = result[:cost]
      cost_label = cost ? Kernel.format('$%.4f', cost) : '—'
      "  Tokens: #{total}  |  Est. Cost: #{cost_label}"
    end
    private_class_method :build_usage_line

    # Builds iteration timeline lines from the result response.
    #
    # @param result [Hash] Eval result envelope.
    # @return [Array<String>] Lines to append, or empty array.
    def self.build_iteration_lines(result)
      baseline = result.dig(:response, :baseline_iterations) || []
      context = result.dig(:response, :context_iterations) || []
      baseline_empty = baseline.empty?
      context_empty = context.empty?
      lines = []

      lines << Services::IterationFormatter.format('BASELINE ITERATIONS', baseline) unless baseline_empty
      lines << Services::IterationFormatter.format('CONTEXT ITERATIONS', context) unless context_empty
      lines << '' unless baseline_empty && context_empty

      lines
    end
    private_class_method :build_iteration_lines
  end
end
