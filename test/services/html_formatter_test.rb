# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class HtmlFormatterTest < Minitest::Test
      def test_format_returns_complete_html_document
        output = HtmlFormatter.format(delta_result)

        assert output.start_with?('<!DOCTYPE html>'), 'should start with the HTML doctype'
        assert_includes output, '<html lang="en">'
        assert_includes output, '</html>'
      end

      def test_format_includes_eval_skill_provider_names
        output = HtmlFormatter.format(delta_result)

        assert_includes output, 'delta-eval'
        assert_includes output, 'test-skill'
        assert_includes output, 'mock'
      end

      def test_format_renders_tokens_and_cost
        output = HtmlFormatter.format(delta_result)

        assert_includes output, 'Tokens: 150'
        assert_includes output, 'Est. Cost: $0.0125'
      end

      def test_format_renders_dash_cost_when_unknown
        result = delta_result.merge(tokens: { total_tokens: 0 }, cost: nil)
        output = HtmlFormatter.format(result)

        assert_includes output, 'Est. Cost: —'
      end

      def test_format_renders_per_criterion_scores_and_deltas
        output = HtmlFormatter.format(delta_result)

        assert_includes output, '<table>'
        assert_includes output, 'Correctness (30)'
        assert_includes output, 'Skill Adherence (25)'
        assert_includes output, '<td>12</td>' # baseline correctness
        assert_includes output, '<td>28</td>' # context correctness
        assert_includes output, '<td>+16</td>' # correctness delta
        assert_includes output, '<td>+17</td>' # skill_adherence delta
      end

      def test_format_renders_totals_row
        output = HtmlFormatter.format(delta_result)

        assert_includes output, 'class="total"'
        assert_includes output, '17/100'
        assert_includes output, '50/100'
      end

      def test_format_renders_pass_verdict
        output = HtmlFormatter.format(delta_result(verdict: true))

        assert_includes output, 'class="verdict pass"'
        assert_includes output, 'Verdict: PASS'
      end

      def test_format_renders_fail_verdict
        output = HtmlFormatter.format(delta_result(verdict: false))

        assert_includes output, 'class="verdict fail"'
        assert_includes output, 'Verdict: FAIL'
      end

      def test_format_renders_iteration_timelines
        result = delta_result
        result[:response][:baseline_iterations] = [
          { step_number: 1, thought: 'Read file', tools_used: %w[read_file], observation_summary: 'content' }
        ]
        result[:response][:context_iterations] = [
          { step_number: 1, thought: 'Final answer', tools_used: [], observation_summary: '' }
        ]
        output = HtmlFormatter.format(result)

        assert_includes output, 'Iteration Timeline'
        assert_includes output, 'Baseline Iterations'
        assert_includes output, 'Step 1: Read file'
        assert_includes output, 'read_file'
        assert_includes output, 'Context Iterations'
        assert_includes output, 'Step 1: Final answer'
      end

      def test_format_omits_iterations_section_when_absent
        output = HtmlFormatter.format(delta_result)

        refute_includes output, 'Iteration Timeline'
      end

      def test_format_escapes_html_significant_characters_in_names
        result = delta_result(skill_name: 'a<b&c')
        output = HtmlFormatter.format(result)

        assert_includes output, 'a&lt;b&amp;c'
        refute_includes output, 'a<b&c'
      end

      def test_format_escapes_iteration_content
        result = delta_result
        result[:response][:baseline_iterations] = [
          { step_number: 1, thought: '<script>alert(1)</script>', tools_used: [], observation_summary: '' }
        ]
        output = HtmlFormatter.format(result)

        assert_includes output, '&lt;script&gt;alert(1)&lt;/script&gt;'
        refute_includes output, '<script>alert(1)</script>'
      end

      def test_format_legacy_result_produces_valid_html
        result = {
          eval_name: 'legacy-eval',
          skill_name: 'legacy-skill',
          provider_name: 'openai',
          pass: true,
          score: 0.875
        }
        output = HtmlFormatter.format(result)

        assert output.start_with?('<!DOCTYPE html>')
        assert_includes output, '</html>'
        assert_includes output, 'legacy-eval'
        assert_includes output, 'legacy-skill'
        assert_includes output, 'openai'
        assert_includes output, 'Status: PASSED'
        assert_includes output, 'Score: 0.88'
        refute_includes output, '<table>'
      end

      def test_format_legacy_failed_result_shows_error
        result = {
          eval_name: 'broken-eval',
          pass: false,
          response: { error: { message: 'connection refused & timed out' } }
        }
        output = HtmlFormatter.format(result)

        assert_includes output, 'Status: FAILED'
        assert_includes output, 'connection refused &amp; timed out'
        assert_includes output, 'Score: N/A'
      end

      private

      def delta_result(verdict: true, skill_name: 'test-skill')
        {
          success: true,
          eval_name: 'delta-eval',
          skill_name: skill_name,
          provider_name: 'mock',
          tokens: { prompt_tokens: 100, completion_tokens: 50, total_tokens: 150 },
          cost: 0.0125,
          response: { report: build_delta_report(verdict: verdict) }
        }
      end

      def build_delta_report(verdict:)
        dimensions = [
          Dimension.new(name: 'correctness', description: '', max_score: 30),
          Dimension.new(name: 'skill_adherence', description: '', max_score: 25)
        ]
        baseline = {
          'correctness' => { score: 12, max_score: 30, reasoning: '' },
          'skill_adherence' => { score: 5, max_score: 25, reasoning: '' }
        }
        context = {
          'correctness' => { score: 28, max_score: 30, reasoning: '' },
          'skill_adherence' => { score: 22, max_score: 25, reasoning: '' }
        }
        DeltaReport.new(baseline: baseline, context: context, criteria: build_criteria(dimensions)).tap do |report|
          report.instance_variable_set(:@baseline_total, 17)
          report.instance_variable_set(:@context_total, 50)
          report.instance_variable_set(:@baseline_scores, { 'correctness' => 12, 'skill_adherence' => 5 })
          report.instance_variable_set(:@context_scores, { 'correctness' => 28, 'skill_adherence' => 22 })
          report.instance_variable_set(:@deltas, { 'correctness' => 16, 'skill_adherence' => 17 })
          report.instance_variable_set(:@verdict, verdict)
        end
      end

      def build_criteria(dimensions)
        Criteria.new(path: '/dev/null').tap do |criteria|
          criteria.instance_variable_set(:@context, '')
          criteria.instance_variable_set(:@pass_threshold, 70)
          criteria.instance_variable_set(:@minimum_delta, 10)
          criteria.instance_variable_set(:@dimensions, dimensions)
        end
      end
    end
  end
end
