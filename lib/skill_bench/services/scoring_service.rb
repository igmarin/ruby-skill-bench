# frozen_string_literal: true

module SkillBench
  module Services
    # Scores the agent result against eval criteria deterministically.
    #
    # Computes a composite score from test pass rate, timing compliance,
    # and error handling, then compares against thresholds in criteria.json.
    class ScoringService
      WEIGHT_TEST_PASS = 0.5
      WEIGHT_TIMING = 0.3
      WEIGHT_ERRORS = 0.2
      DEFAULT_PASS_THRESHOLD = 0.8
      DEFAULT_FAIL_THRESHOLD = 0.5

      # Scores the agent result against eval criteria.
      #
      # @param eval [SkillBench::Models::Eval] The eval being scored
      # @param result [Hash] The agent's result data
      # @param skill_name [String] Name of the skill used
      # @param provider_name [String] Name of the provider used
      # @return [Hash] Scored result with pass/fail status and score
      def self.call(eval:, result:, skill_name:, provider_name:)
        new(eval:, result:, skill_name:, provider_name:).call
      end

      # @param eval [SkillBench::Models::Eval] The eval
      # @param result [Hash] The agent's result
      # @param skill_name [String] Name of the skill
      # @param provider_name [String] Name of the provider
      def initialize(eval:, result:, skill_name:, provider_name:)
        @eval = eval
        @result = result
        @skill_name = skill_name
        @provider_name = provider_name
      end

      # Scores the result against the eval criteria.
      #
      # @return [Hash] Scored result with pass/fail status and score
      def call
        score = compute_score
        thresholds = load_thresholds

        {
          pass: score >= thresholds[:pass_threshold],
          score: score.round(2),
          eval_name: eval.name,
          skill_name: skill_name,
          provider_name: provider_name,
          details: {
            test_pass_rate: test_pass_rate,
            timing_score: timing_score,
            error_score: error_score,
            pass_threshold: thresholds[:pass_threshold],
            fail_threshold: thresholds[:fail_threshold]
          }
        }
      end

      private

      attr_reader :eval, :result, :skill_name, :provider_name

      def compute_score
        (test_pass_rate * WEIGHT_TEST_PASS) +
          (timing_score * WEIGHT_TIMING) +
          (error_score * WEIGHT_ERRORS)
      end

      def test_pass_rate
        return 1.0 unless result.key?(:test_results)

        tests = result[:test_results]
        return 1.0 if tests.empty?

        passed = tests.count { |t| ['passed', :passed].include?(t[:status]) }
        passed.to_f / tests.size
      end

      def timing_score
        return 1.0 unless result.key?(:duration_seconds) && result.key?(:max_duration_seconds)

        duration = result[:duration_seconds]
        max_duration = result[:max_duration_seconds]
        return 1.0 if max_duration.zero?

        ratio = duration.to_f / max_duration
        ratio <= 1.0 ? 1.0 : [0.0, 1.0 - (ratio - 1.0)].max
      end

      def error_score
        return 1.0 if ['success', :success].include?(result[:status])
        return 0.0 if ['error', :error].include?(result[:status])

        error_count = result.fetch(:error_count, 0)
        total_count = result.fetch(:total_count, 1)
        return 1.0 if total_count.zero?

        [0.0, 1.0 - (error_count.to_f / total_count)].round(2)
      end

      def load_thresholds
        criteria = eval.criteria
        {
          pass_threshold: criteria.dig(:pass, :score_threshold) || DEFAULT_PASS_THRESHOLD,
          fail_threshold: criteria.dig(:fail, :score_threshold) || DEFAULT_FAIL_THRESHOLD
        }
      end
    end
  end
end
