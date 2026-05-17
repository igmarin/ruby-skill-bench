# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class IterationFormatterTest < Minitest::Test
      def test_format_with_empty_iterations
        output = IterationFormatter.format('BASELINE ITERATIONS', [])

        assert_includes output, '=== BASELINE ITERATIONS ==='
        refute_includes output, 'Step'
      end

      def test_format_with_single_iteration
        iterations = [
          { step_number: 1, thought: 'Read file', tools_used: %w[read_file], observation_summary: 'content found' }
        ]
        output = IterationFormatter.format('BASELINE ITERATIONS', iterations)

        assert_includes output, '=== BASELINE ITERATIONS ==='
        assert_includes output, 'Step 1: Read file'
        assert_includes output, '→ Tool: read_file'
        assert_includes output, '→ Observation: content found'
      end

      def test_format_with_multiple_iterations
        iterations = [
          { step_number: 1, thought: 'Plan', tools_used: [], observation_summary: '' },
          { step_number: 2, thought: 'Edit', tools_used: %w[edit_file run_command], observation_summary: 'done' }
        ]
        output = IterationFormatter.format('CONTEXT ITERATIONS', iterations)

        lines = output.split("\n")

        assert_equal 3, lines.length
        assert_includes output, 'Step 1: Plan'
        refute_includes lines[1], '→ Tool:' # step 1 has no tools
        assert_includes output, 'Step 2: Edit'
        assert_includes output, '→ Tool: edit_file, run_command'
        assert_includes output, '→ Observation: done'
      end

      def test_format_truncates_long_observations
        long_obs = 'a' * 100
        iterations = [
          { step_number: 1, thought: 'Check', tools_used: [], observation_summary: long_obs }
        ]
        output = IterationFormatter.format('TEST', iterations)

        assert_includes output, '...'
        refute_includes output, 'a' * 65
      end

      def test_format_omits_tool_line_when_empty
        iterations = [
          { step_number: 1, thought: 'Think', tools_used: [], observation_summary: '' }
        ]
        output = IterationFormatter.format('TEST', iterations)

        refute_includes output, '→ Tool'
        refute_includes output, '→ Observation'
      end
    end
  end
end
