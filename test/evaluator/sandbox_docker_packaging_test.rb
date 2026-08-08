# frozen_string_literal: true

require_relative '../test_helper'
require 'rubygems'

# Packaging gate for container isolation (#86): the Docker build context must
# ship with the gem and be discoverable at the path Sandbox resolves.
class SandboxDockerPackagingTest < Minitest::Test
  def test_docker_context_directory_exists_next_to_sandbox
    docker_dir = SkillBench::Constants::Sandbox.docker_context_path

    assert File.directory?(docker_dir),
           "expected Docker context directory at #{docker_dir}"
  end

  def test_dockerfile_exists_in_docker_context
    dockerfile = File.join(SkillBench::Constants::Sandbox.docker_context_path, 'Dockerfile')

    assert_path_exists dockerfile, 'Dockerfile must exist in the Docker build context'
    contents = File.read(dockerfile)

    assert_match(/FROM /i, contents, 'Dockerfile must declare a base image')
    # Container stays up so `docker exec` can run allowlisted commands.
    assert_match(/CMD|ENTRYPOINT/i, contents, 'Dockerfile must keep a process alive for docker exec')
  end

  def test_gemspec_packages_docker_context_assets
    gemspec_path = File.expand_path('../../ruby-skill-bench.gemspec', __dir__)
    spec = Gem::Specification.load(gemspec_path)

    refute_nil spec, "failed to load gemspec at #{gemspec_path}"

    dockerfile_entry = 'lib/skill_bench/execution/docker/Dockerfile'

    assert_includes spec.files, dockerfile_entry,
                    'gemspec must package the Dockerfile (lib/**/*.rb alone is insufficient)'
  end

  def test_sandbox_resolves_same_docker_context_path_as_constant
    # Sandbox must use the packaged path constant so gem installs and checkouts agree.
    resolved = SkillBench::Execution::Sandbox.docker_context_path

    assert_equal SkillBench::Constants::Sandbox.docker_context_path, resolved
  end
end
