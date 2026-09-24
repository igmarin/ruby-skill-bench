# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class GemspecTest < Minitest::Test
    def setup
      gemspec_path = File.expand_path('../../ruby-skill-bench.gemspec', __dir__)
      @spec = Gem::Specification.load(gemspec_path)
    end

    def test_package_metadata_points_to_project_sources
      assert_equal 'https://github.com/igmarin/ruby-skill-bench', @spec.homepage
      assert_equal 'https://github.com/igmarin/ruby-skill-bench',
                   @spec.metadata['source_code_uri']
      assert_equal 'true', @spec.metadata['rubygems_mfa_required']
    end

    def test_package_requires_ruby_3_3_or_newer
      assert_equal Gem::Requirement.new('>= 3.3'), @spec.required_ruby_version
    end

    def test_runtime_dependencies_use_the_updated_json_and_parallel_majors
      dependencies = @spec.dependencies.to_h { |dependency| [dependency.name, dependency.requirement] }

      assert_equal Gem::Requirement.new('~> 3.0'), dependencies.fetch('json')
      assert_equal Gem::Requirement.new('~> 2.0'), dependencies.fetch('parallel')
    end

    def test_package_includes_readme_and_license
      assert_includes @spec.files, 'README.md'
      assert_includes @spec.files, 'LICENSE'
    end

    def test_package_includes_evaluator_lib_files_when_loaded_from_repo_root
      assert_includes @spec.files, 'lib/skill_bench/version.rb'
      assert_includes @spec.files, 'lib/skill_bench/runner.rb'
    end

    def test_package_includes_readme_linked_docs
      assert_includes @spec.files, 'docs/architecture.md'
      assert_includes @spec.files, 'docs/testing-guide.md'
    end
  end
end
