# frozen_string_literal: true

require 'test_helper'
require 'yaml'

module Evaluator
  class CiIntegrationTest < Minitest::Test
    def test_github_actions_workflow_exists
      assert_path_exists '.github/workflows/ci.yml', 'GitHub Actions workflow should exist at .github/workflows/ci.yml'
    end

    def test_workflow_runs_required_checks
      workflow = YAML.safe_load_file('.github/workflows/ci.yml')
      steps = workflow['jobs']['test']['steps']
      step_names = steps.map { |s| s['name'] || s['run'] }.join(' ')

      assert_includes step_names, 'rubocop'
      assert_includes step_names, 'reek'
      assert_includes step_names, 'minitest'
    end
  end
end
