# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'tmpdir'

# Opt-in live Docker proof for container isolation (#89).
# Skips unless SKILL_BENCH_DOCKER_TESTS=1 and a Docker daemon is reachable.
class SandboxDockerLiveTest < Minitest::Test
  def setup
    skip 'Set SKILL_BENCH_DOCKER_TESTS=1 to run live Docker tests' unless ENV['SKILL_BENCH_DOCKER_TESTS'] == '1'
    skip 'Docker daemon not available' unless docker_daemon_available?

    @source_dir = Dir.mktmpdir('skill_bench_live_docker_')
    File.write(File.join(@source_dir, 'probe.txt'), "hello-live\n")
    SkillBench::Config.reset
    SkillBench::Config.allowed_commands = %w[echo cat true]
    SkillBench::Config.allow_host_execution = false
  end

  def teardown
    FileUtils.rm_rf(@source_dir) if @source_dir
  end

  def test_run_command_executes_inside_live_container
    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      refute_nil sandbox.container_id, 'expected a live container_id when Docker is available'

      working_dir = Pathname.new(sandbox.path)
      result = SkillBench::Tools::RunCommand.call('echo live-ok', working_dir, sandbox.container_id)

      assert_match(/Exit Status: 0/, result)
      assert_match(/STDOUT:\nlive-ok/, result)
    end
  end

  def test_container_is_stopped_after_sandbox_run
    container_id = nil

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      container_id = sandbox.container_id
      refute_nil container_id
    end

    _out, _err, status = Open3.capture3('docker', 'inspect', container_id)
    refute status.success?, 'container should be removed/stopped after sandbox exits'
  end

  private

  def docker_daemon_available?
    _out, _err, status = Open3.capture3('docker', 'info')
    status.success?
  rescue Errno::ENOENT
    false
  end
end
