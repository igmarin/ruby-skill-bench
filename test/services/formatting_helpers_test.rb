# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class FormattingHelpersTest < Minitest::Test
      def test_humanize_converts_snake_case_to_title_case
        assert_equal 'Correctness', FormattingHelpers.humanize('correctness')
        assert_equal 'Skill Adherence', FormattingHelpers.humanize('skill_adherence')
      end

      def test_humanize_handles_symbols
        assert_equal 'Code Quality', FormattingHelpers.humanize(:code_quality)
      end

      def test_delta_str_positive_adds_plus_sign
        assert_equal '+5', FormattingHelpers.delta_str(5)
        assert_equal '+0', FormattingHelpers.delta_str(0)
      end

      def test_delta_str_negative_keeps_minus_sign
        assert_equal '-3', FormattingHelpers.delta_str(-3)
      end

      def test_truncate_leaves_short_text_untouched
        assert_equal 'hello', FormattingHelpers.truncate('hello', 10)
      end

      def test_truncate_long_text_adds_ellipsis
        text = 'a' * 100

        assert_equal "#{'a' * 60}...", FormattingHelpers.truncate(text, 60)
      end

      def test_truncate_at_exact_boundary
        assert_equal 'exactly', FormattingHelpers.truncate('exactly', 7)
      end

      def test_trend_icon_returns_unicode_arrows
        assert_equal '↑', FormattingHelpers.trend_icon(:improved)
        assert_equal '↓', FormattingHelpers.trend_icon(:regressed)
        assert_equal '→', FormattingHelpers.trend_icon(:unchanged)
      end

      def test_trend_icon_returns_question_mark_for_unknown
        assert_equal '?', FormattingHelpers.trend_icon(:unknown)
      end
    end
  end
end
