# frozen_string_literal: true

require 'cgi'

module SkillBench
  module Services
    # Formats evaluation results as JUnit XML for CI consumption.
    #
    # Two entry points share the same per-result verdict/score logic:
    # {.format} emits a single-result suite (one <testcase>), while
    # {.format_batch} aggregates many results into one suite so a batch
    # `skill-bench run --all` produces a single JUnit artifact.
    class JUnitFormatter
      # classname attribute applied to every emitted <testcase>.
      CLASSNAME = 'SkillBench'

      # Format a single result as a JUnit XML document.
      #
      # Supports both legacy format (result[:pass]) and modern DeltaReport format.
      #
      # @param result [Hash] Eval result.
      # @return [String] JUnit XML-formatted string.
      def self.format(result)
        suite([result])
      end

      # Format an aggregate batch envelope as one JUnit XML document.
      #
      # Emits a single <testsuite> with one <testcase> per result, adding a
      # <failure> child for every failing eval.
      #
      # @param aggregate [Hash] Aggregate envelope with a :results array.
      # @return [String] JUnit XML-formatted string.
      def self.format_batch(aggregate)
        suite(aggregate[:results] || [])
      end

      # Builds a <testsuite> wrapping one <testcase> per result.
      #
      # @param results [Array<Hash>] Per-eval result envelopes.
      # @return [String] JUnit XML-formatted string.
      def self.suite(results)
        failures = results.count { |result| !passing?(result) }
        cases = results.map { |result| testcase(result) }.join("\n")
        <<~XML
          <?xml version="1.0"?>
          <testsuite name="#{CLASSNAME}" tests="#{results.size}" failures="#{failures}">
          #{cases}
          </testsuite>
        XML
      end
      private_class_method :suite

      # Renders one <testcase> element (indented two spaces) for a result.
      #
      # @param result [Hash] A single-eval result envelope.
      # @return [String] A <testcase> XML fragment.
      def self.testcase(result)
        name = CGI.escapeHTML(result[:eval_name].to_s)
        return %(  <testcase name="#{name}" classname="#{CLASSNAME}"/>) if passing?(result)

        score = CGI.escapeHTML(score_for(result).to_s)
        [
          %(  <testcase name="#{name}" classname="#{CLASSNAME}">),
          %(    <failure message="Score: #{score}">Eval failed</failure>),
          '  </testcase>'
        ].join("\n")
      end
      private_class_method :testcase

      # Whether a result passed (DeltaReport verdict or legacy :pass).
      #
      # @param result [Hash] A single-eval result envelope.
      # @return [Boolean] true when the eval passed.
      def self.passing?(result)
        report = result.dig(:response, :report)
        report.respond_to?(:verdict) ? report.verdict : result[:pass]
      end
      private_class_method :passing?

      # The score reported for a failing eval.
      #
      # @param result [Hash] A single-eval result envelope.
      # @return [Object] DeltaReport context_total or legacy :score.
      def self.score_for(result)
        report = result.dig(:response, :report)
        report.respond_to?(:context_total) ? report.context_total : result[:score]
      end
      private_class_method :score_for
    end
  end
end
