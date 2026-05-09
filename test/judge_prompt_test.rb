# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class JudgePromptTest < Minitest::Test
    def test_builds_prompt_with_all_sections
      criteria = build_criteria
      result = JudgePrompt.call(
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
      result = JudgePrompt.call(
        task: '',
        criteria: criteria,
        skill_context: 'context',
        agent_output: 'output'
      )

      refute result[:success]
      assert_match(/task.*required/i, result[:response][:error][:message])
    end

    def test_returns_error_when_criteria_missing
      result = JudgePrompt.call(
        task: 'Create API',
        criteria: nil,
        skill_context: 'context',
        agent_output: 'output'
      )

      refute result[:success]
      assert_match(/criteria.*required/i, result[:response][:error][:message])
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
