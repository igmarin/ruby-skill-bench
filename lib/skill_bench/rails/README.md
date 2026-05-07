# SkillBench Rails Extensions

This directory contains Rails-specific extensions for the Ruby Skill Bench tool.

## Structure
- `skill_templates.rb`: Rails-specific skill templates (service objects, concerns, ActiveRecord models)

## Usage
These templates are used by the `skill-bench skill new` command when the `--rails` flag is used.

## Available Templates
- `SkillBench::Rails::SkillTemplates.service_object(name)` — Generate a service object template
- `SkillBench::Rails::SkillTemplates.concern(name)` — Generate a concern template
- `SkillBench::Rails::SkillTemplates.active_record_model(name)` — Generate an ActiveRecord model template

## Testing
All classes follow TDD workflow (RED-GREEN-REFACTOR) and include YARD documentation.
