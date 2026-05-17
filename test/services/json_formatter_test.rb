# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class JsonFormatterTest < Minitest::Test
      def test_format_returns_pretty_json
        result = { eval_name: 'test-eval', pass: true, score: 1.0 }
        output = JsonFormatter.format(result)

        parsed = JSON.parse(output)

        assert_equal 'test-eval', parsed['eval_name']
        assert parsed['pass']
        assert_in_delta(1.0, parsed['score'])
      end

      def test_format_preserves_nested_structures
        result = { response: { report: { verdict: true } } }
        output = JsonFormatter.format(result)

        parsed = JSON.parse(output)

        assert parsed['response']['report']['verdict']
      end

      def test_format_is_pretty_printed
        result = { a: 1 }
        output = JsonFormatter.format(result)

        assert_includes output, "{\n"
        assert_includes output, '  "a": 1'
        assert_includes output, '}'
      end
    end
  end
end
