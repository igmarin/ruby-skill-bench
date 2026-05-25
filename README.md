# Ruby Skill Bench

![Ruby Skill Bench Logo](https://github.com/user-attachments/assets/056d7ca4-8671-41ec-9efb-e323b73fb135)


![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/igmarin/ruby-skill-bench?utm_source=oss&utm_medium=github&utm_campaign=igmarin%2Fruby-skill-bench&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

*A high-fidelity evaluation engine for benchmarking AI agent skills across any stack (Rails-first, but extensible).*

## Part of the AI Skill Ecosystem

This repo is one of 6 in a composable AI skill ecosystem:

| Repo | Role |
|------|------|
| [`ruby-core-skills`](https://github.com/igmarin/ruby-core-skills) | 15 shared Ruby skills + process discipline |
| [`rails-agent-skills`](https://github.com/igmarin/rails-agent-skills) | 28 Rails-specific skills + 9 agents |
| [`hanakai-yaku`](https://github.com/igmarin/hanakai-yaku) | 35 Hanami/dry-rb skills + 10 agents |
| [`agnostic-planning-skills`](https://github.com/igmarin/agnostic-planning-skills) | 10 planning skills + 4 agents |
| [`agent-mcp-runtime`](https://github.com/igmarin/agent-mcp-runtime) | Rust CLI runtime (pack resolution, MCP) |
| [**`ruby-skill-bench`**](https://github.com/igmarin/ruby-skill-bench) | Benchmark/eval engine |

See the [Ecosystem Overview](https://github.com/igmarin/agent-mcp-runtime/blob/main/docs/ecosystem.md) for the full architecture.

---

## Features

- **Side-by-Side Evaluation**: Quantify the "ROI of Context" by comparing baseline vs. skill-enhanced agent runs.
- **Isolated Git Sandboxes**: Every run operates in a temporary repo. Clean diffs, zero side-effects, 100% reproducibility.
- **Blind Judging with Dimensions**: LLM judge scores baseline and context independently across 5 canonical dimensions (Correctness, Skill Adherence, Code Quality, Test Coverage, Documentation). Eval authors configure weights and thresholds via `criteria.json`.
- **Sophisticated ReAct Loop**: Employs a robust `Thought → Tool → Observation` loop to handle complex, multi-step engineering tasks.
- **Multi-Provider Ecosystem**: Native support for **OpenAI**, **Anthropic**, **Google Gemini**, **Azure OpenAI**, **Ollama**, **Groq**, **DeepSeek**, and **OpenCode**.
- **Standardized Intelligence**: Consistent reporting format regardless of the underlying LLM provider.

---

## Architecture Overview

The system decoupling allows the reasoning engine to remain agnostic of the execution environment.

```text
CLI / API → RunnerService → Sandbox + ReAct Agent → LLM Client Layer → Provider
                                                              ↓
                                         EvaluationRunner (baseline + context)
                                                              ↓
                                                    Judge (blind scoring)
                                                              ↓
                                                    DeltaReport
```

---

## Configuration & Orchestration

### Environment Variable Mapping

| Provider | Required Env Variables | Registry Key |
| :--- | :--- | :--- |
| **OpenAI** | `SKILL_BENCH_OPENAI_API_KEY` | `:openai` |
| **Anthropic** | `SKILL_BENCH_ANTHROPIC_API_KEY` | `:anthropic` |
| **Gemini** | `SKILL_BENCH_GEMINI_API_KEY` | `:gemini` |
| **Azure** | `SKILL_BENCH_AZURE_API_KEY` | `:azure` |
| **Ollama** | — | `:ollama` |
| **Groq** | `SKILL_BENCH_GROQ_API_KEY` | `:groq` |
| **DeepSeek** | `SKILL_BENCH_DEEPSEEK_API_KEY` | `:deepseek` |
| **OpenCode** | `SKILL_BENCH_OPENCODE_API_KEY`, `SKILL_BENCH_OPENCODE_BASE_URL` | `:opencode` |

> **Note:** Environment variables are loaded automatically. You can also configure provider settings in `skill-bench.json` (created by `skill-bench init`).
>
> **OpenCode requires a custom `base_url`:** OpenCode does not host a public LLM API. You must provide your own OpenAI-compatible endpoint (e.g. a LiteLLM proxy, self-hosted vLLM, or company gateway) via the `base_url` config key. Without it, the provider will fail with "Base URL not set for Opencode".

### Command Allowlist

By default, no shell commands are permitted. You must configure `allowed_commands` in `skill-bench.json`:

```json
{
  "provider": "openai",
  "max_execution_time": 30,
  "allowed_commands": ["rspec", "bundle", "ruby", "git"],
  "config": {
    "api_key": null,
    "model": "gpt-4o"
  }
}
```

> **Security:** The agent can only execute commands on this list. Dangerous commands (bash, curl, sudo, etc.) are always blocked regardless of configuration.

### Configuration Hierarchy

Configuration is loaded in this order (later sources override earlier ones):

1. **Code defaults** — built-in defaults for provider, model, and timeout
2. **Home JSON** — `~/.skill-bench.json` for user-wide settings
3. **Local JSON** — `./skill-bench.json` for project-specific settings
4. **Environment variables** — provider API keys and models from `ENV`

---

## Getting Started

### Installation

```bash
gem install ruby-skill-bench
```

Or add to your `Gemfile`:

```ruby
gem 'ruby-skill-bench'
```

### Usage: The 4-Step Flow

Each command creates specific files. Here is exactly what lands on disk after each step.

#### 1. Initialize Configuration

```bash
skill-bench init --openai
```

**Creates:** `skill-bench.json` (provider configuration)

```json
{
  "provider": "openai",
  "max_execution_time": 30,
  "allowed_commands": ["rspec", "bundle", "ruby", "git"],
  "config": {
    "api_key": null,
    "model": "gpt-4o"
  }
}
```

**Available providers:** `--openai`, `--anthropic`, `--gemini`, `--ollama`, `--azure`, `--groq`, `--deepseek`, `--opencode`

Use `--force` to overwrite an existing config.

---

#### 2. Create a Skill

```bash
skill-bench skill new my-service --mode=rails --template=service_object
```

**Creates:**

```
skills/
└── my-service/
    └── SKILL.md          # <- Your skill instructions go here
```

`SKILL.md` is free-form Markdown. It typically contains:
- What pattern the skill implements (e.g., "Service Object with `.call`")
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
```

---

### Using TemplateRegistry for Rapid Eval Scaffolding

For programmatic eval creation, use `SkillBench::Services::TemplateRegistry` to generate scaffolding from pre-built templates. This is ideal for automating eval creation or building tools on top of SkillBench.

**Basic Usage:**

```ruby
require 'skill_bench'

# Generate a task template for a CRUD service
task_content = SkillBench::Services::TemplateRegistry.call(
  :task_md, 
  :crud, 
  skill_name: "UserCreator"
)

# Generate criteria JSON for an API client
criteria_content = SkillBench::Services::TemplateRegistry.call(:criteria_json, :api)

# Generate skill instructions for a background job
skill_content = SkillBench::Services::TemplateRegistry.call(
  :skill_md, 
  :background_job, 
  skill_name: "OrderProcessor"
)
```

**Available Template Types:**

| Type | Output | Purpose |
|------|--------|---------|
| `task_md` | Markdown | Agent prompt with requirements |
| `criteria_json` | JSON | Scoring rules and dimensions |
| `skill_md` | Markdown | Skill instructions for the agent |

**Supported Categories:**

| Category | Use Case |
|----------|----------|
| `crud` | Service Objects with Create, Read, Update, Delete |
| `api` | API clients with authentication and error handling |
| `background_job` | ActiveJob/Sidekiq workers with retry logic |
| `controller` | RESTful controllers with strong parameters |
| `model` | ActiveRecord models with validations |
| `migration` | Database migrations with indexes |
| `concern` | ActiveSupport::Concern modules |
| `policy` | Authorization policies (Pundit-style) |
| `form_object` | Form objects with validations |
| `view_component` | ViewComponent components with previews |

**Variable Interpolation:**

Templates support `{{variable_name}}` syntax for dynamic content:

```ruby
# Custom variables are interpolated into templates
task = SkillBench::Services::TemplateRegistry.call(
  :task_md, 
  :api, 
  skill_name: "PaymentGateway",
  endpoint: "/api/v1/payments"
)
```

**Complete Workflow Example:**

```ruby
require 'fileutils'
require 'skill_bench'

# Define your skill name
skill_name = "OrderService"

# Generate all eval scaffolding
task_md = SkillBench::Services::TemplateRegistry.call(:task_md, :crud, skill_name: skill_name)
criteria_json = SkillBench::Services::TemplateRegistry.call(:criteria_json, :crud)
skill_md = SkillBench::Services::TemplateRegistry.call(:skill_md, :crud, skill_name: skill_name)

# Write to disk
FileUtils.mkdir_p("evals/order-service")
File.write("evals/order-service/task.md", task_md)
File.write("evals/order-service/criteria.json", criteria_json)

FileUtils.mkdir_p("skills/order-service")
File.write("skills/order-service/SKILL.md", skill_md)

puts "Eval scaffolding created for #{skill_name}!"
```

> **Note:** `TemplateRegistry` is a pure function with no side effects. It returns template strings that you can customize before writing to disk.

---

#### 3. Create an Eval

You have two options: manual or auto-generated.

**Option A — Manual (full control):**

```bash
skill-bench eval new my-first-eval --runtime=rails
```

**Creates:**

```
evals/
└── my-first-eval/
    ├── task.md           # <- The task description for the agent
    └── criteria.json     # <- Scoring rules and dimension weights
```

**`task.md`** tells the agent what to build. Be specific — the agent receives this as its user prompt.

**Example `task.md`:**

```markdown
Create a `UserRegistrationService` that:

1. Accepts `email` and `password`
2. Validates email format with a regex
3. Validates password length (minimum 8 characters)
4. Returns `{ success: true, response: { user_id: ... } }` on success
5. Returns `{ success: false, response: { error: { message: ... } } }` on failure
6. Includes YARD documentation for every public method
7. Includes RSpec tests that cover both success and failure paths
```

**`criteria.json`** tells the judge how to score the agent's output. See the [Scoring Engine](#scoring-engine) section for the full format.

**Option B — Auto-Generated (from a skill):**

```bash
skill-bench eval generate my-service --name my-first-eval
```

Reads `skills/my-service/SKILL.md`, sends it to the LLM, and auto-generates `task.md` + `criteria.json`. The generated eval is immediately validated against the same rules as manual evals.

---

#### 4. Run the Eval

```bash
skill-bench run my-first-eval --skill=my-service
```

**What happens internally:**

1. **Resolve** — Load eval (`task.md` + `criteria.json`), skill (`SKILL.md`), and provider config
2. **Baseline run** — Agent receives `task.md` as a prompt, no skill context → produces output A
3. **Context run** — Agent receives `task.md` + `SKILL.md` as prompt → produces output B
4. **Blind judging** — LLM judge scores output A and output B independently across the dimensions defined in `criteria.json`
5. **Delta computation** — Compare scores, compute deltas, apply pass/fail logic
6. **History recording** — Store result in `.skill-bench-history.json` for trend tracking

Provider is read from `skill-bench.json` — no `--provider` flag needed.

**Run with multiple skills (skill chaining):**

```bash
skill-bench run my-first-eval --skill=skill-a --skill=skill-b
```

Both skill contexts are concatenated and sent to the agent. The judge evaluates whether the combined context improves results.

**Output Formats:**

- Human-readable (default)
- JSON: `--format json`
- JUnit XML: `--format junit`

---

## Multi-Repo Skill Benchmarking

Skills in the ecosystem are split across multiple repos:
- `ruby-core-skills` — 15 shared Ruby skills (DDD, patterns, process discipline)
- `rails-agent-skills` — 28 Rails-specific skills
- `hanakai-yaku` — 35 Hanami/dry-rb skills

To benchmark a skill from an external repo, use the `--skill` flag:

```bash
# Benchmark a core skill
skill-bench run evals/skills/write-yard-docs/basic \
  --skill /path/to/ruby-core-skills/skills/patterns/write-yard-docs

# Benchmark a Rails skill
skill-bench run evals/skills/code-review/pr-review \
  --skill /path/to/rails-agent-skills/skills/code-quality/code-review
```

### Config-Based Multi-Repo Resolution

Configure `skill_sources` in `skill-bench.json` to automatically resolve skills across repos without `--skill` every time:

```json
{
  "provider": "openai",
  "model": "gpt-4o",
  "skill_sources": {
    "core": "../ruby-core-skills/skills",
    "rails": "../rails-agent-skills/skills",
    "hanami": "../hanakai-yaku/skills"
  }
}
```

Each key is a source name (for logging), each value is a path to a `skills/` directory. When a skill is not found locally, SkillBench iterates through `skill_sources` and uses the first match.

### Pack-Based Resolution (`--pack`)

Resolve skills via the ecosystem registry manifest (from `agent-mcp-runtime`):

```bash
# Run an eval using the Rails pack's version of code-review
skill-bench run evals/skills/code-review/basic \
  --skill code-review \
  --pack rails

# Override the default registry manifest path
skill-bench run evals/skills/code-review/basic \
  --skill code-review \
  --pack rails \
  --registry-manifest /path/to/registry.json
```

### Variant Comparison (`compare`)

Compare the same skill across two pack variants to measure context-dependent performance:

```bash
skill-bench compare code-review \
  --variant-a "pack:rails" \
  --variant-b "pack:hanami" \
  --eval evals/skills/code-review/basic
```

The `--variant` spec supports two forms:
- `pack:<name>` — resolve via registry manifest
- `/absolute/path` or `relative/path` — use a direct path

---

## File Reference: What Lives on Disk

SkillBench creates and manages three files in your project. Understanding them helps you iterate faster.

### `skill-bench.json` — Your Configuration

**What it is:** The config file you create with `skill-bench init`. It tells SkillBench which LLM provider to use, your API key, timeout settings, and which shell commands the agent is allowed to run.

**Who edits it:** You. This is the only file SkillBench expects you to write by hand.

**Typical contents:**

```json
{
  "provider": "openai",
  "max_execution_time": 300,
  "allowed_commands": ["rspec", "bundle", "ruby", "git"],
  "config": {
    "api_key": "sk-...",
    "model": "gpt-4o",
    "max_iterations": 25
  }
}
```

**Key rules:**
- Configuration is loaded in this order: **code defaults** → `~/.skill-bench.json` (user-wide) → `./skill-bench.json` (local) → **environment variables**. Later sources override earlier ones.
- If `api_key` is `null`, SkillBench looks for the matching environment variable (e.g. `SKILL_BENCH_OPENAI_API_KEY`).
- `allowed_commands` is a **safeguard**, not a convenience. By default the agent cannot run *any* shell command. Add only what your evals need.

---

### `.skill-bench-history.json` — Evaluation History (Auto-Generated)

**What it is:** A JSON array that records every successful eval run. SkillBench appends to it automatically. It stores the timestamp, eval name, skill names, scores, and deltas so you can track improvement over time.

**Who edits it:** Nobody. SkillBench writes it; you read it. If you delete it, you lose your trend data.

**Example entry:**

```json
[
  {
    "timestamp": "2026-05-12T10:30:00Z",
    "eval_name": "my-first-eval",
    "skill_names": ["my-service"],
    "verdict": true,
    "baseline_total": 32,
    "context_total": 87,
    "deltas": {
      "correctness": 16,
      "skill_adherence": 17,
      "code_quality": 6,
      "test_coverage": 10,
      "documentation": 6
    }
  }
]
```

**Why it matters:** This file powers the **TREND** line you see in human-readable output:

```text
TREND: baseline ↑ (+2), context ↑ (+7)
```

The trend compares the current run against the *previous run of the same eval + skill*. This tells you at a glance whether your latest skill edit made things better or worse.

**Pro tip:** Commit `.skill-bench-history.json` to git if you want to share trend data with your team. Add it to `.gitignore` if you prefer to keep scores private.

---

### `.skill-bench-history.json.bak` — Backup (Auto-Generated)

**What it is:** A copy of `.skill-bench-history.json` created every time SkillBench writes a new entry. If the main file gets corrupted (e.g. you kill the process mid-write), SkillBench automatically falls back to the `.bak` file.

**Who edits it:** Nobody. It is a safety net.

**When to care:** Almost never. If you see a "History file corrupted" warning, SkillBench has already recovered from the `.bak` for you.

---

## Iterating on Skills: A Practical Workflow

Writing a good skill is rarely a one-shot process. Here is a tested workflow that uses the history file to guide your improvements.

### Step 1: Write a V1 Skill

Create a skill and an eval that exercises it:

```bash
skill-bench skill new my-service --mode=rails --template=service_object
skill-bench eval new my-first-eval --runtime=rails
# ... edit SKILL.md, task.md, and criteria.json ...
```

### Step 2: Run the Eval (Baseline + Context)

```bash
skill-bench run my-first-eval --skill=my-service
```

This executes the full evaluation pipeline: a **baseline run** (agent receives the task without the skill) and a **context run** (agent receives the task with the skill). The two outputs are scored independently by the judge and compared.

Read the output carefully. Look at **two things:**

1. **Verdict:** Did it pass? If not, which dimension failed?
2. **Delta:** Which dimensions improved the most? Which improved the least?

### Step 3: Inspect the History

```bash
cat .skill-bench-history.json | jq '.[-1]'
```

This shows the latest entry. Focus on the dimension with the smallest delta — that is where your skill is weakest.

### Step 4: Edit the Skill

Suppose `test_coverage` only improved by `+3`. Open `skills/my-service/SKILL.md` and add a concrete rule:

```markdown
## Hard Rules

... existing rules ...

5. Every service must include RSpec tests with at least:
   - One happy-path test
   - One error-path test
   - Use of `let` and `subject` blocks
```

### Step 5: Re-run and Compare Trends

```bash
skill-bench run my-first-eval --skill=my-service
```

Watch the **TREND** line:

```text
TREND: baseline → (0), context ↑ (+5)
```

The context score went up by 5 points compared to the previous run. If `test_coverage` delta jumped from `+3` to `+8`, your edit worked.

### Step 6: Iterate Until Stable

Repeat steps 4-5 until:
- The eval passes consistently (2-3 runs in a row)
- Deltas are stable (not swinging wildly)
- The trend line shows `context → (0)` or small positive deltas

### When to Stop Iterating

| Situation | Action |
|-----------|--------|
| Context score is ~95+ and deltas are flat | Your skill is mature. Move on. |
| Context score is stuck below threshold | Your eval task might be too hard, or your skill rules are too vague. Rewrite `task.md` with clearer acceptance criteria. |
| Baseline score is already high | The task is too easy. Make `task.md` harder so the skill has room to show value. |
| One dimension is always low | Add a specific rule to `SKILL.md` targeting that dimension. |

---

## Scoring Engine

The engine runs every eval **twice** — once without skill context (baseline) and once with skill context — then uses an LLM judge to score both outputs independently across configurable dimensions.

### How It Works (Visual Walkthrough)

```text
┌────────────────────────────────────────────────────────────────────────┐
│                         EVALUATION PIPELINE                            │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Step 1: Baseline Run                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │  task.md    │───→│   Agent     │───→│  Output A   │                 │
│  └─────────────┘    │  (no skill) │    │  (git diff) │                 │
│                     └─────────────┘    └─────────────┘                 │
│                                                                        │
│  Step 2: Context Run                                                   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │  task.md    │───→│   Agent     │───→│  Output B   │                 │
│  │  SKILL.md   │───→│  (+ skill)  │───→│  (git diff) │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
│                                                                        │
│  Step 3: Blind Judging (two independent calls)                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ Output A    │───→│   Judge     │───→│  Score A    │                 │
│  │ criteria    │    │  (baseline) │    │  per dim    │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
│                                                                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ Output B    │───→│   Judge     │───→│  Score B    │                 │
│  │ criteria    │    │  (context)  │    │  per dim    │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
│                                                                        │
│  Step 4: Verdict                                                       │
│  Delta = Score B - Score A                                             │
│  Pass if: Score B >= pass_threshold AND Delta >= minimum_delta         │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Key principle:** The judge never sees both outputs in the same call. This eliminates "halo effect" bias — the judge scores each output on its own merits, not by direct comparison.

### Canonical Dimensions

These 5 dimensions are **mandatory** in every `criteria.json`. You can add custom dimensions beyond these, but you cannot remove any of the core 5.

| Dimension | Default Description | Typical Weight |
|-----------|---------------------|----------------|
| **Correctness** | Does the output fulfill the task requirements? Are all specified behaviors present and correct? | 25-35 |
| **Skill Adherence** | Did the agent follow the specific patterns, hard gates, and workflows defined in the skill? | 20-30 |
| **Code Quality** | Is the code clean, well-structured, free of smells, follows SRP, and avoids duplication? | 15-25 |
| **Test Coverage** | Are there meaningful tests? Do they test the right things? Are they following TDD/best practices? | 10-20 |
| **Documentation** | Is there adequate YARD documentation, clear intent, and helpful inline comments where needed? | 5-15 |

**Why these weights?** Correctness and Skill Adherence are usually the highest because they directly measure "did the agent do the right thing" and "did the skill help." Test Coverage and Documentation are lower because they are supporting qualities.

### `criteria.json` Format

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

**Field-by-field breakdown:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `context` | string | Yes | Human-readable description of what this eval measures. Shown in the judge prompt. |
| `dimensions` | array | Yes | List of dimension objects. **Must include all 5 canonical dimensions.** Each needs `name` and `max_score`. `max_score` values must sum to exactly 100. |
| `pass_threshold` | integer | No | Minimum total **context** score (0-100) to pass. Default: 70. |
| `minimum_delta` | integer | No | Minimum total improvement (context - baseline) required to pass. Default: 10. |

**Rules:**

1. **Sum to 100:** `dimensions` `max_score` values must sum to exactly 100. The engine rejects any eval where they don't.
2. **All 5 core dimensions required:** You cannot omit `correctness`, `skill_adherence`, `code_quality`, `test_coverage`, or `documentation`.
3. **Custom dimensions allowed:** You can add dimensions beyond the core 5. Their `max_score` values still count toward the 100 total.
4. **Pass/fail logic:** Both conditions must be true:
   - `context_total >= pass_threshold` (the agent with skill scored high enough)
   - `total_delta >= minimum_delta` (the skill made a meaningful difference)

**Example with custom dimension descriptions:**

```json
{
  "context": "Evaluate REST API collection skill",
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 25, "description": "Did the agent use the `.call` pattern and return the standardized hash?" },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15 },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

**Example with a custom dimension (6 total, still summing to 100):**

```json
{
  "context": "Evaluate with performance considerations",
  "dimensions": [
    { "name": "correctness", "max_score": 25 },
    { "name": "skill_adherence", "max_score": 20 },
    { "name": "code_quality", "max_score": 15 },
    { "name": "test_coverage", "max_score": 15 },
    { "name": "documentation", "max_score": 10 },
    { "name": "performance", "max_score": 15, "description": "Is the solution performant? Are N+1 queries avoided?" }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

### Understanding the Output

**Human-readable format:**

```text
═══════════════════════════════════════════════════════
  Eval: my-first-eval
  Skill: my-service
  Provider: openai
═══════════════════════════════════════════════════════

  === BASELINE ITERATIONS ===
  Step 1: Read task → Tool: read_file → Observation: content...
  Step 2: Plan changes → Tool: write_file → Observation: Success...
  Step 3: Run tests → Tool: run_command → Observation: 3 runs, 0 failures
  Step 4: Final answer

  === CONTEXT ITERATIONS ===
  Step 1: Read task → Tool: read_file → Observation: content...
  Step 2: Apply skill pattern → Tool: write_file, run_command → Observation: Success...
  Step 3: Final answer

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

  === WHAT WENT WELL ===
  Correctness (28/30, baseline: 12/30)
    The agent correctly implemented all required behaviors.
  Skill Adherence (22/25, baseline: 5/25)
    Followed the service object pattern and hard gates.

  === WHAT WENT WRONG ===
  Test Coverage (13/15, baseline: 3/15)
    Tests exist but edge cases are missing.
    Advice: Are there meaningful tests? Do they test the right things?
```

**What each column means:**

- **BASELINE:** The agent's score *without* the skill. This is the "unaided" performance.
- **CONTEXT:** The agent's score *with* the skill. This is the "aided" performance.
- **DELTA:** `CONTEXT - BASELINE`. How much the skill helped.
- **TOTAL:** Sum of all dimension scores. Max possible is 100.
- **TREND:** Comparison against the previous run of the same eval + skill (from `.skill-bench-history.json`). Shows whether scores are improving over time.
- **VERDICT:** `PASS` only if `CONTEXT >= pass_threshold` AND `DELTA >= minimum_delta`.

**Iteration timeline:**

Each run (baseline and context) shows the ReAct loop steps the agent took: thinking, calling tools, and observing results. This helps you understand *how* the agent worked through the task. Observations are truncated to keep the output readable. If the timeline is empty, the agent finished in a single LLM call without using tools.

**Feedback sections:**

- **WHAT WENT WELL** — Dimensions where the context score is ≥ 80% of the max, with the judge's reasoning. These are the strengths of your skill.
- **WHAT WENT WRONG** — Dimensions where the context score is < 80% of the max, with the judge's reasoning and the baseline score for comparison. These are where your skill needs work.
- **ADVICE** — Each low-scoring dimension shows its description from `criteria.json` as actionable guidance. If the description is empty, no advice line appears.

**Verdict Decision Matrix**

Your eval result depends on **both** conditions. Here is every scenario:

| Context Score | Delta | Verdict | Why |
|---------------|-------|---------|-----|
| 87 | +55 | **PASS** | Context >= 70 **and** delta >= 10. The skill helped a lot. |
| 87 | -2 | **FAIL** | Context >= 70 **but** delta < 10. The skill made things **worse**. |
| 65 | +15 | **FAIL** | Context < 70 **even though** delta >= 10. Absolute score too low. |
| 65 | +5 | **FAIL** | Context < 70 **and** delta < 10. Both conditions failed. |

**Negative delta means the skill hurt performance.** If baseline=89 and context=87, your skill confused the agent or added noise. This is the most common "unexpected FAIL" — the skill reads well to humans but backfires with the LLM.

**FAIL example — skill made things worse:**

```text
  DIMENSION                BASELINE   CONTEXT    DELTA
  ──────────────────────── ───────── ───────── ───────
  Correctness (30)                28        25      -3
  Skill Adherence (25)            23        22      -1
  Code Quality (20)               18        18      +0
  Test Coverage (15)              12        13      +1
  Documentation (10)               8         9      +1
  ──────────────────────── ───────── ───────── ───────
  TOTAL                           89/100    87/100    -2

  VERDICT: FAIL (threshold: 70, minimum delta: 10)
```

**Why this FAILs:** Context score (87) is above the threshold (70), but the delta is **negative** (-2). The agent scored 89 *without* the skill and only 87 *with* it. The skill actively hurt performance. Common causes:
- Skill is too long or contradictory — the agent ignores the task to follow the skill
- Skill prescribes patterns that conflict with the task requirements
- Skill adds boilerplate that the judge penalizes (over-engineering)

**Fix:** Remove rules that don't directly improve the dimension with the lowest delta. Shorter skills usually beat longer ones.

---

## Reliability & Security

- **Safe-by-Design**: No code execution occurs on the host system; everything happens in the sandbox.
- **Command Blocklist**: Dangerous commands (`bash`, `sh`, `python`, `curl`, etc.) are always blocked, even if listed in `allowed_commands`.
- **Path Validation**: Eval paths are validated to prevent directory traversal attacks.
- **Atomic History Writes**: Benchmark history uses file locking to prevent corruption from concurrent writes.
- **URL Sanitization**: All provider URL parameters are CGI-escaped to prevent injection.
- **YAML Safety**: Config loading uses `permitted_classes: []` to prevent symbol DoS attacks.
- **Traceability**: Every thought and tool call is logged with full backtrace for post-mortem analysis.
- **Robust Error Recovery**: Handles provider outages and rate limits gracefully with standardized error logging.
- **XML-Safe Output**: JUnit XML output is properly escaped to prevent injection attacks.
- **Test Coverage**: 373+ tests covering core engine, CLI commands, and all provider clients.

## Testing

The project uses Minitest with WebMock for HTTP stubbing.

```bash
# Run all tests
bundle exec rake test

# Run with coverage
bundle exec rake test COVERAGE=true

# Run specific test file
bundle exec ruby -Itest test/integration_test.rb
```

**Test Structure:**

- `test/evaluator/` — Core evaluation engine tests
- `test/agent_eval/` — CLI, models, and service tests
- `test/clients/` — Provider client tests

## CI/CD Integration

GitHub Actions workflow included (`.github/workflows/ci.yml`):

- Runs on push and pull requests
- Tests against Ruby 3.3 and 3.4
- Executes rubocop, reek, and minitest
- Outputs JUnit XML for test reporting

```bash
# Run locally with CI output
skill-bench run my-eval --skill=my-skill --format json
```

---

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
