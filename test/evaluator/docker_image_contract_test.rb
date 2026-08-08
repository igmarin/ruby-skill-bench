# frozen_string_literal: true

require_relative '../test_helper'

# Image contract gate for container isolation (#87).
class DockerImageContractTest < Minitest::Test
  def test_dockerfile_documents_network_none_assumption
    dockerfile = File.join(SkillBench::Constants::Sandbox.docker_context_path, 'Dockerfile')
    contents = File.read(dockerfile)

    assert_match(/network none/i, contents)
    assert_match(/FROM ruby:/i, contents)
    assert_match(/sleep.*infinity|CMD \["sleep"/i, contents)
  end

  def test_docker_md_contract_exists
    doc = File.expand_path('../../docs/docker.md', __dir__)

    assert_path_exists doc
    body = File.read(doc)

    assert_match(/evaluator-sandbox/, body)
    assert_match(/network none/i, body)
    assert_match(/rake docker:build/, body)
  end

  def test_version_tag_format_matches_gem_version
    image = SkillBench::Constants::Sandbox::DOCKER_IMAGE_NAME
    versioned = "#{image}:#{SkillBench::VERSION}"

    assert_equal "evaluator-sandbox:#{SkillBench::VERSION}", versioned
  end

  def test_gemspec_packages_docker_docs_optional
    # Dockerfile packaging is required (#86); docs/docker.md is repo docs.
    gemspec_path = File.expand_path('../../ruby-skill-bench.gemspec', __dir__)
    spec = Gem::Specification.load(gemspec_path)

    assert_includes spec.files, 'docs/docker.md'
  end
end
