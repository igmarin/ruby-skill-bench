# frozen_string_literal: true

require_relative '../trend_tracker'

module SkillBench
  module Services
    # Records evaluation results and computes trends.
    class TrendRecorderService
      # Records evaluation results and computes trends.
      #
      # @param result [Hash] The evaluation result from Evaluation::Runner
      # @param eval_name [String] Name of the eval
      # @param skill_names [Array<String>] Names of the skills
      # @return [Hash] Result with success status and trend data
      def self.call(result, eval_name, skill_names)
        new(result, eval_name, skill_names).call
      end

      # @param result [Hash] The evaluation result from Evaluation::Runner
      # @param eval_name [String] Name of the eval
      # @param skill_names [Array<String>] Names of the skills
      def initialize(result, eval_name, skill_names)
        @result = result
        @eval_name = eval_name
        @skill_names = skill_names
      end

      # Records evaluation results and computes trends.
      #
      # @return [Hash] Result with success status and trend data
      def call
        tracker = TrendTracker.new
        enriched = @result.merge(eval_name: @eval_name, skill_names: @skill_names)
        trend = tracker.trend_for(enriched)
        record_result = tracker.record(enriched)

        record_success = record_result.is_a?(Hash) && record_result[:success]
        unless record_success
          message = if record_result.is_a?(Hash)
                      record_result.dig(:response, :error, :message) ||
                        record_result.dig(:error, :message) ||
                        'Unknown error'
                    else
                      'Unexpected record response'
                    end
          SkillBench::ErrorLogger.log_error(
            StandardError.new(message),
            "Trend tracking record failed for eval #{@eval_name}"
          )
          return {
            success: false,
            response: {
              error: {
                message: "Trend tracking record failed: #{message}",
                record_result: record_result
              }
            }
          }
        end
        { success: true, trend: trend }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Trend tracking failed')
        { success: false, response: { error: { message: e.message } } }
      end
    end
  end
end
