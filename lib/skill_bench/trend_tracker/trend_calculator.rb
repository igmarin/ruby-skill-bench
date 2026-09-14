# frozen_string_literal: true

require_relative '../judge/variance'

module SkillBench
  class TrendTracker
    # Calculates performance trends between evaluation results
    class TrendCalculator
      # Computes trend comparison between current result and historical entries
      #
      # @param entries [Array<Hash>] Historical entries
      # @param current_entry [Hash] Current evaluation entry
      # @return [Hash, nil] Trend data or nil if no matching history exists
      def self.compute_trend(entries, current_entry)
        matching = filter_matching_entries(entries, current_entry)
        return nil if matching.empty?

        previous = matching.last
        current_baseline = current_entry[:baseline_total]
        current_context = current_entry[:context_total]
        previous_baseline = previous[:baseline_total]
        previous_context = previous[:context_total]
        return nil unless current_baseline && current_context && previous_baseline && previous_context

        {
          baseline_trend: trend_direction(current_baseline, previous_baseline),
          context_trend: trend_direction(current_context, previous_context),
          baseline_delta: current_baseline - previous_baseline,
          context_delta: current_context - previous_context,
          previous_run: previous[:timestamp],
          judge_variance: judge_variance(matching, current_context)
        }
      end

      class << self
        private

        # Filters historical entries to match current evaluation configuration
        #
        # @param entries [Array<Hash>] Historical entries
        # @param current_entry [Hash] Current evaluation entry
        # @return [Array<Hash>] Matching entries
        def filter_matching_entries(entries, current_entry)
          entries.select do |entry|
            entry[:eval_name] == current_entry[:eval_name] &&
              entry[:skill_names].sort == current_entry[:skill_names].sort
          end
        end

        # Determines trend direction between two values
        #
        # @param current [Numeric] Current value
        # @param previous [Numeric] Previous value
        # @return [Symbol] :improved, :regressed, or :unchanged
        def trend_direction(current, previous)
          return :unchanged if current == previous

          current > previous ? :improved : :regressed
        end

        def judge_variance(matching, current_context)
          totals = matching.filter_map { |entry| entry[:context_total] } + [current_context]
          result = SkillBench::Judge::Variance.call(totals: totals)
          result[:success] ? result[:response] : nil
        end
      end
    end
  end
end
