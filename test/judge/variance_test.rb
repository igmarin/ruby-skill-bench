# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Judge
    class VarianceTest < Minitest::Test
      def test_call_returns_mean_stddev_and_spread
        result = Variance.call(totals: [80, 86, 83])

        assert result[:success]
        stats = result[:response]

        assert_equal 3, stats[:n]
        assert_in_delta 83.0, stats[:mean], 0.001
        assert_in_delta 3.0, stats[:stddev], 0.001
        assert_in_delta 6.0, stats[:spread]
      end

      def test_call_returns_nils_when_fewer_than_two_totals
        result = Variance.call(totals: [80])

        assert result[:success]
        stats = result[:response]

        assert_equal 1, stats[:n]
        assert_nil stats[:mean]
        assert_nil stats[:stddev]
        assert_nil stats[:spread]
      end
    end
  end
end
