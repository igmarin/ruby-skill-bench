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

    def test_resolves_deprecated_skill_via_redirect
      core_repo = File.join(@tmpdir, 'ruby-core-skills')
      core_skills_dir = File.join(core_repo, 'skills')
      write_yard_docs_dir = File.join(core_skills_dir, 'docs', 'write-yard-docs')
      FileUtils.mkdir_p(write_yard_docs_dir)
      File.write(File.join(write_yard_docs_dir, 'SKILL.md'), '# Write YARD Docs')

      core_tile = {
        'skills' => {
          'write-yard-docs' => { 'path' => 'skills/docs/write-yard-docs' }
        }
      }
      File.write(File.join(core_repo, 'tile.json'), JSON.generate(core_tile))

      manifest = {
        'packs' => {
          'core' => {
            'source' => 'igmarin/ruby-core-skills',
            'tile' => 'tile.json'
          },
          'rails' => {
            'source' => 'igmarin/rails-agent-skills',
            'tile' => 'tile.json'
          }
        }
      }
      File.write(@registry_path, JSON.generate(manifest))

      rails_tile = {
        'skills' => {},
        'deprecated_skills' => {
          'write-yard-docs' => {
            'moved_to' => 'igmarin/ruby-core-skills'
          }
        }
      }
      File.write(File.join(@rails_repo, 'tile.json'), JSON.generate(rails_tile))

      resolver = Registry::PackResolver.new(@registry_path)
      rails_repo = @rails_repo
      resolver.define_singleton_method(:resolve_source) do |source|
        if source == 'igmarin/ruby-core-skills'
          core_repo
        elsif source == 'igmarin/rails-agent-skills'
          rails_repo
        end
      end

      result = resolver.resolve_skill('rails', 'write-yard-docs')

      assert_equal File.join(write_yard_docs_dir), result
    end

    def test_resolves_depends_on_skill
      core_repo = File.join(@tmpdir, 'ruby-core-skills')
      core_skills_dir = File.join(core_repo, 'skills')
      tdd_process_dir = File.join(core_skills_dir, 'process', 'tdd-process')
      FileUtils.mkdir_p(tdd_process_dir)
      File.write(File.join(tdd_process_dir, 'SKILL.md'), '# TDD Process')

      core_tile = {
        'skills' => {
          'tdd-process' => { 'path' => 'skills/process/tdd-process' }
        }
      }
      File.write(File.join(core_repo, 'tile.json'), JSON.generate(core_tile))

      manifest = {
        'packs' => {
          'core' => {
            'source' => 'igmarin/ruby-core-skills',
            'tile' => 'tile.json'
          },
          'rails' => {
            'source' => 'igmarin/rails-agent-skills',
            'tile' => 'tile.json',
            'depends_on' => ['core']
          }
        }
      }
      File.write(@registry_path, JSON.generate(manifest))

      rails_tile = { 'skills' => {} }
      File.write(File.join(@rails_repo, 'tile.json'), JSON.generate(rails_tile))

      resolver = Registry::PackResolver.new(@registry_path)
      rails_repo = @rails_repo
      resolver.define_singleton_method(:resolve_source) do |source|
        if source == 'igmarin/ruby-core-skills'
          core_repo
        elsif source == 'igmarin/rails-agent-skills'
          rails_repo
        end
      end

      result = resolver.resolve_skill('rails', 'tdd-process')

      assert_equal File.join(tdd_process_dir), result
    end

    private

    def stub_resolve_source(resolver, repo_path)
      resolver.instance_variable_set(:@repo_path_override, repo_path)
      resolver.define_singleton_method(:resolve_source) { |_source| @repo_path_override }
    end
  end
end
