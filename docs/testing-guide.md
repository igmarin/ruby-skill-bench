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
═══════════════════════════════════════════════════════
  Eval: my-eval
  Skill: my-skill
  Provider: openai
═══════════════════════════════════════════════════════

  DIMENSION                BASELINE   CONTEXT    DELTA
  ──────────────────────── ───────── ───────── ───────
  Correctness (30)                12        28    +16
  Skill Adherence (25)             5        22    +17
  Code Quality (20)               10        16     +6
  Test Coverage (15)               3        13    +10
  Documentation (10)               2         8     +6
  ──────────────────────── ───────── ───────── ───────
  TOTAL                          32/100    87/100   +55

  VERDICT: PASS (threshold: 70, minimum delta: 10)
═══════════════════════════════════════════════════════
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

This file defines the evaluation dimensions, weights, and thresholds:

```json
{
  "context": "Evaluate whether the skill helps build a proper API REST collection",
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 25 },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15 },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

**Fields:**
- `context`: Human-readable description of what the eval measures.
- `dimensions`: Array of dimension objects. Each must have `name` and `max_score`. `max_score` values must sum to exactly 100.
- `pass_threshold`: Minimum total context score to pass (default 70).
- `minimum_delta`: Minimum improvement over baseline required to pass (default 10).
- Optional per-dimension `description` overrides the built-in default.

## Evaluating Workflows vs. Skills

### Atomic Skills

Skills are isolated blocks of logic (e.g., a specific API pattern). Evaluations for skills should focus strictly on the adherence to the patterns defined in the skill's `SKILL.md`.

### Workflows

Workflows are sequences of skills or complex orchestrations (e.g., the full TDD loop). Evaluations for workflows should focus on the process, the ordering of tasks, and the successful completion of a multi-step objective.

When running a workflow evaluation, ensure the eval path points to a workflow eval directory such as `evals/workflows/`.

## Running the Test Suite

The project uses Minitest with 428+ tests covering:
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
bundle exec ruby -Itest test/integration_test.rb

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
