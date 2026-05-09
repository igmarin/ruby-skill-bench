# Evaluation Engine Redesign — v0.2.0

**Status:** Planning Complete — Awaiting Implementation

## Problem Statement

The current evaluation produces meaningless output: every run shows `PASS (score: 0.8)` because `ScoringService` always computes `1.0×0.5 + 1.0×0.3 + 1.0×0.2 = 1.0` (all metrics default to perfect when data is missing). There is no baseline comparison, no per-dimension insight, and no evidence that the skill influenced the result.

The core thesis of this tool is: **skills with their full resources produce better results than without them.** The current engine cannot prove or measure this.

---

## Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Execution modes | Always run both baseline (no skill) and context (with skill) |
| 2 | Scoring method | LLM judge scores each dimension independently |
| 3 | Judging approach | Blind judging — score baseline and context in separate calls, compute deltas |
| 4 | Canonical dimensions | Correctness, Skill Adherence, Code Quality, Test Coverage, Documentation |
| 5 | Dimension weights | Eval authors set `max_score` per dimension (must sum to 100) |
| 6 | Dimension descriptions | Built-in defaults with optional override in `criteria.json` |
| 7 | Pass/fail logic | Context score ≥ `pass_threshold` AND delta ≥ `minimum_delta` |
| 8 | `minimum_delta` | Configurable per eval, default 10 |
| 9 | Skill context delivery | All text-readable files from skill directory (.md, .rb, .json, .yml, .yaml, .txt), max 50KB per file |
| 10 | Judge output format | New structured JSON — no backward compatibility |
| 11 | Agent output for judge | Git diff + structured summary (files changed, commands run, agent reasoning) |
| 12 | Dimensions architecture | First-class `Dimension` objects — easy to add new ones without touching scoring logic |
| 13 | Phase 2 extensibility | Mandatory core dimensions + eval-specific custom additions |
| 14 | Eval author control | Weights, `minimum_delta`, `pass_threshold`, optional dimension description overrides |

---

## New `criteria.json` Format

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

Optional per-dimension description override:
```json
{ "name": "skill_adherence", "max_score": 25, "description": "Did the agent follow the .call pattern and response contract from the skill?" }
```

If `description` is omitted, the built-in default for that dimension is used.

---

## Judge Prompt Structure

The judge is called **twice per eval** — once for baseline output, once for context output (blind judging).

Each call receives:

1. **Task** — `task.md` content
2. **Criteria** — the full `criteria.json` with dimension names, descriptions, and max_scores
3. **Skill context** — all text-readable files from the skill directory, wrapped in `<agent_context>` XML
4. **Agent output** — git diff + structured summary (files changed, commands run, agent reasoning excerpt)

Each call returns:

```json
{
  "dimensions": {
    "correctness": { "score": 28, "max_score": 30, "reasoning": "..." },
    "skill_adherence": { "score": 22, "max_score": 25, "reasoning": "..." },
    "code_quality": { "score": 16, "max_score": 20, "reasoning": "..." },
    "test_coverage": { "score": 13, "max_score": 15, "reasoning": "..." },
    "documentation": { "score": 8, "max_score": 10, "reasoning": "..." }
  },
  "overall_reasoning": "..."
}
```

---

## Output Format

### Human-readable (default)

```
═══════════════════════════════════════════════════════
  Eval: skill-api-rest-collection
  Skill: skills/api/api-rest-collection
  Provider: opencode
═══════════════════════════════════════════════════════

  DIMENSION           BASELINE  CONTEXT   DELTA
  ─────────────────── ────────  ────────  ──────
  Correctness (30)        12       28      +16
  Skill Adherence (25)     5       22      +17
  Code Quality (20)        10       16       +6
  Test Coverage (15)        3       13      +10
  Documentation (10)       2        8       +6
  ─────────────────── ────────  ────────  ──────
  TOTAL                  32/100   87/100   +55

  VERDICT: PASS (threshold: 70, minimum delta: 10)
═══════════════════════════════════════════════════════
```

### JSON (`--format json`)

Full structured data including per-dimension reasoning, overall reasoning, both raw judge responses, and verdict.

---

## Architecture

### New Classes

| Class | Responsibility |
|-------|---------------|
| `Dimension` | Value object: `name`, `description`, `max_score`. Built-in defaults in `DEFAULT_DIMENSIONS` constant. Easy to add new dimensions without touching scoring logic. |
| `Criteria` | Loads `criteria.json`, validates dimension sum = 100, merges eval overrides with built-in default descriptions |
| `JudgePrompt` | Builds the structured prompt for the LLM judge with task, criteria, skill context, and agent output |
| `JudgeResponse` | Parses and validates the judge's per-dimension JSON response |
| `EvaluationRunner` | Orchestrates: baseline run → context run → blind judge both → compute deltas |
| `AgentSummary` | Captures files changed, commands run, agent reasoning from sandbox execution |
| `DeltaReport` | Computes baseline vs context deltas per dimension, determines verdict (pass_threshold + minimum_delta) |

### Modified Classes

| Class | Change |
|-------|--------|
| `RunnerService` | Rewired — calls `EvaluationRunner` instead of single `spawn_agent` + `ScoringService` |
| `Judge` | Rewritten — accepts `JudgePrompt` and returns `JudgeResponse` with per-dimension scores |
| `JudgeScoreParserService` | Rewritten — parses new dimension-based JSON format |
| `OutputFormatter` | New table format with baseline/context/delta columns |
| `ContextHydrator` | Extended — loads all text-readable files (.md, .rb, .json, .yml, .yaml, .txt), not just `.md`. Max 50KB per file. |
| `Models::Eval` | Updated — loads new `criteria.json` format into `Criteria` object |

### Deleted Classes

| Class | Reason |
|-------|--------|
| `ScoringService` | Replaced by `DeltaReport` — deterministic composite scoring is no longer meaningful |

### Well-known Default Dimensions

```ruby
# lib/skill_bench/dimensions.rb
module SkillBench
  DEFAULT_DIMENSIONS = [
    Dimension.new(name: "correctness",      description: "Does the output fulfill the task requirements? Are all specified behaviors present and correct?", max_score: nil),
    Dimension.new(name: "skill_adherence",  description: "Did the agent follow the specific patterns, hard gates, and workflows defined in the skill?", max_score: nil),
    Dimension.new(name: "code_quality",      description: "Is the code clean, well-structured, free of smells, follows SRP, and avoids duplication?", max_score: nil),
    Dimension.new(name: "test_coverage",     description: "Are there meaningful tests? Do they test the right things? Are they following TDD/best practices from the skill?", max_score: nil),
    Dimension.new(name: "documentation",      description: "Is there adequate YARD documentation, clear intent, and helpful inline comments where needed?", max_score: nil),
  ].freeze
end
```

`max_score` is `nil` in defaults — the eval's `criteria.json` sets the weights.

---

## Hard Process Rules

These are **non-negotiable** for every implementation task:

1. **TDD**: Write failing test first, then implement. No exceptions.
2. **Service Object pattern**: Classes use `.call` class method as entry point.
3. **SRP**: Each class has one responsibility. Each method does one thing.
4. **Code review**: Self-review before marking task complete.
5. **YARD documentation**: Every public method gets `@param`, `@return`, `@raise` tags.
6. **Tests pass**: Full suite green before moving on.
7. **`rubocop -A`**: Run and fix all offenses.
8. **`reek`**: Run and fix all warnings. If a warning makes no sense for the context, add it to `.reek.yml` — **never inline reek exclusions**.
9. **User review checkpoint**: After ALL tasks in a phase are complete, user reviews and gives OK before continuing to the next phase.

---

## Implementation Checklist

### Phase 1: Foundation

- [ ] 1.0 Create feature branch `feature/evaluation-engine-v2`
- [ ] 1.1 Create `Dimension` value object with `name`, `description`, `max_score` and `DEFAULT_DIMENSIONS` constant
  - [ ] 1.1a Write test for `Dimension` (initialization, equality, defaults)
  - [ ] 1.1b Implement `Dimension`
  - [ ] 1.1c Run tests, rubocop -A, reek
  - [ ] 1.1d Add YARD docs
- [ ] 1.2 Create `Criteria` loader/validator for new `criteria.json` format
  - [ ] 1.2a Write test for `Criteria` (load JSON, validate sum=100, merge defaults with overrides)
  - [ ] 1.2b Implement `Criteria`
  - [ ] 1.2c Run tests, rubocop -A, reek
  - [ ] 1.2d Add YARD docs
- [ ] 1.3 Create `JudgeResponse` parser for per-dimension JSON
  - [ ] 1.3a Write test for `JudgeResponse` (parse valid JSON, reject invalid, handle edge cases)
  - [ ] 1.3b Implement `JudgeResponse`
  - [ ] 1.3c Run tests, rubocop -A, reek
  - [ ] 1.3d Add YARD docs
- [ ] 1.4 Create `JudgePrompt` that builds structured judge prompts
  - [ ] 1.4a Write test for `JudgePrompt` (includes task, criteria, skill context, agent output)
  - [ ] 1.4b Implement `JudgePrompt`
  - [ ] 1.4c Run tests, rubocop -A, reek
  - [ ] 1.4d Add YARD docs
- [ ] 1.5 Create `AgentSummary` to capture sandbox execution metadata
  - [ ] 1.5a Write test for `AgentSummary` (files changed, commands run, reasoning extraction)
  - [ ] 1.5b Implement `AgentSummary`
  - [ ] 1.5c Run tests, rubocop -A, reek
  - [ ] 1.5d Add YARD docs
- [ ] 1.6 Extend `ContextHydrator` to load all text-readable files (not just .md)
  - [ ] 1.6a Write test for extended file loading (.rb, .json, .yml, etc., 50KB limit)
  - [ ] 1.6b Implement changes to `ContextHydrator`
  - [ ] 1.6c Run tests, rubocop -A, reek
  - [ ] 1.6d Add YARD docs
- [ ] 1.7 Rewrite `Judge` to use `JudgePrompt` and return `JudgeResponse`
  - [ ] 1.7a Write test for new `Judge` (builds prompt, calls LLM, parses response)
  - [ ] 1.7b Implement new `Judge`
  - [ ] 1.7c Run tests, rubocop -A, reek
  - [ ] 1.7d Add YARD docs
- [ ] 1.8 Create `DeltaReport` for delta computation and verdict logic
  - [ ] 1.8a Write test for `DeltaReport` (compute deltas, pass_threshold, minimum_delta)
  - [ ] 1.8b Implement `DeltaReport`
  - [ ] 1.8c Run tests, rubocop -A, reek
  - [ ] 1.8d Add YARD docs
- [ ] 1.9 Create `EvaluationRunner` orchestration service
  - [ ] 1.9a Write test for `EvaluationRunner` (baseline run → context run → blind judge both → deltas)
  - [ ] 1.9b Implement `EvaluationRunner`
  - [ ] 1.9c Run tests, rubocop -A, reek
  - [ ] 1.9d Add YARD docs
- [ ] 1.10 Rewrite `RunnerService` to call `EvaluationRunner`
  - [ ] 1.10a Update existing tests for `RunnerService`
  - [ ] 1.10b Implement changes to `RunnerService`
  - [ ] 1.10c Run tests, rubocop -A, reek
  - [ ] 1.10d Add YARD docs
- [ ] 1.11 Update `OutputFormatter` with new table format
  - [ ] 1.11a Write test for new formatter (dimension table, deltas, verdict)
  - [ ] 1.11b Implement new `OutputFormatter` format
  - [ ] 1.11c Run tests, rubocop -A, reek
  - [ ] 1.11d Add YARD docs
- [ ] 1.12 Update `Models::Eval` to load new `criteria.json` format
  - [ ] 1.12a Write test for new eval loading
  - [ ] 1.12b Implement changes to `Eval` model
  - [ ] 1.12c Run tests, rubocop -A, reek
  - [ ] 1.12d Add YARD docs
- [ ] 1.13 Delete `ScoringService` and update all references
  - [ ] 1.13a Remove `ScoringService` and its tests
  - [ ] 1.13b Update `RunnerService` and any other references
  - [ ] 1.13c Run full test suite, rubocop -A, reek
- [ ] 1.14 Update example evals to new `criteria.json` format
  - [ ] 1.14a Convert `examples/evals/` to new format
  - [ ] 1.14b Convert `evals/new/` template to new format
  - [ ] 1.14c Run tests
- [ ] 1.15 Integration test: full eval run end-to-end
  - [ ] 1.15a Write integration test
  - [ ] 1.15b Verify pass
- [ ] 1.16 Update documentation (README, docs/architecture.md, docs/testing-guide.md)
  - [ ] 1.16a Update README with new output format and criteria.json format
  - [ ] 1.16b Update architecture doc with new class diagram
  - [ ] 1.16c Update testing guide with new eval format
- [ ] **Checkpoint: User review and OK before Phase 2**

### Phase 2: Extensibility (future)

- [ ] 2.0 Custom dimensions per eval (mandatory core + additions)
- [ ] 2.1 Skill chaining (related skills boost score)
- [ ] 2.2 Historical benchmarking (track score improvements over time)
- [ ] 2.3 Eval generator (auto-generate evals from skill instructions)

---

## Relevant Files (Current)

- `lib/skill_bench/services/scoring_service.rb` — To be deleted
- `lib/skill_bench/services/runner_service.rb` — To be rewired
- `lib/skill_bench/judge.rb` — To be rewritten
- `lib/skill_bench/services/judge_score_parser_service.rb` — To be rewritten
- `lib/skill_bench/output_formatter.rb` — To be updated
- `lib/skill_bench/context_hydrator.rb` — To be extended
- `lib/skill_bench/models/eval.rb` — To be updated
- `lib/skill_bench/runner.rb` — May need updates
- `lib/skill_bench/task_evaluator.rb` — May need updates
- `lib/skill_bench/agent_runner.rb` — May need updates
- `test/services/scoring_service_test.rb` — To be deleted
- `test/` — All related tests to be updated
- `.reek.yml` — May need new exclusions
- `examples/evals/` — To be converted to new criteria format
- `evals/new/` — Template to be converted

---

## New Files to Create

- `lib/skill_bench/dimension.rb`
- `lib/skill_bench/criteria.rb`
- `lib/skill_bench/judge_prompt.rb`
- `lib/skill_bench/judge_response.rb`
- `lib/skill_bench/evaluation_runner.rb`
- `lib/skill_bench/agent_summary.rb`
- `lib/skill_bench/delta_report.rb`
- `test/dimension_test.rb`
- `test/criteria_test.rb`
- `test/judge_prompt_test.rb`
- `test/judge_response_test.rb`
- `test/evaluation_runner_test.rb`
- `test/agent_summary_test.rb`
- `test/delta_report_test.rb`