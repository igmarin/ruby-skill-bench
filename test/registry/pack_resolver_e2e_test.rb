# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  class PackResolverE2ETest < Minitest::Test
    def setup
      @registry_path = File.expand_path('../../../agent-mcp-runtime/registry.json', __dir__)
      skip 'E2E sibling repositories not present' unless File.exist?(@registry_path)

      @resolver = Registry::PackResolver.new(@registry_path)
    end

    def test_e2e_pack_names
      assert_includes @resolver.pack_names, 'core'
      assert_includes @resolver.pack_names, 'rails'
      assert_includes @resolver.pack_names, 'hanami'
      assert_includes @resolver.pack_names, 'planning'
    end

    def test_e2e_resolves_skills_across_packs
      %w[core rails hanami planning].each do |pack|
        pack_config = @resolver.instance_variable_get(:@manifest)['packs'][pack]
        source_path = @resolver.send(:resolve_source, pack_config['source'])
        tile_path = File.join(source_path, pack_config['tile'] || 'tile.json')
        next unless File.exist?(tile_path)

        tile = JSON.parse(File.read(tile_path))
        skills = tile['skills'] || {}
        next if skills.empty?

        first_skill = skills.keys.first
        resolved = @resolver.resolve_skill(pack, first_skill)

        refute_nil resolved, "Could not resolve skill #{first_skill} in pack #{pack}"

        expected_suffix = skills[first_skill]['path'].sub(%r{/SKILL\.md$}, '')

        assert resolved.end_with?(expected_suffix), "Expected #{resolved} to end with #{expected_suffix}"
        assert Dir.exist?(resolved), "Resolved path #{resolved} for skill #{first_skill} does not exist"
      end
    end

    def test_e2e_deprecated_skill_resolution
      deprecated = @resolver.resolve_skill('rails', 'write-yard-docs')

      refute_nil deprecated, 'Deprecated write-yard-docs should resolve'
      assert Dir.exist?(deprecated), "Resolved path #{deprecated} should exist"
      assert_match(/ruby-core-skills/, deprecated)
    end

    def test_e2e_depends_on_chain
      resolved = @resolver.resolve_skill('rails', 'tdd-process')

      refute_nil resolved, 'tdd-process should resolve via depends_on'
      assert Dir.exist?(resolved), "Resolved path #{resolved} should exist"
      assert_match(/ruby-core-skills/, resolved)
    end
  end
end
