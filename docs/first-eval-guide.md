# Agent Eval - 5 Minute First Eval Guide

Get started with Agent Eval in 5 minutes.

## Prerequisites
- Ruby 3.0+
- Bundler

## Step 1: Installation

Add to your Gemfile:
```ruby
gem 'agent-eval'
```

Or install globally:
```bash
gem install agent-eval
```

## Step 2: Initialize Configuration

```bash
agent-eval init --rails
```

This creates `.agent-eval.yml` with default providers and Rails-specific settings.

## Step 3: Create Your First Skill

```bash
agent-eval skill new my-service --mode=rails --template=service_object
```

This creates `skills/my-service/service.rb` with a Rails service object template.

## Step 4: Create an Eval

```bash
agent-eval eval new my-first-eval --runtime=rails
```

This creates `evals/my-first-eval/` with `task.md` and `criteria.json`.

Edit `evals/my-first-eval/task.md` to define your evaluation task.

## Step 5: Run the Eval

```bash
agent-eval run my-first-eval --skill=my-service --provider=openai
```

## Step 6: Check Results

The output shows:
- Eval name, skill used, provider
- Pass/fail status
- Score

For CI mode:
```bash
agent-eval run my-first-eval --skill=my-service --provider=openai --ci
```

This outputs JSON/JUnit XML for CI/CD integration.

## Next Steps

- Explore `lib/agent_eval/rails/skill_templates.rb` for more Rails templates
- Read `plans/agent-eval-architecture.md` for architecture details
- Run `agent-eval list skills|evals|providers` to see available resources
