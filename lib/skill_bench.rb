# frozen_string_literal: true

# Ruby Skill Bench - AI Agent Skills Evaluation Engine
#
# @example Basic usage
#   require 'skill_bench'
#   SkillBench::EvaluateCommand.call(ARGV)

# Core modules
require_relative 'skill_bench/version'
require_relative 'skill_bench/evaluate_command'
require_relative 'skill_bench/agent_runner'
require_relative 'skill_bench/judge'
require_relative 'skill_bench/sandbox'
require_relative 'skill_bench/output_formatter'
require_relative 'skill_bench/context_hydrator'
require_relative 'skill_bench/runner'
require_relative 'skill_bench/client'
require_relative 'skill_bench/react_agent'

# Clients
require_relative 'skill_bench/clients/all'

# Config management
require_relative 'skill_bench/config/store'
require_relative 'skill_bench/config/defaults'
require_relative 'skill_bench/config/applier'
require_relative 'skill_bench/config/env_overrides'
require_relative 'skill_bench/config/json_loader'
require_relative 'skill_bench/config/facade_readers'
require_relative 'skill_bench/config/facade_writers'

# Models
require_relative 'skill_bench/models/config'
require_relative 'skill_bench/models/eval'
require_relative 'skill_bench/models/skill'
require_relative 'skill_bench/models/provider'

# Commands
require_relative 'skill_bench/commands/init'
require_relative 'skill_bench/commands/run'
require_relative 'skill_bench/commands/skill_new'
require_relative 'skill_bench/commands/eval_new'

# Services
require_relative 'skill_bench/services/runner_service'
require_relative 'skill_bench/services/scoring_service'
require_relative 'skill_bench/services/result_printer_service'
require_relative 'skill_bench/services/option_parser_service'
require_relative 'skill_bench/services/judge_score_parser_service'
require_relative 'skill_bench/services/output_persistence_service'

# Tools
require_relative 'skill_bench/tools'

# History recording
require_relative 'skill_bench/history_recorder'
require_relative 'skill_bench/history_recorder/persistence_service'
require_relative 'skill_bench/history_recorder/summary_service'

# Rails integrations
require_relative 'skill_bench/rails/skill_templates'

# Migration utilities
require_relative 'skill_bench/migration/provider_migrator'

# Interactive mode
require_relative 'skill_bench/interactive'

# Package verification
require_relative 'skill_bench/package_verifier'

# Utility modules
require_relative 'skill_bench/error_logger'
require_relative 'skill_bench/task_evaluator'
require_relative 'skill_bench/task_file_reader'
require_relative 'skill_bench/source_path_resolver'
