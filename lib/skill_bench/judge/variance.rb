# frozen_string_literal: true

require_relative '../error_logger'

module SkillBench
  module Judge
    # Sample statistics over repeated judge totals.
    class Variance
      # @param totals [Array<Numeric>] Judge totals from repeated runs of the same eval.
      # @return [Hash] `{ success: true, response: { n:, mean:, stddev:, spread: } }`
      def self.call(totals:)
        new(totals).call
      end

      # @param totals [Array<Numeric>]
      def initialize(totals)
        @totals = totals
      end

      # @return [Hash]
      def call
        nums = Array(@totals).map { |total| Float(total) }
        count = nums.size
        return empty_result(count: count) if count < 2

        mean = nums.sum / count
        sample_variance = nums.sum { |value| (value - mean)**2 } / (count - 1)

        {
          success: true,
          response: {
            n: count,
            mean: mean,
            stddev: Math.sqrt(sample_variance),
            spread: nums.max - nums.min
          }
        }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Judge::Variance Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      def empty_result(count:)
        { success: true, response: { n: count, mean: nil, stddev: nil, spread: nil } }
      end
    end
  end
end
