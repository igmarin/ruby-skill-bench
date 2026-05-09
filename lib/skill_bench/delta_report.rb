# frozen_string_literal: true

module SkillBench
  # Computes baseline vs context deltas per dimension and determines verdict.
  #
  # Verdict is true when context score meets pass_threshold AND
  # the total delta meets minimum_delta.
  class DeltaReport
    attr_reader :deltas, :baseline_total, :context_total, :verdict, :baseline_scores, :context_scores, :criteria

    # Computes deltas and verdict from baseline and context judge responses.
    #
    # @param baseline [Hash] Baseline judge dimensions hash.
    # @param context [Hash] Context judge dimensions hash.
    # @param criteria [SkillBench::Criteria] The eval criteria with thresholds.
    # @return [Hash] Service response with delta_report or error.
    def self.call(baseline:, context:, criteria:)
      new(baseline:, context:, criteria:).call
    end

    # @param baseline [Hash] Baseline dimensions.
    # @param context [Hash] Context dimensions.
    # @param criteria [SkillBench::Criteria] Eval criteria.
    def initialize(baseline:, context:, criteria:)
      @baseline = baseline
      @context = context
      @criteria = criteria
      @deltas = {}
    end

    # Computes deltas and determines verdict.
    #
    # @return [Hash] Service response with delta_report or error.
    def call
      return mismatch_result unless dimensions_match?

      @baseline_scores = extract_scores(baseline)
      @context_scores = extract_scores(context)
      compute_totals
      compute_deltas
      determine_verdict

      { success: true, response: { delta_report: self } }
    rescue StandardError => e
      SkillBench::ErrorLogger.log_error(e, 'DeltaReport Error')
      { success: false, response: { error: { message: e.message } } }
    end

    private

    attr_reader :baseline, :context

    def dimensions_match?
      baseline.keys.sort == context.keys.sort
    end

    def mismatch_result
      { success: false, response: { error: { message: 'Baseline and context dimension names mismatch' } } }
    end

    def compute_totals
      @baseline_total = baseline.values.sum { |v| extract_score(v) }
      @context_total = context.values.sum { |v| extract_score(v) }
    end

    def compute_deltas
      baseline.each do |name, base|
        base_score = extract_score(base)
        context_score = extract_score(context[name])
        @deltas[name] = context_score - base_score
      end
    end

    def extract_score(dim)
      dim[:score] || dim['score']
    end

    def extract_scores(dimensions)
      dimensions.transform_values { |dim| extract_score(dim) }
    end

    def determine_verdict
      @verdict = context_total >= criteria.pass_threshold && total_delta >= criteria.minimum_delta
    end

    def total_delta
      context_total - baseline_total
    end
  end
end
