# Testing Guide: Evaluations & Workflows

This guide explains how to run evaluations and how to create new evaluation tasks for skills and workflows.

## Running Evaluations

The primary tool for running evaluations is the `skill-bench` CLI.

### Basic Usage

To run a specific evaluation task:

```bash
skill-bench run my-eval --skill=my-skill
```

Provider is read from `skill-bench.json` — no `--provider` flag needed.

### Output Formats

**Human-readable (default):**
```
============================================================
Eval: my-eval
Skill: my-skill
Provider: openai
Status: PASSED
Score: 0.95
============================================================
```

**JSON:**
```bash
skill-bench run my-eval --skill=my-skill --format json
```

**JUnit XML:**
```bash
skill-bench run my-eval --skill=my-skill --format=junit
```

### Batch Processing

To run an eval with a path containing a slash:

```bash
skill-bench run evals/my-eval --skill=my-skill
```

The evaluator resolves the path automatically.

### Overriding Skill Context

By default, the evaluator infers the skill path from the evaluation path. If you need to test an evaluation against a different skill:

```bash
skill-bench run my-eval --skill=skills/custom-skill
```

## Creating New Evaluations

An evaluation task consists of a directory containing at least two files: `task.md` and `criteria.json`.

### 1. The Task (`task.md`)

This file contains the instructions for the AI agent. It should describe a specific problem to solve or a feature to implement.

**Best Practices:**
- Provide clear context and requirements.
- Include a description of the current codebase state.
- Specify the desired outcome.

### 2. The Criteria (`criteria.json`)

This file defines the grading thresholds:

```json
{
  "runtime": "rails",
  "pass": {
    "score_threshold": 0.8
  },
  "fail": {
    "score_threshold": 0.5
  }
}
```

**Fields:**
- `runtime`: Target runtime environment ("rails" or "generic")
- `pass.score_threshold`: Score needed to pass (default 0.8)
- `fail.score_threshold`: Score below which the eval is a clear failure (default 0.5)

## Evaluating Workflows vs. Skills

### Atomic Skills

Skills are isolated blocks of logic (e.g., a specific API pattern). Evaluations for skills should focus strictly on the adherence to the patterns defined in the skill's `SKILL.md`.

### Workflows

Workflows are sequences of skills or complex orchestrations (e.g., the full TDD loop). Evaluations for workflows should focus on the process, the ordering of tasks, and the successful completion of a multi-step objective.

When running a workflow evaluation, ensure the eval path points to a workflow eval directory such as `evals/workflows/`.

## Running the Test Suite

The project uses Minitest with 373+ tests covering:
- Core evaluation engine (`test/evaluator/`)
- CLI commands and models (`test/agent_eval/`)
- Provider clients (`test/clients/`)
- Skill services (`test/skills/`)

```bash
# Run all tests
bundle exec rake test

# Run with coverage report
bundle exec rake test COVERAGE=true

# Run specific test file
bundle exec ruby -Itest test/agent_eval/services/scoring_service_test.rb

# Run lint checks
bundle exec rake rubocop
bundle exec rake reek
```

### Test Isolation

Tests use temporary directories and restore the original working directory:
```ruby
def setup
  @original_dir = Dir.pwd
  @tmp_dir = Dir.mktmpdir('test')
  Dir.chdir(@tmp_dir)
end

def teardown
  Dir.chdir(@original_dir)
  FileUtils.rm_rf(@tmp_dir)
end
```

### Environment Variable Handling

Tests that modify ENV must restore original values:
```ruby
def test_something
  original_key = ENV.fetch('SKILL_BENCH_OPENAI_API_KEY', nil)
  ENV.delete('SKILL_BENCH_OPENAI_API_KEY')
  # ... test code ...
ensure
  ENV['SKILL_BENCH_OPENAI_API_KEY'] = original_key if original_key
end
```