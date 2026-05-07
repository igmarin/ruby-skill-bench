# SkillBench Commands

This directory contains the CLI command implementations for the Ruby Skill Bench tool.

## Structure
- `init.rb`: Implements `skill-bench init` command for config generation
- `skill_new.rb`: Implements `skill-bench skill new` command for skill scaffolding
- `eval_new.rb`: Implements `skill-bench eval new` command for eval scaffolding
- `run.rb`: Implements `skill-bench run` command for executing evaluations

## Usage
Commands are called by the CLI entry point and follow service object pattern with `.run` class methods.

## Testing
All commands have corresponding tests in `test/` and follow TDD workflow.
