# SkillBench Models

This directory contains the core data models for the Ruby Skill Bench tool.

## Structure
- `config.rb`: Configuration model for loading `.agent-eval.yml` (legacy format)
- `skill.rb`: Skill model for discovering and representing reusable skills
- `eval.rb`: Eval model for loading and representing evaluation scenarios
- `provider.rb`: Provider model for agent runtime + LLM abstraction

## Usage
All models follow single responsibility principle and are used by commands to execute evaluations.

## Testing
All models have corresponding tests in `test/` and follow TDD workflow.
