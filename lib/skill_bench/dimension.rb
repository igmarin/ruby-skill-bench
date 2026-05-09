# frozen_string_literal: true

module SkillBench
  # Value object representing a scoring dimension for evaluation.
  #
  # Dimensions are used by the judge to score agent output across
  # different aspects such as correctness, code quality, and skill adherence.
  class Dimension
    attr_reader :name, :description, :max_score

    # @param name [String] The machine-friendly identifier for the dimension.
    # @param description [String] Human-readable explanation of what the dimension measures.
    # @param max_score [Integer, nil] Maximum score this dimension can contribute. Nil in defaults.
    def initialize(name:, description:, max_score:)
      @name = name
      @description = description
      @max_score = max_score
    end

    # Compares two Dimension instances for equality.
    #
    # @param other [Object] The object to compare against.
    # @return [Boolean] true when all attributes match.
    def ==(other)
      other.is_a?(Dimension) &&
        name == other.name &&
        description == other.description &&
        max_score == other.max_score
    end
    alias eql? ==

    # Computes a hash code based on attributes.
    #
    # @return [Integer] The hash code.
    def hash
      [name, description, max_score].hash
    end
  end

  # Canonical dimensions used when eval authors do not override descriptions.
  # Weights (max_score) are nil here; the eval's criteria.json provides them.
  DEFAULT_DIMENSIONS = [
    Dimension.new(
      name: 'correctness',
      description: 'Does the output fulfill the task requirements? Are all specified behaviors present and correct?',
      max_score: nil
    ),
    Dimension.new(
      name: 'skill_adherence',
      description: 'Did the agent follow the specific patterns, hard gates, and workflows defined in the skill?',
      max_score: nil
    ),
    Dimension.new(
      name: 'code_quality',
      description: 'Is the code clean, well-structured, free of smells, follows SRP, and avoids duplication?',
      max_score: nil
    ),
    Dimension.new(
      name: 'test_coverage',
      description: 'Are there meaningful tests? Do they test the right things? Are they following TDD/best practices from the skill?',
      max_score: nil
    ),
    Dimension.new(
      name: 'documentation',
      description: 'Is there adequate YARD documentation, clear intent, and helpful inline comments where needed?',
      max_score: nil
    )
  ].freeze
end
