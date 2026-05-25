# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'

module SkillBench
  class SourcePathResolverTest < Minitest::Test
    def test_infers_skill_source_path_from_eval_path
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'evals/skills/rails-code-review/review-order'
      )

      assert_equal 'skills/rails-code-review', resolved
    end

    def test_infers_old_format_skill_source_path
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'evals/skills/security/authentication/login-eval'
      )

      assert_equal 'skills/security/authentication', resolved
    end

    def test_infers_skill_source_path_from_evaluator_eval_path
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'evaluator/evals/skills/rails-code-review/review-order'
      )

      assert_equal 'skills/rails-code-review', resolved
    end

    def test_infers_skill_source_path_from_private_evals_path
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'private-evals/skills/rails-code-review/review-order'
      )

      assert_equal 'skills/rails-code-review', resolved
    end

    def test_infers_workflow_source_path_from_eval_path
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'evals/workflows/rails-tdd-loop/full-feature'
      )

      assert_equal 'workflows/rails-tdd-loop', resolved
    end

    def test_prefers_explicit_override
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'evals/workflows/rails-tdd-loop/full-feature',
        skill_path: 'skills/patterns/ruby-service-objects'
      )

      assert_equal 'skills/patterns/ruby-service-objects', resolved
    end

    def test_returns_nil_for_unmapped_eval_path_without_override
      resolved = Execution::SourcePathResolver.call(eval_folder_path: 'tmp/custom-evals/example')

      assert_nil resolved
    end

    def test_handles_absolute_paths_with_ambiguous_segments
      # Simulate an absolute path where 'skills' appears early in the parent directories
      absolute_path = File.expand_path('my-skills/rails-agent-skills/evaluator/evals/skills/graphql-best-practices/some-eval', '/')
      resolved = Execution::SourcePathResolver.call(eval_folder_path: absolute_path)

      assert_equal 'skills/graphql-best-practices', resolved
    end

    def test_local_skills_resolve_first_with_empty_sources
      resolved = Execution::SourcePathResolver.call(
        eval_folder_path: 'evals/skills/refactor-process/basic',
        skill_sources: {}
      )

      assert_equal 'skills/refactor-process', resolved
    end

    def test_falls_back_to_skill_sources_when_local_not_found
      Dir.mktmpdir do |tmpdir|
        source_path = File.join(tmpdir, 'code-quality')
        skill_dir = File.join(source_path, 'write-yard-docs')
        FileUtils.mkdir_p(skill_dir)
        File.write(File.join(skill_dir, 'SKILL.md'), '# Write YARD Docs')

        resolved = Execution::SourcePathResolver.call(
          eval_folder_path: 'tmp/evals/skills/write-yard-docs/basic',
          skill_sources: { 'core' => tmpdir }
        )

        assert_equal File.join(source_path, 'write-yard-docs'), resolved
      end
    end

    def test_first_matching_source_wins
      Dir.mktmpdir do |tmpdir_a|
        Dir.mktmpdir do |tmpdir_b|
          source_a = File.join(tmpdir_a, 'code-quality')
          skill_a = File.join(source_a, 'write-yard-docs')
          FileUtils.mkdir_p(skill_a)
          File.write(File.join(skill_a, 'SKILL.md'), '# A')

          source_b = File.join(tmpdir_b, 'patterns')
          skill_b = File.join(source_b, 'write-yard-docs')
          FileUtils.mkdir_p(skill_b)
          File.write(File.join(skill_b, 'SKILL.md'), '# B')

          resolved = Execution::SourcePathResolver.call(
            eval_folder_path: 'custom/evals/skills/write-yard-docs/basic',
            skill_sources: { 'first' => tmpdir_a, 'second' => tmpdir_b }
          )

          assert_equal File.join(source_a, 'write-yard-docs'), resolved
        end
      end
    end

    def test_returns_nil_for_unmapped_path_with_skill_sources
      Dir.mktmpdir do |tmpdir|
        resolved = Execution::SourcePathResolver.call(
          eval_folder_path: 'tmp/custom-no-skills/eval',
          skill_sources: { 'core' => tmpdir }
        )

        assert_nil resolved
      end
    end
  end
end
