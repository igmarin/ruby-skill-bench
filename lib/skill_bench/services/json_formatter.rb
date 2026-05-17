# frozen_string_literal: true

require 'json'

module SkillBench
  module Services
    # Formats evaluation results as JSON.
    class JsonFormatter
      # Format result as JSON.
      #
      # @param result [Hash] Eval result.
      # @return [String] JSON-formatted string.
      def self.format(result)
        JSON.pretty_generate(result)
      end
    end
  end
end
