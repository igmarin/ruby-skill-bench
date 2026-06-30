# frozen_string_literal: true

# Ruby Skill Bench - AI Agent Skills Evaluation Engine
#
# @example Basic usage
#   require 'skill_bench'
#   SkillBench::CLI.call(ARGV)

# Core modules
require_relative 'skill_bench/version'
require_relative 'skill_bench/constants'
require_relative 'skill_bench/dimension'
require_relative 'skill_bench/criteria'
require_relative 'skill_bench/delta_report'
require_relative 'skill_bench/cli'
require_relative 'skill_bench/config'
require_relative 'skill_bench/output_formatter'
require_relative 'skill_bench/client'

# Judge subsystem
require_relative 'skill_bench/judge'
require_relative 'skill_bench/judge/judge'
require_relative 'skill_bench/judge/prompt'
require_relative 'skill_bench/judge/response'

# Agent subsystem
require_relative 'skill_bench/agent'
require_relative 'skill_bench/agent/runner'
require_relative 'skill_bench/agent/summary'
require_relative 'skill_bench/agent/react_agent'

# Task subsystem
require_relative 'skill_bench/task'
require_relative 'skill_bench/task/evaluator'
require_relative 'skill_bench/task/file_reader'

# Evaluation orchestration
require_relative 'skill_bench/evaluation'
require_relative 'skill_bench/evaluation/runner'
require_relative 'skill_bench/evaluation/generator'

# Execution environment
require_relative 'skill_bench/execution'
require_relative 'skill_bench/execution/context_hydrator'
require_relative 'skill_bench/execution/sandbox'
require_relative 'skill_bench/execution/source_path_resolver'

# Clients
require_relative 'skill_bench/clients/all'
require_relative 'skill_bench/clients/provider_schemas'

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
require_relative 'skill_bench/models/criteria_validator'
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
require_relative 'skill_bench/services/batch_runner_service'
require_relative 'skill_bench/services/summary_formatter'
require_relative 'skill_bench/services/template_registry'

# Tools
require_relative 'skill_bench/tools'

# History recording
require_relative 'skill_bench/history_recorder'
require_relative 'skill_bench/history_recorder/persistence_service'
require_relative 'skill_bench/history_recorder/summary_service'

# Trend tracking
require_relative 'skill_bench/trend_tracker'
require_relative 'skill_bench/trend_tracker/persistence'
require_relative 'skill_bench/trend_tracker/trend_calculator'

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
