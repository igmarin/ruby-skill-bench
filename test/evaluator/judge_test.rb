# frozen_string_literal: true

require_relative '../test_helper'

class JudgeTest < Minitest::Test
  def test_call_sends_correct_prompt_to_client
    task = 'do something'
    criteria = '{"score": "1-100"}'
    baseline_diff = '+ baseline code'
    context_diff = '+ context code'

    expected_response = { success: true, response: { message: { 'content' => '{"baseline_score": 80, "context_score": 90, "reasoning": "better context"}' } } }

    SkillBench::Client.expects(:call).with do |params|
      params[:system_prompt].include?('objective judge') &&
        params[:messages].first[:content].include?('BASELINE')
    end.returns(expected_response)

    result = SkillBench::Judge.call(task, criteria, baseline_diff, context_diff)

    assert result[:success]
    assert_equal '{"baseline_score": 80, "context_score": 90, "reasoning": "better context"}', result[:response][:content]
  end

  def test_call_returns_error_on_client_failure
    SkillBench::Client.expects(:call).returns({ success: false, response: { error: { message: 'API failure' } } })

    result = SkillBench::Judge.call('task', 'criteria', 'diff1', 'diff2')

    refute result[:success]
    assert_equal 'API failure', result[:response][:error][:message]
  end
end
