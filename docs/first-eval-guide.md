# SkillBench - 5 Minute First Eval Guide

Get started with Ruby Skill Bench in 5 minutes.

## Prerequisites
- Ruby 3.1+
- Bundler

## Step 1: Installation

Add to your Gemfile:
```ruby
gem 'ruby-skill-bench'
```

Or install globally:
```bash
gem install ruby-skill-bench
```

## Step 2: Initialize Configuration

```bash
skill-bench init --openai
```

This creates `skill-bench.json` with the OpenAI provider config. Use `--force` to overwrite.

**Available providers:** `--openai`, `--anthropic`, `--gemini`, `--ollama`, `--azure`, `--groq`, `--deepseek`, `--opencode`

## Step 3: Create Your First Skill

```bash
skill-bench skill new my-service --mode=rails --template=service_object
```

This creates `skills/my-service/SKILL.md` with a Rails service object template.

## Step 4: Create an Eval

```bash
skill-bench eval new my-first-eval --runtime=rails
```

This creates `evals/my-first-eval/` with `task.md` and `criteria.json`.

Edit `evals/my-first-eval/task.md` to define your evaluation task.

## Step 5: Run the Eval

```bash
skill-bench run my-first-eval --skill=my-service
```

Provider is read from `skill-bench.json` — no `--provider` flag needed.

**Available Providers (configured via `skill-bench init`):**
- `openai` — OpenAI GPT models
- `anthropic` — Anthropic Claude
- `gemini` — Google Gemini
- `azure` — Azure OpenAI
- `ollama` — Local Ollama models
- `groq` — Groq fast inference
- `deepseek` — DeepSeek models
- `opencode` — OpenCode platform

## Step 6: Check Results

The output shows:
- Eval name, skill used, provider
- Pass/fail status
- Score

For JSON output:
```bash
skill-bench run my-first-eval --skill=my-service --format json
```

For JUnit XML output:
```bash
skill-bench run my-first-eval --skill=my-service --format junit
```

## Next Steps

- Explore skill templates with `skill-bench skill new --help`
- Read `docs/architecture.md` for architecture details