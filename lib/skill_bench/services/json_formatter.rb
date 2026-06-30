# frozen_string_literal: true

require 'json'

module SkillBench
  module Services
    # Formats evaluation results as JSON.
    class JsonFormatter
      # Zeroed token usage used when a result carries no usage data.
      EMPTY_USAGE = { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }.freeze

      # Format result as JSON.
      #
      # Ensures top-level :tokens and :cost fields are always present (additive;
      # existing keys are preserved) so JSON consumers see a stable shape.
      #
      # @param result [Hash] Eval result.
      # @return [String] JSON-formatted string.
      def self.format(result)
        JSON.pretty_generate(with_usage_fields(result))
      end

      # Returns the result augmented with token/cost fields when missing.
      #
      # @param result [Hash] Eval result (returned unchanged when not a Hash).
      # @return [Hash] Result with :tokens and :cost guaranteed present.
      def self.with_usage_fields(result)
        return result unless result.is_a?(Hash)

        defaults = {
          tokens: result[:tokens] || result.dig(:response, :tokens) || EMPTY_USAGE,
          cost: result.key?(:cost) ? result[:cost] : result.dig(:response, :cost)
        }
        defaults.merge(result)
      end
    end
  end
end
