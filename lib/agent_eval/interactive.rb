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
    # @raise [NotImplementedError] Raised when gum integration is not enabled
    def self.gum_choose
      raise NotImplementedError, 'Interactive selection not implemented; enable gum integration'
    end

    # Select an eval from available evals
    # @return [String, nil] Eval name or nil
    # @raise [NotImplementedError] Raised when gum integration is not enabled
    def self.select_eval
      raise NotImplementedError, 'Interactive selection not implemented; enable gum integration'
    end

    # Select a skill from available skills
    # @return [String, nil] Skill name or nil
    # @raise [NotImplementedError] Raised when gum integration is not enabled
    def self.select_skill
      raise NotImplementedError, 'Interactive selection not implemented; enable gum integration'
    end

    # Select a provider from available providers
    # @return [String, nil] Provider name or nil
    # @raise [NotImplementedError] Raised when gum integration is not enabled
    def self.select_provider
      raise NotImplementedError, 'Interactive selection not implemented; enable gum integration'
    end
  end
end
