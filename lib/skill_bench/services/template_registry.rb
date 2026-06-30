# frozen_string_literal: true

require 'json'
require_relative '../dimension'
require_relative 'template_registry/category_data'

module SkillBench
  module Services
    # Resolves and renders evaluation templates by type and category.
    #
    # Provides a registry of template strings for generating eval scaffolding
    # (task descriptions, scoring criteria, and skill instructions) across
    # supported Rails pattern categories. Supports variable interpolation
    # using +{{variable_name}}+ syntax.
    #
    # @example Resolve a task template with variables
    #   TemplateRegistry.call(:task_md, :crud, skill_name: "UserCreator")
    #
    # @example Resolve criteria JSON
    #   TemplateRegistry.call(:criteria_json, :api)
    class TemplateRegistry
      TEMPLATE_TYPES = %i[task_md criteria_json skill_md].freeze
      CATEGORIES = REGISTRY.keys.freeze

      # Score weight per core scoring dimension. Keyed by the canonical
      # +SkillBench::DEFAULT_DIMENSIONS+ names so scaffolded criteria can never
      # drift from the names the runtime loader requires; values sum to 100.
      CRITERIA_DIMENSION_SCORES = {
        'correctness' => 30,
        'skill_adherence' => 25,
        'code_quality' => 20,
        'test_coverage' => 15,
        'documentation' => 10
      }.freeze

      # Canonical dimension descriptions keyed by name, sourced from the runtime defaults.
      CORE_DIMENSION_DESCRIPTIONS = SkillBench::DEFAULT_DIMENSIONS.to_h { |dimension| [dimension.name, dimension.description] }.freeze

      # Top-level thresholds emitted with scaffolded criteria.
      CRITERIA_PASS_THRESHOLD = 70
      CRITERIA_MINIMUM_DELTA = 10

      # @param template_type [Symbol, String] Template type (:task_md, :criteria_json, :skill_md)
      # @param category [Symbol, String] Category (:crud, :api, :background_job, etc.)
      # @param variables [Hash{Symbol, String => String}] Variables for interpolation
      # @return [String] The rendered template content
      # @raise [ArgumentError] if template_type or category is invalid
      def self.call(template_type, category, variables = {})
        new(template_type, category, variables).call
      end

      # @param template_type [Symbol, String] Template type
      # @param category [Symbol, String] Category
      # @param variables [Hash{Symbol, String => String}] Variables for interpolation
      def initialize(template_type, category, variables = {})
        @template_type = template_type.to_sym
        @category = category.to_sym
        @variables = variables
      end

      # Resolves the template and applies variable interpolation.
      #
      # @return [String] The rendered template content
      # @raise [ArgumentError] if template_type or category is invalid
      def call
        validate_template_type!
        validate_category!

        interpolate(build_template)
      end

      private

      attr_reader :template_type, :category, :variables

      def validate_template_type!
        return if TEMPLATE_TYPES.include?(template_type)

        raise ArgumentError, "Invalid template type: #{template_type}. Valid types: #{TEMPLATE_TYPES.join(', ')}"
      end

      def validate_category!
        return if CATEGORIES.include?(category)

        raise ArgumentError, "Invalid category: #{category}. Valid categories: #{CATEGORIES.join(', ')}"
      end

      def category_data
        REGISTRY.fetch(category)
      end

      def build_template
        case template_type
        when :task_md then build_task_md
        when :criteria_json then build_criteria_json
        when :skill_md then build_skill_md
        end
      end

      def interpolate(template)
        variables.reduce(template.dup) do |result, (key, value)|
          result.gsub("{{#{key}}}", value.to_s)
        end
      end

      def build_task_md
        <<~MARKDOWN
          # Task: Implement {{skill_name}} (#{category})

          ## Objective

          Implement a #{category.to_s.tr('_', ' ')} following Rails best practices and the project's established patterns.

          ## Requirements

          #{category_data.requirements}

          ## Acceptance Criteria

          - All tests pass (`bundle exec rake test`)
          - Code follows project conventions
          - YARD documentation for all public methods
          - No rubocop or reek offenses
        MARKDOWN
      end

      # Builds runtime-loadable scoring criteria for the category.
      #
      # Emits the five core dimensions required by {SkillBench::Criteria}
      # (+correctness+, +skill_adherence+, +code_quality+, +test_coverage+,
      # +documentation+) with integer +max_score+ values summing to 100, plus
      # the top-level +pass_threshold+ and +minimum_delta+ the loader expects.
      # Category-specific flavor lives only in the dimension descriptions.
      #
      # @return [String] Pretty-printed criteria JSON.
      def build_criteria_json
        JSON.pretty_generate(
          category: category.to_s,
          dimensions: criteria_dimensions,
          pass_threshold: CRITERIA_PASS_THRESHOLD,
          minimum_delta: CRITERIA_MINIMUM_DELTA
        )
      end

      # @return [Array<Hash>] Core dimensions with integer +max_score+ summing to 100.
      def criteria_dimensions
        focus = category_data.criteria[:focus]
        CRITERIA_DIMENSION_SCORES.map do |name, max_score|
          {
            name: name,
            max_score: max_score,
            description: "#{CORE_DIMENSION_DESCRIPTIONS.fetch(name)} (#{category} focus: #{focus})"
          }
        end
      end

      def build_skill_md
        <<~MARKDOWN
          # Skill: {{skill_name}} (#{category})

          ## Pattern

          #{category_data.pattern}

          ## Hard Rules

          1. Follow TDD — write failing test first, then implement.
          2. Use `.call` class method as entry point (Service Object pattern).
          3. Each class has one responsibility (SRP).
          4. YARD documentation on all public methods.
          5. `rubocop -A` and `reek` must pass.

          ## Template

          ```ruby
          #{category_data.code_template}
          ```
        MARKDOWN
      end
    end
  end
end
