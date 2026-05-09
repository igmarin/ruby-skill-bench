# frozen_string_literal: true

require 'json'

module SkillBench
  # Loads, validates, and represents evaluation criteria from criteria.json.
  #
  # Merges eval-specific dimension overrides with built-in default descriptions
  # and validates that dimension weights sum to exactly 100.
  class Criteria
    attr_reader :dimensions, :context, :pass_threshold, :minimum_delta

    # Loads criteria from a JSON file.
    #
    # @param path [String] Path to the criteria.json file.
    # @return [Hash] Service response with :success and :response keys.
    # @raise [TypeError] when the provided path is not a string.
    def self.call(path:)
      new(path:).call
    end

    # Returns an empty criteria with default thresholds and no dimensions.
    #
    # @return [SkillBench::Criteria] An empty criteria instance.
    def self.empty
      new(path: '').tap do |criteria|
        criteria.instance_variable_set(:@context, '')
        criteria.instance_variable_set(:@pass_threshold, 70)
        criteria.instance_variable_set(:@minimum_delta, 10)
        criteria.instance_variable_set(:@dimensions, [])
      end
    end

    # @param path [String] Path to the criteria.json file.
    def initialize(path:)
      @path = path
    end

    # Loads and validates the criteria file.
    #
    # @return [Hash] Service response with criteria or error.
    def call
      raw = load_json
      return raw unless raw[:success]

      data = raw[:response][:data]
      raw_dimensions = data['dimensions'] || data[:dimensions] || []
      dimensions = build_dimensions(raw_dimensions)

      validation = validate_dimensions(dimensions)
      return validation unless validation[:success]

      assign_attributes(data, dimensions)

      { success: true, response: { criteria: self } }
    rescue StandardError => e
      SkillBench::ErrorLogger.log_error(e, 'Criteria Load Error')
      { success: false, response: { error: { message: e.message } } }
    end

    private

    attr_reader :path

    def load_json
      return missing_file_result unless File.exist?(path)

      data = JSON.parse(File.read(path))
      { success: true, response: { data: data } }
    rescue JSON::ParserError => e
      { success: false, response: { error: { message: "Invalid JSON: #{e.message}" } } }
    end

    def missing_file_result
      { success: false, response: { error: { message: "Criteria file #{path} does not exist" } } }
    end

    def build_dimensions(raw_dimensions)
      defaults = DEFAULT_DIMENSIONS.to_h { |d| [d.name, d] }

      raw_dimensions.map do |raw|
        name = raw['name'] || raw[:name]
        default = defaults[name]
        description = raw['description'] || raw[:description] || default&.description || ''

        Dimension.new(
          name: name,
          description: description,
          max_score: raw['max_score'] || raw[:max_score]
        )
      end
    end

    def validate_dimensions(dimensions)
      total = dimensions.sum { |d| d.max_score.to_i }
      return { success: true, response: {} } if total == 100

      {
        success: false,
        response: { error: { message: "Dimension max_scores must sum to 100, got #{total}" } }
      }
    end

    def assign_attributes(data, dimensions)
      @context = data['context'] || data[:context] || ''
      @pass_threshold = data['pass_threshold'] || data[:pass_threshold] || 70
      @minimum_delta = data['minimum_delta'] || data[:minimum_delta] || 10
      @dimensions = dimensions
    end
  end
end
