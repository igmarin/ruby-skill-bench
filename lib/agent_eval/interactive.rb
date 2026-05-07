# frozen_string_literal: true

require 'agent_eval/commands/run'

# Provides interactive CLI mode using gum-like menu system
module AgentEval
  # Interactive CLI module for agent-eval
  module Interactive
    # Run the interactive CLI mode
    # @return [Hash, nil] Result from Run.run, or nil if user exits
    def self.run
      choice = gum_choose
      return nil unless choice

      case choice
      when 'Run Eval'
        eval_name = select_eval
        skill_name = select_skill
        provider_name = select_provider

        return nil unless eval_name && skill_name && provider_name

        AgentEval::Commands::Run.run(
          eval_name: eval_name,
          skill_name: skill_name,
          provider_name: provider_name
        )
      when 'Exit'
        exit 0
      end
    end

    # Display main menu using gum
    # @return [String, nil] User's choice or nil
    def self.gum_choose
      'Run Eval' # Placeholder for gum integration
    end

    # Select an eval from available evals
    # @return [String, nil] Eval name or nil
    def self.select_eval
      'test-eval' # Placeholder
    end

    # Select a skill from available skills
    # @return [String, nil] Skill name or nil
    def self.select_skill
      'test-skill' # Placeholder
    end

    # Select a provider from available providers
    # @return [String, nil] Provider name or nil
    def self.select_provider
      'openai' # Placeholder
    end
  end
end
