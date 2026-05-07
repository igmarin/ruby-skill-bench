# frozen_string_literal: true

require 'json'
require 'cgi'

module AgentEval
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

    # Determine exit code based on eval result
    # @param result [Hash] Eval result with :pass key
    # @return [Integer] 0 if passed, 1 if failed
    def self.exit_code(result)
      result[:pass] ? 0 : 1
    end

    # Format result as human-readable text
    # @param result [Hash] Eval result
    # @return [String] Human-readable formatted string
    def self.format_human(result)
      status = result[:pass] ? 'PASSED' : 'FAILED'
      lines = [
        '=' * 60,
        "Eval: #{result[:eval_name]}",
        "Skill: #{result[:skill_name]}",
        "Provider: #{result[:provider_name]}",
        "Status: #{status}",
        "Score: #{result[:score]&.round(2) || 'N/A'}",
        '=' * 60
      ]
      lines.join("\n")
    end
    private_class_method :format_human

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
        <testsuite name="AgentEval" tests="1" failures="#{result[:pass] ? 0 : 1}">
          <testcase name="#{eval_name}" classname="AgentEval">
            #{failure_xml}
          </testcase>
        </testsuite>
      XML
    end
    private_class_method :format_junit
  end
end
