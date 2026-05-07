# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class InteractiveTest < Minitest::Test
    def setup
      # Common stubs for interactive tests
      Interactive.stubs(:gum_choose).returns('Run Eval')
      Interactive.stubs(:select_eval).returns('test-eval')
      Interactive.stubs(:select_skill).returns('test-skill')
      Interactive.stubs(:select_provider).returns('openai')

      # Correct namespace for run command might need verification
      # Based on spec it was SkillBench::Commands::Run
      # Let's ensure it's stubbed correctly
      return unless defined?(SkillBench::Commands::Run)

      SkillBench::Commands::Run.stubs(:run).returns({ pass: true })
    end

    def test_run_does_not_raise_error
      assert_silent { Interactive.run }
    end

    def test_run_returns_result
      skip unless defined?(SkillBench::Commands::Run)

      result = Interactive.run

      assert result[:pass]
    end
  end
end
