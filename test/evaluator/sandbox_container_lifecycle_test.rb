# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'tmpdir'

# Container lifecycle activation (#88): prefer Docker when available, skip
# rebuild when the image already exists, keep fail-closed host when not.
class SandboxContainerLifecycleTest < Minitest::Test
  def setup
    @source_dir = Dir.mktmpdir('evaluator_lifecycle_source_')
    File.write(File.join(@source_dir, 'test_file.txt'), 'hello')
  end

  def teardown
    FileUtils.rm_rf(@source_dir)
  end

  def test_docker_available_is_false_when_context_missing
    SkillBench::Execution::Sandbox.stubs(:docker_context_path).returns('/nonexistent/docker/context')

    sandbox = SkillBench::Execution::Sandbox.new(@source_dir)

    refute sandbox.send(:docker_available?)
  end

  def test_docker_available_is_false_when_docker_daemon_unreachable
    Open3.stubs(:capture3).with('docker', 'info').returns(['', 'Cannot connect', stub(success?: false)])

    sandbox = SkillBench::Execution::Sandbox.new(@source_dir)

    refute sandbox.send(:docker_available?)
  end

  def test_docker_available_is_true_when_context_and_daemon_ok
    Open3.stubs(:capture3).with('docker', 'info').returns(['Server Version: 24', '', stub(success?: true)])

    sandbox = SkillBench::Execution::Sandbox.new(@source_dir)

    assert sandbox.send(:docker_available?)
  end

  def test_ensure_image_skips_build_when_image_already_present
    sandbox = SkillBench::Execution::Sandbox.new(@source_dir)
    image = SkillBench::Execution::Sandbox.image_ref

    sandbox.stubs(:image_present?).with(image).returns(true)
    sandbox.expects(:system).with('docker', 'build', anything, anything, anything, anything).never

    sandbox.send(:ensure_image)
  end

  def test_ensure_image_builds_when_image_missing
    sandbox = SkillBench::Execution::Sandbox.new(@source_dir)
    image = SkillBench::Execution::Sandbox.image_ref
    context = SkillBench::Execution::Sandbox.docker_context_path

    sandbox.stubs(:image_present?).with(image).returns(false)
    sandbox.expects(:system).with(
      'docker', 'build',
      '-t', image,
      '-t', "#{SkillBench::Constants::Sandbox::DOCKER_IMAGE_NAME}:latest",
      context,
      '--quiet'
    ).returns(true)

    sandbox.send(:ensure_image)
  end

  def test_start_container_sets_container_id_without_rebuild_when_image_present
    sandbox = SkillBench::Execution::Sandbox.new(@source_dir)
    sandbox.instance_variable_set(:@path, @source_dir)
    image = SkillBench::Execution::Sandbox.image_ref

    sandbox.stubs(:ensure_image)
    Open3.expects(:capture3).with do |*args|
      args[0] == 'docker' &&
        args[1] == 'run' &&
        args.include?('--network') && args.include?('none') &&
        args.include?('--security-opt') && args.include?('no-new-privileges') &&
        args.include?('--cap-drop') && args.include?('ALL') &&
        args.last == image
    end.returns(["cid-abc123\n", '', stub(success?: true)])

    sandbox.send(:start_container)

    assert_equal 'cid-abc123', sandbox.container_id
  end

  def test_run_yields_container_id_when_docker_available
    sandbox_double_path = nil

    SkillBench::Execution::Sandbox.any_instance.stubs(:docker_available?).returns(true)
    SkillBench::Execution::Sandbox.any_instance.stubs(:ensure_image)
    Open3.stubs(:capture3).with do |*args|
      args[0] == 'docker' && args[1] == 'run'
    end.returns(["live-container\n", '', stub(success?: true)])
    SkillBench::Execution::Sandbox.any_instance.stubs(:stop_container)

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      sandbox_double_path = sandbox.path

      assert_equal 'live-container', sandbox.container_id
    end

    refute_nil sandbox_double_path
  end

  def test_run_leaves_container_id_nil_when_docker_unavailable
    SkillBench::Execution::Sandbox.any_instance.stubs(:docker_available?).returns(false)
    SkillBench::Execution::Sandbox.any_instance.expects(:start_container).never

    SkillBench::Execution::Sandbox.run(@source_dir) do |sandbox|
      assert_nil sandbox.container_id
    end
  end

  def test_image_ref_includes_gem_version
    ref = SkillBench::Execution::Sandbox.image_ref

    assert_equal "evaluator-sandbox:#{SkillBench::VERSION}", ref
  end
end
