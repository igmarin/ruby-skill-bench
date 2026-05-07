# Agent Eval Rails Extensions

This directory contains Rails-specific extensions for the Agent Eval tool.

## Structure
- `skill_templates.rb`: Rails-specific skill templates (service objects, concerns, ActiveRecord models)

## Usage
These templates are used by the `agent-eval skill new` command when the `--rails` flag is used.

## Available Templates
- `AgentEval::Rails::SkillTemplates.service_object(name)` - Generate a service object template
- `AgentEval::Rails::SkillTemplates.concern(name)` - Generate a concern template
- `AgentEval::Rails::SkillTemplates.active_record_model(name)` - Generate an ActiveRecord model template

## Testing
All classes follow TDD workflow (RED-GREEN-REFACTOR) and include YARD documentation.
