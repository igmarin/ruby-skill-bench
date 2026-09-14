# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class HelpPrinterTest < Minitest::Test
      def test_call_prints_usage
        assert_output(/Usage: skill-bench/) do
          HelpPrinter.call
        end
      end

      def test_call_returns_zero
        assert_equal 0, HelpPrinter.call
      end

      def test_call_lists_all_subcommands
        assert_output(/init.*run.*skill.*eval/m) do
          HelpPrinter.call
        end
      end

      def test_call_includes_format_flag
        assert_output(/--format/) do
          HelpPrinter.call
        end
      end

      def test_call_includes_eval_generate_subcommand
        assert_output(/eval generate/) do
          HelpPrinter.call
        end
      end

      def test_call_notes_multi_skill_support
        assert_output(/can be specified multiple times/) do
          HelpPrinter.call
        end
      end

      def test_call_includes_cache_flag
        assert_output(/--cache/) do
          HelpPrinter.call
        end
      end

      def test_call_includes_mock_provider
        assert_output(/--mock/) do
          HelpPrinter.call
        end
      end
    end
  end
end
