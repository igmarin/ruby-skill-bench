# frozen_string_literal: true

module SkillBench
  module Services
    # Scores the agent result against eval criteria
    class ScoringService
      # Scores the agent result against eval criteria.
      #
      # @param eval [SkillBench::Models::Eval] The eval being scored
      # @param result [Hash] The agent's result data
      # @param skill_name [String] Name of the skill used
      # @param provider_name [String] Name of the provider used
      # @return [Hash] Scored result with pass/fail status and score
      def self.call(eval:, result:, skill_name:, provider_name:)
        new(eval, result, skill_name, provider_name).call
      end

      # @param eval [SkillBench::Models::Eval] The eval
      # @param result [Hash] The agent's result
      # @param skill_name [String] Name of the skill
      # @param provider_name [String] Name of the provider
      def initialize(eval, result, skill_name, provider_name)
        @eval = eval
        @result = result
        @skill_name = skill_name
        @provider_name = provider_name
      end

      # Scores the result against the eval criteria.
      #
      # @return [Hash] Scored result with pass/fail status and score
      def call
        # TODO: Implement real scoring logic (LLM or custom scorer)
        {
          pass: true,
          score: 1.0,
          eval_name: eval.name,
          skill_name: skill_name,
          provider_name: provider_name
        }
      end

      private

      attr_reader :eval, :result, :skill_name, :provider_name
    end
  end
end
