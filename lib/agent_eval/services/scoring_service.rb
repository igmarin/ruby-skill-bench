# frozen_string_literal: true

module AgentEval
  module Services
    # Scores the agent result against eval criteria
    class ScoringService
      def self.call(eval:, result:, skill_name:, provider_name:)
        new(eval, result, skill_name, provider_name).call
      end

      def initialize(eval, result, skill_name, provider_name)
        @eval = eval
        @result = result
        @skill_name = skill_name
        @provider_name = provider_name
      end

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
