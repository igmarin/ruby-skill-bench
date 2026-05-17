# frozen_string_literal: true

require 'cgi'

module SkillBench
  module Services
    # Formats evaluation results as JUnit XML.
    class JUnitFormatter
      # Format result as JUnit XML.
      #
      # Supports both legacy format (result[:pass]) and modern DeltaReport format.
      #
      # @param result [Hash] Eval result.
      # @return [String] JUnit XML-formatted string.
      def self.format(result)
        report = result.dig(:response, :report)
        verdict = report.respond_to?(:verdict) ? report.verdict : result[:pass]
        eval_name = CGI.escapeHTML(result[:eval_name].to_s)

        if verdict
          <<~XML
            <?xml version="1.0"?>
            <testsuite name="SkillBench" tests="1" failures="0">
              <testcase name="#{eval_name}" classname="SkillBench"/>
            </testsuite>
          XML
        else
          score = report.respond_to?(:context_total) ? report.context_total : result[:score]
          escaped_score = CGI.escapeHTML(score.to_s)
          <<~XML
            <?xml version="1.0"?>
            <testsuite name="SkillBench" tests="1" failures="1">
              <testcase name="#{eval_name}" classname="SkillBench">
                <failure message="Score: #{escaped_score}">Eval failed</failure>
              </testcase>
            </testsuite>
          XML
        end
      end
    end
  end
end
