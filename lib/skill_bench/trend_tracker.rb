# frozen_string_literal: true

require 'time'
require_relative 'trend_tracker/persistence'
require_relative 'trend_tracker/trend_calculator'

module SkillBench
  # Tracks evaluation results over time and computes trend deltas.
  class TrendTracker
    DEFAULT_HISTORY_FILE = '.skill-bench-trends.json'

    # @param history_file [String] Path to the history JSON file.
    def initialize(history_file: DEFAULT_HISTORY_FILE)
      @persistence = Persistence.new(history_file)
    end

    # Records an evaluation result.
    #
    # @param result [Hash] The evaluation result from EvaluationRunner.
    # @param history [Array<Hash>] Pre-loaded history to append to; defaults to a fresh load.
    # @return [Hash] Service response.
    def record(result, history = @persistence.load)
      history << extract_entry(result)
      write_result = @persistence.write(history)

      return { success: false, response: { error: write_result[:error] } } unless write_result[:success]

      { success: true, response: { recorded: true } }
    rescue StandardError => e
      SkillBench::ErrorLogger.log_error(e, 'TrendTracker Error')
      { success: false, response: { error: { message: e.message } } }
    end

    # Loads the full history.
    #
    # @return [Array<Hash>] List of historical entries.
    def history
      @persistence.load
    end

    # Computes the trend of the given result against the most recent matching history entry.
    #
    # @param result [Hash] The current evaluation result.
    # @param history [Array<Hash>] Pre-loaded history to compare against; defaults to a fresh load.
    # @return [Hash, nil] Trend data or nil if no matching history exists.
    def trend_for(result, history = @persistence.load)
      current = extract_entry(result)
      TrendCalculator.compute_trend(history, current)
    end

    private

    def extract_entry(result)
      report = result.dig(:response, :report)
      {
        timestamp: Time.now.iso8601,
        eval_name: result[:eval_name],
        skill_names: result[:skill_names],
        verdict: report&.verdict,
        baseline_total: report&.baseline_total,
        context_total: report&.context_total,
        deltas: report&.deltas
      }
    end
  end
end
