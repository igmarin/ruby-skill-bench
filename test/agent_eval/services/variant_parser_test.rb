# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class VariantParserTest < Minitest::Test
      def test_call_parses_pack_variant
        result = VariantParser.call('pack:rails')

        assert_equal :pack, result[:type]
        assert_equal 'rails', result[:name]
      end

      def test_call_parses_path_variant
        result = VariantParser.call('/path/to/skill')

        assert_equal :path, result[:type]
        assert_equal '/path/to/skill', result[:path]
      end

      def test_call_parses_path_with_colon
        result = VariantParser.call('/path/to:skill')

        assert_equal :path, result[:type]
        assert_equal '/path/to:skill', result[:path]
      end
    end
  end
end
