# frozen_string_literal: true

require_relative 'variant_resolver'
require_relative 'runner_service'

module SkillBench
  module Services
    # Runs both variants of a skill comparison.
    class ComparisonRunner
      # Runs both variants and returns their results.
      #
      # @param variant_a [Hash] First variant specification
      # @param variant_b [Hash] Second variant specification
      # @param skill_name [String] Name of the skill to compare
      # @param eval_path [String] Path to the eval directory
      # @param manifest_path [String, nil] Optional path to registry manifest
      # @return [Hash] Hash with :result_a and :result_b keys
      def self.call(variant_a, variant_b, skill_name, eval_path, manifest_path: nil)
        new(variant_a, variant_b, skill_name, eval_path, manifest_path: manifest_path).call
      end

      # @param variant_a [Hash] First variant specification
      # @param variant_b [Hash] Second variant specification
      # @param skill_name [String] Name of the skill to compare
      # @param eval_path [String] Path to the eval directory
      # @param manifest_path [String, nil] Optional path to registry manifest
      def initialize(variant_a, variant_b, skill_name, eval_path, manifest_path: nil)
        @variant_a = variant_a
        @variant_b = variant_b
        @skill_name = skill_name
        @eval_path = eval_path
        @manifest_path = manifest_path
      end

      # Runs both variants and returns their results.
      #
      # @return [Hash] Hash with :result_a and :result_b keys
      def call
        skill_paths_a = VariantResolver.call(@variant_a, @skill_name, manifest_path: @manifest_path)
        skill_paths_b = VariantResolver.call(@variant_b, @skill_name, manifest_path: @manifest_path)

        result_a = RunnerService.call(eval_name: @eval_path, skill_names: skill_paths_a)
        result_b = RunnerService.call(eval_name: @eval_path, skill_names: skill_paths_b)

        { result_a: result_a, result_b: result_b }
      end
    end
  end
end
