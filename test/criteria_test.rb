# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class CriteriaTest < Minitest::Test
    def test_loads_valid_criteria_json
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), valid_criteria_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        assert result[:success]
        criteria = result[:response][:criteria]

        assert_equal 5, criteria.dimensions.size
        assert_equal 'Evaluate whether the skill helps build a proper API REST collection', criteria.context
        assert_equal 70, criteria.pass_threshold
        assert_equal 10, criteria.minimum_delta
      end
    end

    def test_merges_eval_descriptions_with_defaults
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), criteria_with_override_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        assert result[:success]
        criteria = result[:response][:criteria]
        dim = criteria.dimensions.find { |d| d.name == 'skill_adherence' }

        assert_equal 'Did the agent follow the .call pattern?', dim.description
      end
    end

    def test_returns_error_when_dimensions_do_not_sum_to_one_hundred
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), invalid_sum_json)

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/must sum to 100/, result[:response][:error][:message])
      end
    end

    def test_returns_error_when_file_missing
      result = Criteria.call(path: 'nonexistent/criteria.json')

      refute result[:success]
      assert_match(/does not exist/, result[:response][:error][:message])
    end

    def test_returns_error_on_invalid_json
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'criteria.json'), 'not json')

        result = Criteria.call(path: File.join(dir, 'criteria.json'))

        refute result[:success]
        assert_match(/Invalid JSON/, result[:response][:error][:message])
      end
    end

    private

    def valid_criteria_json
      {
        context: 'Evaluate whether the skill helps build a proper API REST collection',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25 },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def criteria_with_override_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 30 },
          { name: 'skill_adherence', max_score: 25, description: 'Did the agent follow the .call pattern?' },
          { name: 'code_quality', max_score: 20 },
          { name: 'test_coverage', max_score: 15 },
          { name: 'documentation', max_score: 10 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end

    def invalid_sum_json
      {
        context: 'Evaluate API',
        dimensions: [
          { name: 'correctness', max_score: 20 },
          { name: 'skill_adherence', max_score: 20 }
        ],
        pass_threshold: 70,
        minimum_delta: 10
      }.to_json
    end
  end
end
