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

```text
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
- List acceptance criteria as numbered items (the judge checks these).

**Example — Good task.md:**

```markdown
Create a `PasswordValidator` class that:

1. Accepts a `password` string
2. Validates minimum length of 8 characters
3. Validates presence of at least one uppercase letter
4. Validates presence of at least one digit
5. Returns `{ valid: true }` or `{ valid: false, errors: [...] }`
6. Includes RSpec tests with 100% branch coverage
7. Uses `# frozen_string_literal: true`
8. Has YARD docs for the class and all public methods
```

**Why this works:** Each numbered item is a discrete acceptance criterion the judge can verify independently. Vague tasks like "create a password validator" produce inconsistent scores because the judge has to guess what "good" means.

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

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `context` | string | Yes | Shown to the judge. Describes what the eval measures. |
| `dimensions` | array | Yes | Array of `{ name, max_score }` objects. Must include all 5 core dimensions. `max_score` values must sum to exactly 100. |
| `pass_threshold` | integer | No | Minimum context score to pass. Default: 70. |
| `minimum_delta` | integer | No | Minimum improvement over baseline to pass. Default: 10. |
| `description` (per dimension) | string | No | Overrides the built-in default description for that dimension. |

**Custom dimension descriptions** are especially useful when a skill has specific hard rules. For example, if your skill requires the `.call` pattern, you can tell the judge exactly what to look for:

```json
{
  "name": "skill_adherence",
  "max_score": 25,
  "description": "Did the agent create a class with a `.call` class method that returns `{ success: bool, response: { ... } }`?"
}
```

This produces more consistent scores than the generic default description.

### 3. What the Judge Sees

Understanding the judge prompt helps you write better tasks and criteria. The judge receives a structured prompt with four sections:

```text
## Task
[Contents of task.md]

## Criteria
Context: [Contents of criteria.json context]
Dimensions:
- correctness: max_score=30, description=...
- skill_adherence: max_score=25, description=...
...

## Skill Context
[Contents of SKILL.md wrapped in XML]

## Agent Output
[Git diff + file listing + reasoning excerpt]

## Instructions
Score each dimension independently. Return JSON with:
- "dimensions": object mapping each dimension name to { "score": number, "max_score": number, "reasoning": string }
- "overall_reasoning": string summarizing the evaluation
```

**Important:** The judge is called **twice** per eval — once for baseline output (no skill context section) and once for context output (with skill context). The judge never sees both outputs in the same call. This prevents the judge from being biased by direct comparison.

---

## Evaluating Workflows vs. Skills

### Atomic Skills

Skills are isolated blocks of logic (e.g., a specific API pattern). Evaluations for skills should focus strictly on the adherence to the patterns defined in the skill's `SKILL.md`.

**Recommended weights for atomic skills:**

```json
{
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 30 },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 10 },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

Skill Adherence is weighted highest because the core question is "did the skill help?"

### Workflows

Workflows are sequences of skills or complex orchestrations (e.g., the full TDD loop). Evaluations for workflows should focus on the process, the ordering of tasks, and the successful completion of a multi-step objective.

**Recommended weights for workflows:**

```json
{
  "dimensions": [
    { "name": "correctness", "max_score": 35 },
    { "name": "skill_adherence", "max_score": 20 },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15 },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 65,
  "minimum_delta": 15
}
```

Correctness is weighted higher because workflows are judged on end-to-end success. The `minimum_delta` is also higher (15 vs 10) because workflows are expected to show stronger skill impact.

---

## Interpreting the Output

### Human-Readable Format

```text
═══════════════════════════════════════════════════════
  Eval: my-eval
  Skill: my-skill
  Provider: openai
═══════════════════════════════════════════════════════

  DIMENSION                BASELINE   CONTEXT    DELTA
  ──────────────────────── ───────── ───────── ───────
  Correctness (30)                12        28     +16
  Skill Adherence (25)             5        22     +17
  Code Quality (20)               10        16      +6
  Test Coverage (15)               3        13     +10
  Documentation (10)               2         8      +6
  ──────────────────────── ───────── ───────── ───────
  TOTAL                          32/100    87/100   +55

  TREND: baseline ↑ (+2), context ↑ (+7)
  VERDICT: PASS (threshold: 70, minimum delta: 10)
═══════════════════════════════════════════════════════
```

**Reading the table:**

- **BASELINE:** What the agent produced *without* the skill. Think of this as "raw" ability.
- **CONTEXT:** What the agent produced *with* the skill. Think of this as "aided" ability.
- **DELTA:** The improvement. `+16` means the skill added 16 points to that dimension.
- **TOTAL:** Sum of all dimension scores. The `/100` reminds you of the maximum.

**Verdict logic:**

```ruby
pass = context_total >= pass_threshold && total_delta >= minimum_delta
```

Both must be true. This prevents two failure modes:

1. **High absolute, no improvement:** baseline=80, context=80, delta=0 → FAIL (skill didn't help)
2. **Low absolute, small improvement:** baseline=10, context=20, delta=10 → FAIL (still terrible)

**TREND line:**

```text
TREND: baseline ↑ (+2), context ↑ (+7)
```

This compares the current run against the **previous run of the same eval + skill** (stored in `.skill-bench-trends.json`).

- `↑` = improved since last run
- `↓` = regressed since last run
- `→` = unchanged

The numbers in parentheses are the point differences. This helps you track whether your skill is getting better over time.

### JSON Format

```bash
skill-bench run my-eval --skill=my-skill --format json
```

Returns a structured hash with:

- `eval_name`, `skill_name`, `provider_name`
- `report` containing: `verdict`, `baseline_total`, `context_total`, `deltas`, `baseline_scores`, `context_scores`, `criteria`
- `trend` (if history exists): `baseline_trend`, `context_trend`, `baseline_delta`, `context_delta`, `previous_run`

Useful for CI/CD pipelines and automated reporting.

### JUnit XML Format

```bash
skill-bench run my-eval --skill=my-skill --format junit
```

Returns standard JUnit XML. Useful for GitHub Actions, Jenkins, and other CI systems that parse JUnit reports.

---

## Running the Test Suite

The project uses Minitest with 440+ tests covering:

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
