# SkillBench - 5 Minute First Eval Guide

Get started with Ruby Skill Bench in 5 minutes. No prior AI eval experience required.

---

## Prerequisites

- Ruby 3.1+
- Bundler

Not sure? Run:

```bash
ruby --version   # Should be 3.1 or higher
bundle --version # Should print a version number
```

---

## Step 1: Installation

Add to your Gemfile:

```ruby
gem 'ruby-skill-bench'
```

Or install globally:

```bash
gem install ruby-skill-bench
```

---

## Step 2: Initialize Configuration

```bash
skill-bench init --openai
```

This creates `skill-bench.json` with the OpenAI provider config. Use `--force` to overwrite.

**Available providers:** `--openai`, `--anthropic`, `--gemini`, `--ollama`, `--azure`, `--groq`, `--deepseek`, `--opencode`

> **What is `skill-bench.json`?** This is your config file. It stores your API key, chosen LLM model, timeout, and allowed shell commands. Think of it as `.env` but structured as JSON. You edit it; SkillBench reads it.

---

## Step 3: Create Your First Skill

```bash
skill-bench skill new my-service --mode=rails --template=service_object
```

This creates `skills/my-service/SKILL.md` with a Rails service object template.

**What is a skill?** A skill is a set of instructions (written in Markdown) that you want the AI agent to follow. It is like a style guide or a cheat sheet. The agent reads it before solving the task.

**What goes in `SKILL.md`:**
- What pattern the skill implements (e.g. "Service Object with `.call`")
- Hard rules the agent must follow
- Code examples
- Response format expectations

**Example `SKILL.md`:**

```markdown
# Service Object Skill

## Pattern

All service objects use the `.call` class method and return a standardized hash:

```ruby
{ success: true, response: { data: ... } }
```

## Hard Rules

1. Every `.rb` file begins with `# frozen_string_literal: true`
2. Every public method has YARD docs (`@param`, `@return`, `@raise`)
3. `rescue StandardError` blocks must log backtrace
```ruby

---

## Step 4: Create an Eval

You have two options.

### Option A — Manual (recommended for learning)

```bash
skill-bench eval new my-first-eval --runtime=rails
```

**Creates:**

```bash
evals/
└── my-first-eval/
    ├── task.md           # <- The prompt given to the agent
    └── criteria.json     # <- How the judge scores the result
```

#### What goes in `task.md`

This is the **user prompt** the agent receives. Be specific — the agent has no other context.

**Bad example (too vague):**

```markdown
Create a user service.
```

**Good example (specific requirements):**

```markdown
Create a `UserRegistrationService` that:

1. Accepts `email` and `password` parameters
2. Validates email format with a regex (must contain @ and a domain)
3. Validates password length (minimum 8 characters)
4. Returns `{ success: true, response: { user_id: ... } }` on success
5. Returns `{ success: false, response: { error: { message: ... } } }` on failure
6. Includes YARD documentation for every public method
7. Includes RSpec tests covering both success and failure paths
8. Follows the frozen_string_literal convention

Do not use ActiveRecord. Use plain Ruby objects.
```

#### What goes in `criteria.json`

This tells the judge how to score. The 5 core dimensions are mandatory.

**Minimal example (copy-paste ready):**

```json
{
  "context": "Evaluate service object creation skill",
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

**With custom descriptions (recommended):**

```json
{
  "context": "Evaluate service object creation skill",
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 25, "description": "Did the agent use the .call pattern and return the standardized hash?" },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15, "description": "Are there tests for both success and failure paths?" },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

**Key rules:**

- `max_score` values must sum to exactly 100
- All 5 core dimensions (`correctness`, `skill_adherence`, `code_quality`, `test_coverage`, `documentation`) are required
- `pass_threshold` = minimum context score to pass (0-100)
- `minimum_delta` = minimum improvement over baseline to pass

---

### Option B — Auto-Generated (from a skill)

If you already have a skill and want the LLM to design the eval for you:

```bash
skill-bench eval generate my-service --name my-first-eval
```

This reads `skills/my-service/SKILL.md` and generates both `task.md` and `criteria.json`. The output is immediately validated — if the generated `criteria.json` has invalid dimensions or doesn't sum to 100, you'll see an error and can fix it manually.

---

## Step 5: Run the Eval

```bash
skill-bench run my-first-eval --skill=my-service
```

Provider is read from `skill-bench.json` — no `--provider` flag needed.

**What happens behind the scenes:**

1. Agent runs **without** skill context → produces baseline output
2. Agent runs **with** skill context → produces context output
3. Judge scores both independently → per-dimension scores
4. Engine computes deltas → applies pass/fail logic
5. Result is recorded in `.skill-bench-history.json` for trend tracking

**Run with multiple skills:**

```bash
skill-bench run my-first-eval --skill=skill-a --skill=skill-b
```

Both skill contexts are concatenated. The judge evaluates whether the combined context improves results.

**Available Providers (configured via `skill-bench init`):**

- `openai` — OpenAI GPT models
- `anthropic` — Anthropic Claude
- `gemini` — Google Gemini
- `azure` — Azure OpenAI
- `ollama` — Local Ollama models
- `groq` — Groq fast inference
- `deepseek` — DeepSeek models
- `opencode` — OpenCode platform (**requires custom `base_url`**: OpenCode does not host a public LLM API. Provide your own OpenAI-compatible endpoint via `config.base_url`)

---

## Step 6: Check Results

**Human-readable output (default):**

```text
═══════════════════════════════════════════════════════
  Eval: my-first-eval
  Skill: my-service
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

**Column meanings:**

| Column | Meaning |
|--------|---------|
| **BASELINE** | Score without skill (unaided performance). Think: "How well does the AI do on its own?" |
| **CONTEXT** | Score with skill (aided performance). Think: "How well does the AI do when it reads my skill?" |
| **DELTA** | Improvement = CONTEXT - BASELINE. Think: "How many points did my skill add?" |
| **TREND** | Change since the *previous* run of this exact eval + skill. Stored in `.skill-bench-history.json`. |
| **VERDICT** | PASS only if CONTEXT >= threshold AND DELTA >= minimum_delta. Both must be true. |

**Why both conditions for PASS?**

- `pass_threshold` alone would pass even if the skill didn't help (e.g. baseline=80, context=80, delta=0).
- `minimum_delta` alone would pass even if the absolute score is terrible (e.g. baseline=10, context=20, delta=10).
- Both together ensure the skill is **both effective and meaningful**.

**The four possible outcomes:**

| Context Score | Delta | Verdict | What it means |
|---------------|-------|---------|---------------|
| 87 | +55 | **PASS** | Skill helped a lot. Context >= 70 **and** delta >= 10. |
| 87 | -2 | **FAIL** | Skill made things **worse**. Context >= 70 **but** delta < 10. |
| 65 | +15 | **FAIL** | Skill helped, but not enough. Delta >= 10 **but** context < 70. |
| 65 | +5 | **FAIL** | Skill didn't help enough. Both conditions failed. |

**Most common surprise: negative delta**

If baseline=89 and context=87, your skill confused the agent. The agent scored higher *without* reading your skill. This usually means:

1. **Skill is too long** — the agent fixates on following the skill and ignores the actual task
2. **Skill contradicts the task** — e.g., skill says "use Service Objects" but task says "write a script"
3. **Over-engineering** — skill adds boilerplate (factories, decorators) that the judge penalizes as unnecessary

**Fix:** Remove rules that don't directly improve the weakest dimension. Measure: look at the dimension with the smallest (or most negative) delta. Delete or rewrite rules targeting that dimension.

**JSON output:**

```bash
skill-bench run my-first-eval --skill=my-service --format json
```

**JUnit XML output:**

```bash
skill-bench run my-first-eval --skill=my-service --format junit
```

---

## Step 7: Iterate and Improve

Your first run probably will not pass. That is normal. Here is how to improve.

### Use the History File

After each run, SkillBench appends to `.skill-bench-history.json`. You can read it to track progress:

```bash
cat .skill-bench-history.json | jq '.[-1]'
```

Look at the dimension with the **smallest delta**. That is where your skill is weakest. Open `SKILL.md` and add a concrete rule targeting that dimension.

### Example Iteration

**Run 1:** Test Coverage delta is only `+3`.

**Action:** Add to `SKILL.md`:

```markdown
## Testing Rules

Every service must have RSpec tests with:
- One test for the happy path (valid input succeeds)
- One test for the error path (invalid input returns errors)
- Use `describe`, `context`, and `it` blocks
```

**Run 2:** Test Coverage delta jumps to `+10`. TREND line shows `context ↑ (+5)`.

**Repeat** until the eval passes consistently and deltas are stable.

---

## Understanding the Files on Disk

SkillBench manages three files you should know about:

### `skill-bench.json` — Your Configuration (You Edit This)

Created by `skill-bench init`. Stores provider, API key, model, timeout, and allowed commands. You edit this file by hand or with the CLI.

```json
{
  "provider": "openai",
  "max_execution_time": 300,
  "allowed_commands": ["rspec", "bundle", "ruby", "git"],
  "config": {
    "api_key": "sk-...",
    "model": "gpt-4o"
  }
}
```

### `.skill-bench-history.json` — Evaluation History (Auto-Generated)

A JSON array recording every successful eval run. SkillBench writes it automatically. It stores timestamps, eval names, skill names, scores, and deltas. This powers the **TREND** line in your output.

```json
[
  {
    "timestamp": "2026-05-12T10:30:00Z",
    "eval_name": "my-first-eval",
    "skill_names": ["my-service"],
    "verdict": true,
    "baseline_total": 32,
    "context_total": 87,
    "deltas": { "correctness": 16, "skill_adherence": 17, ... }
  }
]
```

**Tip:** Commit this file to git if you want to share trend data with your team.

### `.skill-bench-history.json.bak` — Backup (Auto-Generated)

A safety copy of the history file. If the main file gets corrupted, SkillBench recovers from this backup automatically. You never need to touch it.

---

## Troubleshooting

### "Dimension max_scores must sum to 100"

Check your `criteria.json`. All `max_score` values must add up to exactly 100.

### "missing required core dimensions: documentation"

You are missing one of the 5 mandatory dimensions. All of these must be present: `correctness`, `skill_adherence`, `code_quality`, `test_coverage`, `documentation`.

### "Config load failed, using mock provider"

Run `skill-bench init --<provider>` to create `skill-bench.json`, or ensure it exists in the current directory.

### "Baseline agent failed" or "Context agent failed"

The LLM provider returned an error. Check your API key in `skill-bench.json` or environment variables.

### "Base URL not set for Opencode"

You selected `opencode` as provider but did not set a `base_url`. OpenCode does not host a public API. Either switch to a real provider (`openrouter`, `groq`, etc.) or set `config.base_url` to your own OpenAI-compatible proxy.

## Next Steps

- Explore skill templates with `skill-bench skill new --help`
- Read `docs/architecture.md` for the full component map
- Read `docs/testing-guide.md` for advanced eval authoring techniques
