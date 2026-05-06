# Agent Eval Commands

This directory contains the CLI command implementations for the Agent Eval tool.

## Structure
- `init.rb`: Implements `agent-eval init` command for config generation
- `skill_new.rb`: Implements `agent-eval skill new` command for skill scaffolding
- `eval_new.rb`: Implements `agent-eval eval new` command for eval scaffolding
- `run.rb`: Implements `agent-eval run` command for executing evaluations

## Usage
Commands are called by the CLI entry point and follow service object pattern with `.run` class methods.

## Testing
All commands have corresponding specs in `spec/commands/` and follow TDD workflow.
