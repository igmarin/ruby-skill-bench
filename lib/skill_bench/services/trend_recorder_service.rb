# frozen_string_literal: true

require_relative '../trend_tracker'

module SkillBench
  module Services
    # Records evaluation results and computes trends.
    class TrendRecorderService
      # Serializes the load -> append -> write of the shared trend history
      # file. Batch runs ({BatchRunnerService}) execute evals concurrently and
      # the trend file is process-global shared state; without this lock,
      # concurrent records race on the temp-file rename and silently lose
      # appended entries.
      WRITE_MUTEX = Mutex.new

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
      # Loads the trend history once and reuses it for both the trend
      # computation and the append+write, avoiding a duplicate parse per run.
      #
      # @return [Hash] Result with success status and trend data
      def call
        tracker = TrendTracker.new
        enriched = @result.merge(eval_name: @eval_name, skill_names: @skill_names)
        trend, record_result = record_atomically(tracker, enriched)

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

      private

      # Loads history, computes the trend, and records the entry while holding
      # {WRITE_MUTEX}, so concurrent batch evals serialize their read-modify-
      # write of the shared trend file. History is still loaded exactly once
      # per run and reused for both the trend computation and the append.
      #
      # @param tracker [SkillBench::TrendTracker] The trend tracker
      # @param enriched [Hash] Result enriched with eval_name and skill_names
      # @return [Array(Hash, Hash)] The computed trend and the record result
      def record_atomically(tracker, enriched)
        WRITE_MUTEX.synchronize do
          history = tracker.history
          trend = tracker.trend_for(enriched, history)
          [trend, tracker.record(enriched, history)]
        end
      end
    end
  end
end
