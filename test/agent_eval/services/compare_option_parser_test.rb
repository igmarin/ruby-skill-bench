# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class CompareOptionParserTest < Minitest::Test
      def test_call_parses_variant_a
        result = CompareOptionParser.call(['--variant-a', 'pack:rails'])

        assert_equal 'pack:rails', result[:variant_a]
      end

      def test_call_parses_variant_b
        result = CompareOptionParser.call(['--variant-b', 'pack:hanami'])

        assert_equal 'pack:hanami', result[:variant_b]
      end

      def test_call_parses_eval
        result = CompareOptionParser.call(['--eval', 'evals/test'])

        assert_equal 'evals/test', result[:eval]
      end

      def test_call_parses_format
        result = CompareOptionParser.call(['--format', 'json'])

        assert_equal :json, result[:format]
      end

      def test_call_defaults_format_to_human
        result = CompareOptionParser.call([])

        assert_equal :human, result[:format]
      end

      def test_call_raises_help_requested
        assert_raises(SkillBench::HelpRequested) do
          CompareOptionParser.call(['-h'])
        end
      end
    end
  end
end
