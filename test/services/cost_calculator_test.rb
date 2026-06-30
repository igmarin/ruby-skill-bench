# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class CostCalculatorTest < Minitest::Test
      def test_computes_cost_for_known_model
        usage = { prompt_tokens: 1000, completion_tokens: 2000, total_tokens: 3000 }

        cost = CostCalculator.call(usage: usage, model: 'gpt-4o')

        # 1K input * $0.005 + 2K output * $0.015 = 0.005 + 0.030
        assert_in_delta 0.035, cost, 1e-6
      end

      def test_computes_cost_for_anthropic_model
        usage = { prompt_tokens: 1000, completion_tokens: 1000, total_tokens: 2000 }

        cost = CostCalculator.call(usage: usage, model: 'claude-3-5-sonnet')

        # 1K input * $0.003 + 1K output * $0.015 = 0.018
        assert_in_delta 0.018, cost, 1e-6
      end

      def test_matches_dated_model_variant_by_prefix
        usage = { prompt_tokens: 1000, completion_tokens: 0, total_tokens: 1000 }

        cost = CostCalculator.call(usage: usage, model: 'claude-3-5-sonnet-20241022')

        assert_in_delta 0.003, cost, 1e-6
      end

      def test_prices_claude_4_default_models
        usage = { prompt_tokens: 1000, completion_tokens: 1000, total_tokens: 2000 }

        # Defaults the codebase actually passes in (config/defaults.rb,
        # clients/provider_schemas.rb) must resolve, not fall through to nil.
        sonnet_cost = CostCalculator.call(usage: usage, model: 'claude-sonnet-4-20250514')
        opus_cost = CostCalculator.call(usage: usage, model: 'claude-opus-4-7')

        # claude-sonnet-4: 1K * $0.003 + 1K * $0.015 = 0.018
        assert_in_delta 0.018, sonnet_cost, 1e-6
        # claude-opus-4: 1K * $0.015 + 1K * $0.075 = 0.090
        assert_in_delta 0.090, opus_cost, 1e-6
      end

      def test_prefers_longest_matching_prefix
        usage = { prompt_tokens: 1000, completion_tokens: 0, total_tokens: 1000 }

        cost = CostCalculator.call(usage: usage, model: 'gpt-4o-mini-2024-07-18')

        # Must resolve to gpt-4o-mini ($0.00015), not gpt-4o ($0.005).
        assert_in_delta 0.00015, cost, 1e-8
      end

      def test_returns_nil_for_unknown_model
        usage = { prompt_tokens: 1000, completion_tokens: 1000, total_tokens: 2000 }

        assert_nil CostCalculator.call(usage: usage, model: 'mock')
      end

      def test_returns_nil_for_nil_model
        assert_nil CostCalculator.call(usage: { prompt_tokens: 10 }, model: nil)
      end

      def test_handles_empty_usage_as_zero
        cost = CostCalculator.call(usage: {}, model: 'gpt-4o')

        assert_in_delta 0.0, cost, 1e-9
      end

      def test_handles_nil_usage_without_crashing
        cost = CostCalculator.call(usage: nil, model: 'gpt-4o')

        assert_in_delta 0.0, cost, 1e-9
      end

      def test_tolerates_string_usage_keys
        usage = { 'prompt_tokens' => 1000, 'completion_tokens' => 0 }

        cost = CostCalculator.call(usage: usage, model: 'gpt-4o')

        assert_in_delta 0.005, cost, 1e-6
      end
    end
  end
end
