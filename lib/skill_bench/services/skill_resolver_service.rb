# frozen_string_literal: true

require_relative '../models/skill'
require_relative 'skill_resolver'
require_relative '../registry/pack_resolver'

module SkillBench
  module Services
    # Resolves skills from names, supporting both direct resolution and pack-based resolution.
    class SkillResolverService
      # Default registry manifest path relative to the current working directory.
      DEFAULT_REGISTRY_MANIFEST = '../agent-mcp-runtime/registry.json'
      private_constant :DEFAULT_REGISTRY_MANIFEST

      # Resolves skills from names.
      #
      # @param skill_names [Array<String>] Names of the skills to resolve
      # @param pack [String, nil] Optional pack name for registry-based skill resolution
      # @param registry_manifest [String, nil] Optional path to registry.json manifest
      # @return [Array<SkillBench::Models::Skill>] The resolved skills
      # @raise [ArgumentError] when a skill cannot be resolved
      def self.call(skill_names, pack: nil, registry_manifest: nil)
        new(skill_names, pack: pack, registry_manifest: registry_manifest).call
      end

      # @param skill_names [Array<String>] Names of the skills
      # @param pack [String, nil] Optional pack name
      # @param registry_manifest [String, nil] Optional registry.json path
      def initialize(skill_names, pack: nil, registry_manifest: nil)
        @skill_names = skill_names
        @pack = pack
        @registry_manifest = registry_manifest
      end

      # Resolves the skills from names.
      #
      # @return [Array<SkillBench::Models::Skill>] The resolved skills
      # @raise [ArgumentError] when a skill cannot be resolved
      def call
        return @call if defined?(@call)

        @call = if @pack && !@pack.empty?
                  resolve_pack_skills
                else
                  @skill_names.map { |name| Services::SkillResolver.call(name) }
                end
      end

      private

      attr_reader :skill_names, :pack, :registry_manifest

      def resolve_pack_skills
        manifest_path = registry_manifest || DEFAULT_REGISTRY_MANIFEST
        manifest_absolute = File.expand_path(manifest_path, Dir.pwd)

        raise ArgumentError, "Registry manifest not found: #{manifest_path}" unless File.exist?(manifest_absolute)

        resolver = Registry::PackResolver.new(manifest_absolute)

        skill_names.map do |skill_name|
          path = resolver.resolve_skill(pack, skill_name)
          raise ArgumentError, "Skill '#{skill_name}' not found in pack '#{pack}'" unless path

          Models::Skill.new(name: skill_name, path: path)
        end
      end
    end
  end
end
