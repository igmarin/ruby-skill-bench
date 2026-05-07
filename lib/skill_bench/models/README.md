# Agent Eval Models

This directory contains the core data models for the Agent Eval tool.

## Structure
- `config.rb`: Configuration model for loading `.agent-eval.yml`
- `skill.rb`: Skill model for discovering and representing reusable skills
- `eval.rb`: Eval model for loading and representing evaluation scenarios
- `provider.rb`: Provider model for agent runtime + LLM abstraction
- `provider_registry.rb`: Registry for managing multiple providers

## Usage
All models follow single responsibility principle and are used by commands to execute evaluations.

## Testing
All models have corresponding specs in `spec/models/` and follow TDD workflow.
