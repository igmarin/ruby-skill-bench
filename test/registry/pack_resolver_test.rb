# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'json'

module SkillBench
  class PackResolverTest < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir
      @registry_path = File.join(@tmpdir, 'registry.json')

      @rails_repo = File.join(@tmpdir, 'rails-agent-skills')
      @skills_dir = File.join(@rails_repo, 'skills')
      @code_review_dir = File.join(@skills_dir, 'code-quality', 'code-review')
      FileUtils.mkdir_p(@code_review_dir)
      File.write(File.join(@code_review_dir, 'SKILL.md'), '# Code Review')

      tile = {
        'skills' => {
          'code-review' => { 'path' => 'skills/code-quality/code-review' }
        }
      }
      File.write(File.join(@rails_repo, 'tile.json'), JSON.generate(tile))

      manifest = {
        'packs' => {
          'rails' => {
            'source' => 'igmarin/zzz-test-nonexistent-rails-agent-skills',
            'tile' => 'tile.json'
          }
        }
      }
      File.write(@registry_path, JSON.generate(manifest))
    end

    def teardown
      FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
    end

    def test_resolves_skill_from_pack
      resolver = Registry::PackResolver.new(@registry_path)
      stub_resolve_source(resolver, @rails_repo)

      result = resolver.resolve_skill('rails', 'code-review')

      assert_equal File.join(@code_review_dir), result
    end

    def test_returns_nil_for_unknown_pack
      resolver = Registry::PackResolver.new(@registry_path)
      result = resolver.resolve_skill('unknown-pack', 'code-review')

      assert_nil result
    end

    def test_returns_nil_for_unknown_skill
      resolver = Registry::PackResolver.new(@registry_path)
      stub_resolve_source(resolver, @rails_repo)

      result = resolver.resolve_skill('rails', 'unknown-skill')

      assert_nil result
    end

    def test_lists_pack_names
      resolver = Registry::PackResolver.new(@registry_path)

      assert_equal ['rails'], resolver.pack_names
    end

    def test_returns_nil_when_source_not_found
      resolver = Registry::PackResolver.new(@registry_path)
      result = resolver.resolve_skill('rails', 'code-review')

      assert_nil result
    end

    def test_returns_nil_when_tile_missing
      FileUtils.rm_f(File.join(@rails_repo, 'tile.json'))
      resolver = Registry::PackResolver.new(@registry_path)
      stub_resolve_source(resolver, @rails_repo)

      result = resolver.resolve_skill('rails', 'code-review')

      assert_nil result
    end

    private

    def stub_resolve_source(resolver, repo_path)
      resolver.instance_variable_set(:@repo_path_override, repo_path)
      resolver.define_singleton_method(:resolve_source) { |_source| @repo_path_override }
    end
  end
end
