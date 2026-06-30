# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'tmpdir'

class SandboxTest < Minitest::Test
  def setup
    @source_dir = Dir.mktmpdir('evaluator_test_source_')
    File.write(File.join(@source_dir, 'test_file.txt'), 'hello world')
  end

  def teardown
    FileUtils.rm_rf(@source_dir)
  end

  def test_run_copies_files_and_initializes_git
    stub_docker

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      assert_path_exists File.join(sandbox.path, 'test_file.txt')
      assert_path_exists File.join(sandbox.path, '.git')

      # Test diff is empty initially
      diff = SkillBench::Execution::Sandbox.capture_diff(sandbox.path)

      assert_equal 'No code changes made.', diff

      # Make a change
      File.write(File.join(sandbox.path, 'test_file.txt'), 'hello updated')
      diff = SkillBench::Execution::Sandbox.capture_diff(sandbox.path)

      assert_includes diff, 'hello updated'
    end
  end

  # Fix (a): a pre-existing `.git` in the source must never be copied; the
  # sandbox creates its own fresh repository, so attacker-controlled repo
  # state (config diff/filter drivers, hooks) cannot reach host git ops.
  def test_run_does_not_copy_source_git_directory
    stub_docker
    plant_source_git_repo

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      sandbox_config = File.join(sandbox.path, '.git', 'config')

      assert_path_exists File.join(sandbox.path, '.git'), 'sandbox should have its own fresh repo'
      refute_includes File.read(sandbox_config), 'evil',
                      'source .git/config must not be copied into the sandbox'
      refute_path_exists File.join(sandbox.path, '.git', 'hooks', 'pre-commit'),
                         'source hooks must not be copied into the sandbox'
    end
  end

  # Fix (b): every git invocation carries the hardening flags that disable
  # in-repo/user attribute, hook, and fsmonitor drivers (DRY: one constant).
  def test_git_command_centralizes_hardening_flags
    argv = SkillBench::Execution::Sandbox.git_command('add', '.')

    assert_equal 'git', argv.first
    assert_equal %w[add .], argv.last(2)

    %w[
      core.attributesFile=/dev/null
      core.fsmonitor=false
      core.hooksPath=/dev/null
      core.symlinks=false
    ].each do |setting|
      assert_includes argv, setting, "hardening flag #{setting} missing"
      assert_equal '-c', argv[argv.index(setting) - 1], "#{setting} must follow a -c flag"
    end
  end

  # End-to-end: a malicious in-tree `.gitattributes` diff driver paired with a
  # `.git/config` definition must not execute any external program during the
  # host-side git lifecycle (setup_git + capture_diff).
  def test_malicious_gitattributes_diff_driver_does_not_execute
    stub_docker
    sentinel = File.join(Dir.mktmpdir('sandbox_sentinel_'), 'pwned')
    plant_source_git_repo(diff_command: "touch #{sentinel}")
    File.write(File.join(@source_dir, '.gitattributes'), "* diff=evil\n")

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      File.write(File.join(sandbox.path, 'test_file.txt'), 'hello updated')
      diff = SkillBench::Execution::Sandbox.capture_diff(sandbox.path)

      refute_path_exists sentinel, 'malicious diff driver must not run'
      assert_includes diff, 'hello updated', 'honest diff content must be preserved'
    end
  ensure
    FileUtils.rm_rf(File.dirname(sentinel)) if sentinel
  end

  # Behavior preserved: a benign `.gitattributes` is still copied and a normal
  # edit produces the same human-readable diff as before the hardening.
  def test_normal_source_with_gitattributes_produces_expected_diff
    stub_docker
    File.write(File.join(@source_dir, '.gitattributes'), "*.txt text\n")

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      assert_path_exists File.join(sandbox.path, '.gitattributes')

      File.write(File.join(sandbox.path, 'test_file.txt'), "hello world\nsecond line\n")
      diff = SkillBench::Execution::Sandbox.capture_diff(sandbox.path)

      assert_includes diff, 'diff --git a/test_file.txt b/test_file.txt'
      assert_includes diff, '+second line'
    end
  end

  private

  def stub_docker
    SkillBench::Execution::Sandbox.any_instance.stubs(:start_container)
    SkillBench::Execution::Sandbox.any_instance.stubs(:stop_container)
  end

  # Plants a fake source `.git` repo carrying an attacker-controlled diff
  # driver and a pre-commit hook, to prove neither is copied or executed.
  def plant_source_git_repo(diff_command: 'touch /tmp/skill_bench_should_not_run')
    git_dir = File.join(@source_dir, '.git')
    FileUtils.mkdir_p(File.join(git_dir, 'hooks'))
    File.write(File.join(git_dir, 'config'), <<~CONFIG)
      [diff "evil"]
      \tcommand = #{diff_command}
    CONFIG
    hook = File.join(git_dir, 'hooks', 'pre-commit')
    File.write(hook, "#!/bin/sh\ntouch #{File.join(@source_dir, 'hook_ran')}\n")
    FileUtils.chmod(0o755, hook)
  end
end
