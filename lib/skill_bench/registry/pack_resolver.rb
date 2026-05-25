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
      # @param [Array<Object>] visited
      def resolve_skill(pack_name, skill_name, visited = [])
        return nil if visited.include?(pack_name)

        visited += [pack_name]

        pack = @manifest.dig('packs', pack_name)
        return nil unless pack

        source_path = resolve_source(pack['source'])
        return nil unless source_path

        tile_path = File.join(source_path, pack['tile'])
        return nil unless File.exist?(tile_path)

        tile = JSON.parse(File.read(tile_path))

        # 1. Try to resolve directly
        resolved = resolve_direct(tile, source_path, skill_name)
        return resolved if resolved

        # 2. Try to resolve via deprecated_skills redirect
        resolved = resolve_redirect(tile, skill_name, visited)
        return resolved if resolved

        # 3. Try to resolve via depends_on packs in registry
        resolve_dependencies(pack, skill_name, visited)
      end

      # Lists available pack names from the manifest.
      #
      # @return [Array<String>] Available pack names
      def pack_names
        @manifest.fetch('packs', {}).keys
      end

      private

      def resolve_direct(tile, source_path, skill_name)
        skill_entry = tile.dig('skills', skill_name)
        return nil unless skill_entry

        skill_path = File.join(source_path, skill_entry['path'])
        resolved = File.expand_path(skill_path)
        resolved = File.dirname(resolved) if resolved.end_with?('SKILL.md')
        base = File.expand_path(source_path)

        # Ensure resolved path is inside source directory
        resolved == base || resolved.start_with?(base + File::SEPARATOR) ? resolved : nil
      end

      def resolve_redirect(tile, skill_name, visited)
        dep_entry = tile.dig('deprecated_skills', skill_name)
        return nil unless dep_entry

        moved_to = dep_entry['moved_to']
        return nil unless moved_to

        target_pack = find_pack_by_source(moved_to)
        return nil unless target_pack

        resolve_skill(target_pack, skill_name, visited)
      end

      def resolve_dependencies(pack, skill_name, visited)
        depends_on = pack['depends_on']
        return nil unless depends_on.is_a?(Array)

        depends_on.each do |dep_pack|
          resolved = resolve_skill(dep_pack, skill_name, visited)
          return resolved if resolved
        end
        nil
      end

      def find_pack_by_source(source)
        @manifest.fetch('packs', {}).each do |pack_name, pack_config|
          if pack_config['source'] == source ||
             pack_config['source'].to_s.split('/').last == source.to_s.split('/').last
            return pack_name
          end
        end
        nil
      end

      def resolve_source(source)
        return nil unless source.is_a?(String) && !source.empty?

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
