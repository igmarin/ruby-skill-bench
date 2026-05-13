# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class JudgePromptTest < Minitest::Test
    def test_builds_prompt_with_all_sections
      criteria = build_criteria
      result = Judge::Prompt.call(
        task: 'Create a REST API',
        criteria: criteria,
        skill_context: '<agent_context><file path="skill.md">Skill content</file></agent_context>',
        agent_output: 'git diff output'
      )

      assert result[:success]
      prompt = result[:response][:prompt]

      assert_match(/Create a REST API/, prompt)
      assert_match(/correctness/, prompt)
      assert_match(/Skill content/, prompt)
      assert_match(/git diff output/, prompt)
    end

    def test_returns_error_when_task_missing
      criteria = build_criteria
      result = Judge::Prompt.call(
        task: '',
        criteria: criteria,
        skill_context: 'context',
        agent_output: 'output'
      )

      refute result[:success]
      assert_match(/task.*required/i, result[:response][:error][:message])
    end

    def test_returns_error_when_criteria_missing
      result = Judge::Prompt.call(
        task: 'Create API',
        criteria: nil,
        skill_context: 'context',
        agent_output: 'output'
      )

      refute result[:success]
      assert_match(/criteria.*required/i, result[:response][:error][:message])
    end

    def test_returns_error_when_agent_output_nil
      criteria = build_criteria
      result = Judge::Prompt.call(
        task: 'Create API',
        criteria: criteria,
        skill_context: 'context',
        agent_output: nil
      )

      refute result[:success]
      assert_match(/agent output.*required/i, result[:response][:error][:message])
    end

    def test_accepts_nil_skill_context_for_baseline_runs
      criteria = build_criteria
      result = Judge::Prompt.call(
        task: 'Create API',
        criteria: criteria,
        skill_context: nil,
        agent_output: 'output'
      )

      assert result[:success]
      refute_match(/skill context.*required/i, result[:response][:prompt])
    end

    def test_returns_error_when_skill_context_empty_string
      criteria = build_criteria
      result = Judge::Prompt.call(
        task: 'Create API',
        criteria: criteria,
        skill_context: '',
        agent_output: 'output'
      )

      refute result[:success]
      assert_match(/skill context.*required/i, result[:response][:error][:message])
    end

    private

    def build_criteria
      dimensions = [
        Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30),
        Dimension.new(name: 'skill_adherence', description: 'Follows skill?', max_score: 25)
      ]
      Criteria.new(path: '/dev/null').tap do |c|
        c.instance_variable_set(:@context, 'Evaluate API')
        c.instance_variable_set(:@pass_threshold, 70)
        c.instance_variable_set(:@minimum_delta, 10)
        c.instance_variable_set(:@dimensions, dimensions)
      end
    end
  end
end
