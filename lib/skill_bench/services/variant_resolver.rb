# frozen_string_literal: true

require_relative '../registry/pack_resolver'
require_relative 'runner_service'
require_relative 'manifest_finder'

module SkillBench
  module Services
    # Resolves skill paths from variant specifications.
    class VariantResolver
      # Resolves skill paths from a variant specification.
      #
      # @param variant [Hash] Parsed variant from VariantParser
      # @param skill_name [String] Name of the skill to resolve
      # @param manifest_path [String, nil] Optional path to registry manifest
      # @return [Array<String>] Array of skill paths
      # @raise [ArgumentError] when skill cannot be resolved
      def self.call(variant, skill_name, manifest_path: nil)
        new(variant, skill_name, manifest_path: manifest_path).call
      end

      # @param variant [Hash] Parsed variant from VariantParser
      # @param skill_name [String] Name of the skill to resolve
      # @param manifest_path [String, nil] Optional path to registry manifest
      def initialize(variant, skill_name, manifest_path: nil)
        @variant = variant
        @skill_name = skill_name
        @manifest_path = manifest_path
      end

      # Resolves skill paths from the variant specification.
      #
      # @return [Array<String>] Array of skill paths
      # @raise [ArgumentError] when skill cannot be resolved or variant type is unknown
      def call
        case @variant[:type]
        when :pack
          resolve_pack_skill
        when :path
          [@variant[:path]]
        else
          raise ArgumentError, "Unknown variant type: #{@variant[:type]}, variant: #{@variant.inspect}"
        end
      end

      private

      # Resolves a skill from a pack.
      #
      # @return [Array<String>] Array containing the resolved skill path
      # @raise [ArgumentError] when skill is not found in pack
      def resolve_pack_skill
        pack_name = @variant[:name]
        manifest = @manifest_path || ManifestFinder.call
        resolver = Registry::PackResolver.new(manifest)
        resolved = resolver.resolve_skill(pack_name, @skill_name)
        raise ArgumentError, "Skill '#{@skill_name}' not found in pack '#{pack_name}'" unless resolved

        [resolved]
      end
    end
  end
end
