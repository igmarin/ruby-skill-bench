# frozen_string_literal: true

require 'json'

module SkillBench
  module Judge
    # Parses and validates structured JSON responses from the LLM judge.
    #
    # Expects a JSON object with a 'dimensions' key mapping dimension names
    # to score hashes, and an optional 'overall_reasoning' string.
    class Response
      attr_reader :dimensions, :overall_reasoning

      # Parses a judge JSON string.
      #
      # @param json [String] The raw JSON string from the judge.
      # @return [Hash] Service response with parsed judge response or error.
      def self.call(json:)
        new(json:).call
      end

      # @param json [String] The raw JSON string from the judge.
      def initialize(json:)
        @json = json
      end

      # Parses and validates the judge JSON.
      #
      # @return [Hash] Service response with judge response or error.
      def call
        data = parse_json
        return data unless data[:success]

        payload = data[:response][:data]
        validation = validate_structure(payload)
        return validation unless validation[:success]

        dims = payload['dimensions'] || payload[:dimensions]
        extracted = extract_dimensions(dims)
        return extracted unless extracted[:success]

        @dimensions = extracted[:response][:dimensions]
        @overall_reasoning = payload['overall_reasoning'] || payload[:overall_reasoning] || ''

        { success: true, response: { judge_response: self } }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Judge::Response Parse Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      attr_reader :json

      def parse_json
        stripped = strip_markdown_fences(json)
        data = JSON.parse(stripped)
        { success: true, response: { data: data } }
      rescue JSON::ParserError => e
        { success: false, response: { error: { message: "Invalid JSON: #{e.message}" } } }
      end

      def strip_markdown_fences(text)
        return text unless text.start_with?('```')

        lines = text.each_line.to_a
        lines.shift if lines.first&.strip&.start_with?('```')
        lines.pop if lines.last&.strip == '```'
        lines.join.strip
      end

      def validate_structure(payload)
        dims = payload['dimensions'] || payload[:dimensions]

        return missing_dimensions_result if dims.nil?
        return empty_dimensions_result if dims.empty?

        { success: true, response: {} }
      end

      def missing_dimensions_result
        { success: false, response: { error: { message: "Judge response missing 'dimensions' key" } } }
      end

      def empty_dimensions_result
        { success: false, response: { error: { message: "Judge response 'dimensions' is empty" } } }
      end

      def extract_dimensions(dims)
        dimensions = {}

        dims.each do |name, dim|
          validated = validate_dimension(name, dim)
          return validated unless validated[:success]

          dimensions[name] = validated[:response][:dimension]
        end

        { success: true, response: { dimensions: dimensions } }
      end

      def validate_dimension(name, dim)
        score = dim['score'] || dim[:score]
        return missing_score_result(name) if score.nil?

        numeric_score = parse_numeric(score)
        return invalid_score_result(name, score) if numeric_score.nil?

        max_score = dim['max_score'] || dim[:max_score]
        max_score_result = validate_max_score(name, numeric_score, max_score)
        return max_score_result unless max_score_result[:success]

        {
          success: true,
          response: {
            dimension: {
              score: numeric_score,
              max_score: max_score,
              reasoning: dim['reasoning'] || dim[:reasoning] || ''
            }
          }
        }
      end

      def validate_max_score(name, numeric_score, max_score)
        return { success: true, response: {} } unless max_score
        return invalid_max_score_result(name, max_score) unless max_score.is_a?(Numeric)
        return out_of_bounds_result(name, numeric_score, max_score) if numeric_score.negative? || numeric_score > max_score

        { success: true, response: {} }
      end

      def parse_numeric(value)
        return value if value.is_a?(Numeric)

        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

      def missing_score_result(name)
        { success: false, response: { error: { message: "Judge dimension '#{name}' missing score" } } }
      end

      def invalid_score_result(name, score)
        { success: false, response: { error: { message: "Judge dimension '#{name}' has invalid score: #{score.inspect}" } } }
      end

      def out_of_bounds_result(name, score, max_score)
        { success: false, response: { error: { message: "Judge dimension '#{name}' score #{score} out of bounds (0..#{max_score})" } } }
      end

      def invalid_max_score_result(name, max_score)
        { success: false, response: { error: { message: "Judge dimension '#{name}' has invalid max_score: #{max_score.inspect} (must be numeric)" } } }
      end
    end
  end
end
