# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ComparisonReporterTest < Minitest::Test
      def setup
        @report_a = Struct.new(:dimensions, :total, :verdict).new(
          [
            Struct.new(:name, :score).new('correctness', 80.0),
            Struct.new(:name, :score).new('style', 70.0)
          ],
          75.0,
          'PASS'
        )
        @report_b = Struct.new(:dimensions, :total, :verdict).new(
          [
            Struct.new(:name, :score).new('correctness', 85.0),
            Struct.new(:name, :score).new('style', 65.0)
          ],
          75.0,
          'PASS'
        )
        @result_a = { response: { report: @report_a } }
        @result_b = { response: { report: @report_b } }
        @stdout_orig = $stdout
        $stdout = StringIO.new
      end

      def teardown
        $stdout = @stdout_orig
      end

      def test_call_prints_comparison_report
        ComparisonReporter.call(@result_a, @result_b, 'pack:rails', 'pack:hanami')

        output = $stdout.string

        assert_includes output, '=== Comparison Report ==='
        assert_includes output, 'pack:rails'
        assert_includes output, 'pack:hanami'
        assert_includes output, 'correctness'
        assert_includes output, 'style'
        assert_includes output, 'TOTAL'
        assert_includes output, 'A: PASS'
        assert_includes output, 'B: PASS'
      end

      def test_call_returns_early_when_reports_missing
        result_a = { response: {} }
        result_b = { response: {} }

        ComparisonReporter.call(result_a, result_b, 'A', 'B')

        output = $stdout.string

        assert_includes output, '=== Comparison Report ==='
        refute_includes output, 'correctness'
      end

      def test_call_handles_missing_dimension_in_result_b
        report_b = Struct.new(:dimensions, :total, :verdict).new(
          [
            Struct.new(:name, :score).new('correctness', 85.0)
          ],
          85.0,
          'PASS'
        )
        result_b = { response: { report: report_b } }

        ComparisonReporter.call(@result_a, result_b, 'A', 'B')

        output = $stdout.string

        assert_includes output, 'style' # Should show 0 for missing dimension
      end

      def test_call_handles_missing_total
        report_a = Struct.new(:dimensions, :total, :verdict).new(
          [Struct.new(:name, :score).new('correctness', 80.0)],
          nil,
          'PASS'
        )
        report_b = Struct.new(:dimensions, :total, :verdict).new(
          [Struct.new(:name, :score).new('correctness', 85.0)],
          nil,
          'PASS'
        )
        result_a = { response: { report: report_a } }
        result_b = { response: { report: report_b } }

        ComparisonReporter.call(result_a, result_b, 'A', 'B')

        output = $stdout.string

        refute_includes output, 'TOTAL'
      end
    end
  end
end
