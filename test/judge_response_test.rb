# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class JudgeResponseTest < Minitest::Test
    def test_parses_valid_judge_json
      result = JudgeResponse.call(json: valid_judge_json)

      assert result[:success]
      response = result[:response][:judge_response]

      assert_equal 5, response.dimensions.size
      assert_equal 28, response.dimensions['correctness'][:score]
      assert_equal 30, response.dimensions['correctness'][:max_score]
      assert_equal 'Good work', response.dimensions['correctness'][:reasoning]
      assert_equal 'Overall solid', response.overall_reasoning
    end

    def test_rejects_invalid_json
      result = JudgeResponse.call(json: 'not json')

      refute result[:success]
      assert_match(/Invalid JSON/, result[:response][:error][:message])
    end

    def test_rejects_missing_dimensions_key
      result = JudgeResponse.call(json: { overall_reasoning: 'ok' }.to_json)

      refute result[:success]
      assert_match(/missing 'dimensions'/, result[:response][:error][:message])
    end

    def test_rejects_empty_dimensions
      result = JudgeResponse.call(json: { dimensions: {}, overall_reasoning: 'ok' }.to_json)

      refute result[:success]
      assert_match(/empty/, result[:response][:error][:message])
    end

    def test_rejects_dimension_without_score
      result = JudgeResponse.call(json: invalid_dimension_json)

      refute result[:success]
      assert_match(/missing score/, result[:response][:error][:message])
    end

    def test_accepts_integer_and_float_scores
      result = JudgeResponse.call(json: mixed_scores_json)

      assert result[:success]
      response = result[:response][:judge_response]

      assert_equal 28, response.dimensions['correctness'][:score]
      assert_in_delta(22.5, response.dimensions['skill_adherence'][:score])
    end

    private

    def valid_judge_json
      {
        dimensions: {
          correctness: { score: 28, max_score: 30, reasoning: 'Good work' },
          skill_adherence: { score: 22, max_score: 25, reasoning: 'Followed well' },
          code_quality: { score: 16, max_score: 20, reasoning: 'Clean code' },
          test_coverage: { score: 13, max_score: 15, reasoning: 'Good tests' },
          documentation: { score: 8, max_score: 10, reasoning: 'Adequate docs' }
        },
        overall_reasoning: 'Overall solid'
      }.to_json
    end

    def invalid_dimension_json
      {
        dimensions: {
          correctness: { max_score: 30, reasoning: 'Missing score' }
        },
        overall_reasoning: 'Bad'
      }.to_json
    end

    def mixed_scores_json
      {
        dimensions: {
          correctness: { score: 28, max_score: 30, reasoning: 'Good' },
          skill_adherence: { score: 22.5, max_score: 25, reasoning: 'Followed' }
        },
        overall_reasoning: 'Mixed'
      }.to_json
    end
  end
end
