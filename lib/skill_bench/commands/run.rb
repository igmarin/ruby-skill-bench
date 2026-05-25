# frozen_string_literal: true

require_relative '../services/runner_service'

module SkillBench
  module Commands
    # Handles the `skill-bench run` command
    class Run
      # Run an eval with specified skill(s)
      # @param eval_name [String] Name of eval to run (e.g., 'test-eval' or 'evals/test-eval')
      # @param skill_names [Array<String>] Names of skills to use
      # @param pack [String, nil] Optional pack name for registry-based skill resolution
      # @param registry_manifest [String, nil] Optional path to registry.json manifest
      # @return [Hash] Result with pass/fail and score
      def self.run(eval_name:, skill_names:, pack: nil, registry_manifest: nil)
        Services::RunnerService.call(
          eval_name: eval_name,
          skill_names: skill_names,
          pack: pack,
          registry_manifest: registry_manifest
        )
      end
    end
  end
end
