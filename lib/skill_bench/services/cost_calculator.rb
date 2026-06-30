# frozen_string_literal: true

module SkillBench
  module Services
    # Estimates the USD cost of an LLM run from token usage and a model name.
    #
    # Prices are approximate, drawn from public OpenAI/Anthropic pricing pages,
    # and expressed in USD per 1,000 tokens. Provider pricing changes over time,
    # so treat the result as a rough estimate and extend {PRICES} as needed.
    class CostCalculator
      # Approximate per-model prices in USD per 1,000 tokens.
      # Keyed by a canonical model prefix; longer prefixes win on lookup so that
      # dated variants (e.g. "claude-3-5-sonnet-20241022") resolve correctly.
      # Source: public OpenAI and Anthropic pricing pages (approximate).
      PRICES = {
        'gpt-4o-mini' => { input: 0.00015, output: 0.0006 },
        'gpt-4o' => { input: 0.005, output: 0.015 },
        'gpt-4-turbo' => { input: 0.01, output: 0.03 },
        'gpt-4' => { input: 0.03, output: 0.06 },
        'gpt-3.5-turbo' => { input: 0.0005, output: 0.0015 },
        'claude-3-5-sonnet' => { input: 0.003, output: 0.015 },
        'claude-3-5-haiku' => { input: 0.0008, output: 0.004 },
        'claude-3-opus' => { input: 0.015, output: 0.075 },
        'claude-3-sonnet' => { input: 0.003, output: 0.015 },
        'claude-3-haiku' => { input: 0.00025, output: 0.00125 }
      }.freeze

      # Token count that one priced unit of {PRICES} covers.
      TOKENS_PER_UNIT = 1000.0

      # Estimates the USD cost for a run.
      #
      # @param usage [Hash, nil] Token usage with :prompt_tokens and :completion_tokens.
      # @param model [String, nil] The model name (e.g. "gpt-4o").
      # @return [Float, nil] Estimated cost in USD, or nil when the model is unknown.
      def self.call(usage:, model:)
        new(usage, model).call
      end

      # @param usage [Hash, nil] Token usage hash.
      # @param model [String, nil] The model name.
      def initialize(usage, model)
        @usage = usage || {}
        @model = model
      end

      # Estimates the USD cost for the configured usage and model.
      #
      # @return [Float, nil] Estimated cost in USD, or nil when the model is unknown.
      def call
        price = price_for(@model)
        return nil unless price

        input_cost = units(:prompt_tokens) * price[:input]
        output_cost = units(:completion_tokens) * price[:output]
        (input_cost + output_cost).round(6)
      end

      private

      # Finds the price entry for a model by longest matching name prefix.
      #
      # @param model [String, nil] The model name.
      # @return [Hash, nil] Price entry with :input and :output, or nil when unknown.
      def price_for(model)
        key = model.to_s.downcase
        return PRICES[key] if PRICES.key?(key)

        PRICES.select { |name, _| key.start_with?(name) }.max_by { |name, _| name.length }&.last
      end

      # Converts a usage token count into priced 1K-token units.
      #
      # @param key [Symbol] The usage key to read.
      # @return [Float] The number of priced units.
      def units(key)
        token_count(key) / TOKENS_PER_UNIT
      end

      # Reads a token count from the usage hash, tolerating string keys.
      #
      # @param key [Symbol] The usage key (e.g. :prompt_tokens).
      # @return [Integer] The token count, or zero when absent.
      def token_count(key)
        (@usage[key] || @usage[key.to_s] || 0).to_i
      end
    end
  end
end
