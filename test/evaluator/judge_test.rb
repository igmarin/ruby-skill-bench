# frozen_string_literal: true

require_relative '../test_helper'

class JudgeTest < Minitest::Test
  def test_call_sends_prompt_to_client_and_returns_judge_response
    prompt = 'Evaluate this output'
    client_response = {
      success: true,
      response: { message: { 'content' => judge_json } }
    }

    SkillBench::Client.expects(:call).with do |params|
      params[:system_prompt].include?('objective judge') &&
        params[:messages].first[:content] == prompt
    end.returns(client_response)

    result = SkillBench::Judge.call(prompt: prompt)

    assert result[:success]
    response = result[:response][:judge_response]

    assert_equal 28, response.dimensions['correctness'][:score]
    assert_equal 'Overall solid', response.overall_reasoning
  end

  def test_call_returns_error_on_client_failure
    SkillBench::Client.expects(:call).returns({ success: false, response: { error: { message: 'API failure' } } })

    result = SkillBench::Judge.call(prompt: 'prompt')

    refute result[:success]
    assert_equal 'API failure', result[:response][:error][:message]
  end

  def test_call_returns_error_when_judge_response_invalid
    SkillBench::Client.expects(:call).returns({
                                                success: true,
                                                response: { message: { 'content' => 'not json' } }
                                              })

    result = SkillBench::Judge.call(prompt: 'prompt')

    refute result[:success]
    assert_match(/Invalid JSON/, result[:response][:error][:message])
  end

  private

  def judge_json
    {
      dimensions: {
        correctness: { score: 28, max_score: 30, reasoning: 'Good work' }
      },
      overall_reasoning: 'Overall solid'
    }.to_json
  end
end
