# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Judge
    class GoldenTraceTest < Minitest::Test
      FIXTURE = File.expand_path('../fixtures/judge_traces/canonical.json', __dir__)

      def test_canonical_trace_parses_to_expected_scores
        json = File.read(FIXTURE)
        result = Response.call(json: json)

        assert result[:success], "parse failed: #{result.dig(:response, :error, :message)}"
        response = result[:response][:judge_response]
        dims = response.dimensions

        assert_equal 24, dims['correctness'][:score]
        assert_equal 20, dims['skill_adherence'][:score]
        assert_equal 16, dims['code_quality'][:score]
        assert_equal 12, dims['test_coverage'][:score]
        assert_equal 8, dims['documentation'][:score]
        total = dims.each_value.sum { |dim| dim[:score] }

        assert_equal 80, total
      end
    end
  end
end
