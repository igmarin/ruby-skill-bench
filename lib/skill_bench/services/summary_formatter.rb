# frozen_string_literal: true

require 'json'

module SkillBench
  module Services
    # Builds a compact JSON summary of a batch run for CI gating.
    #
    # Surfaces the aggregate pass/fail counts plus rolled-up token and cost
    # usage and the single worst skill-vs-baseline delta across the batch, so
    # a CI job can gate on (and archive) one machine-readable artifact.
    class SummaryFormatter
      # Format an aggregate batch envelope as a pretty JSON summary string.
      #
      # @param aggregate [Hash] Aggregate envelope with :results and :summary.
      # @return [String] Pretty-printed JSON summary.
      def self.format(aggregate)
        new(aggregate).format
      end

      # @param aggregate [Hash] Aggregate envelope with :results and :summary.
      def initialize(aggregate)
        @results = aggregate[:results] || []
        @summary = aggregate[:summary] || {}
      end

      # Builds the JSON summary document.
      #
      # @return [String] Pretty-printed JSON summary.
      def format
        JSON.pretty_generate(
          passed: summary[:passed],
          failed: summary[:failed],
          total: summary[:total],
          tokens: total_tokens,
          cost: total_cost,
          worst_delta: worst_delta
        )
      end

      private

      attr_reader :results, :summary

      # Sums total_tokens across every result, treating missing usage as 0.
      #
      # @return [Integer] Aggregate token count.
      def total_tokens
        results.sum { |result| tokens_for(result) }
      end

      # Reads a single result's total token count.
      #
      # @param result [Hash] A single-eval result envelope.
      # @return [Integer] total_tokens, or 0 when absent.
      def tokens_for(result)
        tokens = result[:tokens] || {}
        tokens[:total_tokens] || tokens['total_tokens'] || 0
      end

      # Sums non-nil per-result costs.
      #
      # @return [Float, nil] Total cost, or nil when no result reports a cost.
      def total_cost
        costs = results.filter_map { |result| result[:cost] }
        costs.empty? ? nil : costs.sum
      end

      # Finds the eval with the smallest skill-vs-baseline delta.
      #
      # @return [Hash, nil] {:eval_name, :delta} for the worst eval, or nil
      #   when no result carries a delta report.
      def worst_delta
        scored = results.filter_map { |result| delta_entry(result) }
        scored.min_by { |entry| entry[:delta] }
      end

      # Builds a {eval_name, delta} entry for a result with a delta report.
      #
      # @param result [Hash] A single-eval result envelope.
      # @return [Hash, nil] Entry hash, or nil when the report lacks deltas.
      def delta_entry(result)
        report = result.dig(:response, :report)
        return nil unless report.respond_to?(:context_total) && report.respond_to?(:baseline_total)

        { eval_name: result[:eval_name], delta: report.context_total - report.baseline_total }
      end
    end
  end
end
