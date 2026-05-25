# frozen_string_literal: true

require 'json'

module SkillBench
  module Registry
    # Resolves skill paths from the ecosystem registry manifest.
    # Reads a registry.json (from agent-mcp-runtime) and resolves
    # pack → tile.json → skill path.
    class PackResolver
      # @param registry_path [String] Path to registry.json manifest
      def initialize(registry_path)
        @manifest = JSON.parse(File.read(registry_path))
      end

      # Resolves a skill path within a named pack.
      #
      # @param pack_name [String] Pack name (e.g. "rails", "core", "hanami")
      # @param skill_name [String] Skill name (e.g. "code-review")
      # @return [String, nil] Absolute path to the skill directory, or nil
      def resolve_skill(pack_name, skill_name)
        pack = @manifest.dig('packs', pack_name)
        return nil unless pack

        source_path = resolve_source(pack['source'])
        return nil unless source_path

        tile_path = File.join(source_path, pack['tile'])
        return nil unless File.exist?(tile_path)

        tile = JSON.parse(File.read(tile_path))
        skill_entry = tile.dig('skills', skill_name)
        return nil unless skill_entry

        File.join(source_path, skill_entry['path'])
      end

      # Lists available pack names from the manifest.
      #
      # @return [Array<String>] Available pack names
      def pack_names
        @manifest.fetch('packs', {}).keys
      end

      private

      def resolve_source(source)
        repo_name = source.split('/').last
        candidates = [
          File.expand_path("../#{repo_name}", Dir.pwd),
          File.expand_path("../../#{repo_name}", Dir.pwd),
          File.join(Dir.home, '.agent-mcp-runtime', 'cache', repo_name)
        ]
        candidates.find { |c| Dir.exist?(c) }
      end
    end
  end
end
