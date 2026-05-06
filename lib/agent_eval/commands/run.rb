# frozen_string_literal: true

require_relative '../models/eval'
require_relative '../models/skill'
require_relative '../models/provider_registry'
require_relative '../models/config'

module AgentEval
  module Commands
    # Handles the `agent-eval run` command
    class Run
      # Run an eval with specified skill and provider
      # @param eval_name [String] Name of eval to run
      # @param skill_name [String] Name of skill to use
      # @param provider_name [String] Name of provider to use
      # @return [Hash] Result with pass/fail and score
      def self.run(eval_name:, skill_name:, provider_name:)
        eval = AgentEval::Models::Eval.load(eval_name)
        skill = find_skill(skill_name)
        provider = find_provider(provider_name)

        result = spawn_agent(eval, skill, provider)
        score_result(eval, result)
      end

      # Find a skill by name
      # @param skill_name [String] Skill name to find
      # @return [AgentEval::Models::Skill] Found skill
      # @raise [RuntimeError] if skill not found
      def self.find_skill(skill_name)
        skills = AgentEval::Models::Skill.discover
        skills.find { |skill| skill.name == skill_name } || raise("Skill not found: #{skill_name}")
      end

      # Find a provider by name
      # @param provider_name [String] Provider name to find
      # @return [AgentEval::Models::Provider] Found provider
      # @raise [RuntimeError] if provider not found
      def self.find_provider(provider_name)
        config = AgentEval::Models::Config.load
        registry = AgentEval::Models::ProviderRegistry.load_from_config(config.providers)
        registry.get(provider_name) || raise("Provider not found: #{provider_name}")
      end

      # Spawn agent with eval, skill, and provider
      # @param _eval [AgentEval::Models::Eval] Eval to run
      # @param _skill [AgentEval::Models::Skill] Skill to use
      # @param _provider [AgentEval::Models::Provider] Provider to use
      # @return [String] Agent execution result
      def self.spawn_agent(_eval, _skill, _provider)
        # TODO: Implement actual agent spawning (subprocess or Ruby class)
        'Agent result placeholder'
      end

      # Score the agent result against eval criteria
      # @param _eval [AgentEval::Models::Eval] Eval with criteria
      # @param _result [String] Agent execution result
      # @return [Hash] Score with pass/fail and score value
      def self.score_result(_eval, _result)
        # TODO: Implement scoring logic (LLM or custom scorer)
        { pass: true, score: 1.0 }
      end
    end
  end
end
