# frozen_string_literal: true

require 'json'

module SkillBench
  # Parses and validates structured JSON responses from the LLM judge.
  #
  # Expects a JSON object with a 'dimensions' key mapping dimension names
  # to score hashes, and an optional 'overall_reasoning' string.
  class JudgeResponse
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
      SkillBench::ErrorLogger.log_error(e, 'JudgeResponse Parse Error')
      { success: false, response: { error: { message: e.message } } }
    end

    private

    attr_reader :json

    def parse_json
      data = JSON.parse(json)
      { success: true, response: { data: data } }
    rescue JSON::ParserError => e
      { success: false, response: { error: { message: "Invalid JSON: #{e.message}" } } }
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
        score = dim['score'] || dim[:score]
        return missing_score_result if score.nil?

        dimensions[name] = {
          score: score,
          max_score: dim['max_score'] || dim[:max_score],
          reasoning: dim['reasoning'] || dim[:reasoning] || ''
        }
      end

      { success: true, response: { dimensions: dimensions } }
    end

    def missing_score_result
      { success: false, response: { error: { message: 'Judge dimension missing score' } } }
    end
  end
end
