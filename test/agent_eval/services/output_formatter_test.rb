# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class OutputFormatterTest < Minitest::Test
      def test_call_returns_result_as_string
        agent_result = { result: 'Agent output' }
        result = OutputFormatter.call(agent_result)

        assert_equal 'Agent output', result
      end

      def test_call_converts_nil_to_string
        agent_result = { result: nil }
        result = OutputFormatter.call(agent_result)

        assert_equal '', result
      end

      def test_call_converts_number_to_string
        agent_result = { result: 123 }
        result = OutputFormatter.call(agent_result)

        assert_equal '123', result
      end

      def test_call_preserves_string_result
        input = "Multi-line\noutput"
        agent_result = { result: input }
        result = OutputFormatter.call(agent_result)

        assert_equal input, result
      end
    end
  end
end
