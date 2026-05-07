# Agent Eval Migration

This directory contains migration scripts for the Agent Eval tool.

## Structure
- `provider_migrator.rb`: Migrates old provider classes to new YAML-based configuration

## Usage
The migration scripts are used to upgrade from the old code-level provider configuration to the new YAML-based system.

## Available Migrators
- `AgentEval::Migration::ProviderMigrator.migrate(providers, yaml_path)` - Migrate providers to YAML config

## Testing
All classes follow TDD workflow (RED-GREEN-REFACTOR) and include YARD documentation.
