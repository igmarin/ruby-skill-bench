# frozen_string_literal: true

# AgentEval provides tools for evaluating AI agent performance using structured skills and evals
module AgentEval
  # Models module for data structures and configuration
  module Models
  end

  # Commands module for CLI operations
  module Commands
  end

  # Services module for internal logic
  module Services
  end

  # Runtimes module for provider execution
  module Runtimes
  end

  # Rails module for Rails-specific integrations
  module Rails
  end

  # Migration module for data migrations
  module Migration
  end
end

require_relative 'agent_eval/models/config'
require_relative 'agent_eval/models/skill'
require_relative 'agent_eval/models/eval'
require_relative 'agent_eval/models/provider'
require_relative 'agent_eval/commands/init'
require_relative 'agent_eval/commands/skill_new'
require_relative 'agent_eval/commands/eval_new'
require_relative 'agent_eval/commands/run'
require_relative 'agent_eval/services/runner_service'
require_relative 'agent_eval/services/scoring_service'
require_relative 'agent_eval/output_formatter'
require_relative 'agent_eval/rails/skill_templates'
require_relative 'agent_eval/migration/provider_migrator'
