# frozen_string_literal: true

require 'test_helper'
require 'yaml'

module SkillBench
  class CiIntegrationTest < Minitest::Test
    def setup
      @project_root = File.expand_path('../..', __dir__)
    end

    def test_github_actions_workflow_exists
      workflow_path = File.join(@project_root, '.github', 'workflows', 'ci.yml')

      assert_path_exists workflow_path, 'GitHub Actions workflow should exist at .github/workflows/ci.yml'
    end

    def test_workflow_runs_required_checks
      workflow_path = File.join(@project_root, '.github', 'workflows', 'ci.yml')
      workflow = YAML.safe_load_file(workflow_path)
      steps = workflow['jobs']['test']['steps']
      step_names = steps.map { |s| s['name'] || s['run'] }.join(' ')

      assert_includes step_names, 'rubocop'
      assert_includes step_names, 'reek'
      assert_includes step_names, 'minitest'
      assert_equal %w[3.3 3.4 4.0], workflow.dig('jobs', 'test', 'strategy', 'matrix', 'ruby-version')
      assert workflow.dig('jobs', 'container-integration'), 'Docker integration job should remain in CI'
    end
  end
end
