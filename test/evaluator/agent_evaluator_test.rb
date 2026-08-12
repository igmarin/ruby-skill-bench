# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class AgentEvaluatorTest < Minitest::Test
    def test_module_is_defined
      assert(defined?(SkillBench))
      assert_kind_of Module, SkillBench
    end

    def test_version_is_accessible
      assert(defined?(SkillBench::VERSION))
      assert_match(/\A\d+\.\d+\.\d+\z/, SkillBench::VERSION)
      assert_equal '1.3.1', SkillBench::VERSION
    end

    def test_module_is_already_loaded?
      assert(defined?(SkillBench))
    end
  end
end
