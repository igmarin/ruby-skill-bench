# SkillBench Architecture

Ruby Skill Bench provides a reproducible and isolated environment for testing AI agents. It consists of several decoupled components that orchestrate the evaluation flow.

## High-Level Flow

1. **`RunnerService`**: The entry point. Resolves eval, skill, and provider, then runs baseline and context agents.
2. **`Sandbox`**: Creates a temporary directory, copies task files, and initializes a Git repository for clean, reproducible runs.
3. **`ContextHydrator`**: Loads skill documentation (.md, .rb, .json, .yml, .yaml, .txt up to 50KB each) and wraps it in XML for the agent's system prompt.
4. **`ReactAgent`**: Autonomous agent following a **Thought → Tool → Observation** loop.
5. **`EvaluationRunner`**: Orchestrates blind judging — builds `JudgePrompt` for baseline and context outputs, calls `Judge` twice, then computes deltas via `DeltaReport`.
6. **`DeltaReport`**: Computes per-dimension deltas and determines verdict based on `pass_threshold` and `minimum_delta`.
7. **`Client`**: Provider-agnostic abstraction for LLM backends.

## Key Components

### `SkillBench::Services::RunnerService`

- Resolves eval, skill, and provider configuration.
- Runs baseline agent (no skill context) and context agent (with skill context).
- Delegates judging and delta computation to `EvaluationRunner`.
- Falls back to mock provider when config is unavailable.

### `SkillBench::EvaluationRunner`

- Builds `JudgePrompt` for baseline and context outputs.
- Calls `Judge` twice (blind scoring).
- Uses `DeltaReport` to compute per-dimension deltas and final verdict.

### `SkillBench::DeltaReport`

- Computes baseline vs context deltas per dimension.
- Verdict requires: `context_total >= pass_threshold` AND `total_delta >= minimum_delta`.

### `SkillBench::CLI` Commands

- `InitCommand` — Creates `skill-bench.json` configuration
- `RunCommand` — Executes evaluations
- `SkillCommand` — Scaffolds new skills with templates
- `EvalCommand` — Creates evaluation scenarios

### `SkillBench::Services::TemplateRegistry`

- Provides pre-built templates for generating eval scaffolding
- Supports three template types: `task_md`, `criteria_json`, `skill_md`
- Offers 10 Rails pattern categories: `crud`, `api`, `background_job`, `controller`, `model`, `migration`, `concern`, `policy`, `form_object`, `view_component`
- Enables variable interpolation using `{{variable_name}}` syntax
- Used for programmatic eval creation and tool building

### `SkillBench::Sandbox`

- Uses `Dir.mktmpdir` for isolation.
- Captures state changes using `git diff`.
- Validates sandbox path to prevent directory traversal.
- Cleans up automatically after execution.

### `SkillBench::ReactAgent`

- Implements a stateful loop.
- Supports tool usage (e.g., `read_file`, `write_file`, `run_shell_command`).
- Manages conversation history.

### `SkillBench::Clients::BaseClient`

- Implements the **Template Method** pattern.
- Handles Faraday connection setup and timeouts.
- Centralizes error logging and response normalization.
- Delegates to `ResponseParser`, `ResponseErrorHandler`, and `RequestBuilder`

### `SkillBench::OutputFormatter`

- Formats results as human-readable text, JSON, or JUnit XML
- Human format displays a dimension table with baseline, context, and delta columns
- Escapes XML output to prevent injection
- Provides exit codes for CI/CD integration

### `SkillBench::ErrorLogger`

- Shared error logging module for all service objects
- Logs error message and full backtrace
- Uses `Rails.logger` when available, falls back to `warn`

## Data Flow: What Passes Between Components

Understanding what data moves between components helps debug issues and write better evals.

### Flow 1: RunnerService → EvaluationRunner

```ruby
# RunnerService builds this and passes it to EvaluationRunner.call
evaluation = {
  task: "Create a UserRegistrationService...",        # from task.md
  criteria: <Criteria object>,                         # from criteria.json
  skill_context: "<agent_context>...SKILL.md...</agent_context>",  # from ContextHydrator
  baseline_output: '{"result":"...","status":":success"}',        # from baseline agent run
  context_output: '{"result":"...","status":":success"}'         # from context agent run
}
```

### Flow 2: EvaluationRunner → Judge (two calls)

```ruby
# First call — baseline (no skill context)
JudgePrompt.call(
  task: task,
  criteria: criteria,
  skill_context: "",        # empty string for baseline
  agent_output: baseline_output
)

# Second call — context (with skill context)
JudgePrompt.call(
  task: task,
  criteria: criteria,
  skill_context: skill_context,   # XML-wrapped SKILL.md
  agent_output: context_output
)
```

### Flow 3: Judge → JudgeResponse

The judge returns a JSON string like:

```json
{
  "dimensions": {
    "correctness": { "score": 28, "max_score": 30, "reasoning": "All requirements met." },
    "skill_adherence": { "score": 22, "max_score": 25, "reasoning": "Used .call pattern correctly." }
  },
  "overall_reasoning": "Solid implementation."
}
```

`JudgeResponse` parses this, validates that scores are numeric and within bounds, and returns a structured object.

### Flow 4: DeltaReport → Output

```ruby
# DeltaReport receives two JudgeResponse objects
baseline = {
  'correctness' => { score: 12, max_score: 30 },
  'skill_adherence' => { score: 5, max_score: 25 }
}

context = {
  'correctness' => { score: 28, max_score: 30 },
  'skill_adherence' => { score: 22, max_score: 25 }
}

# Produces:
deltas = {
  'correctness' => 16,        # 28 - 12
  'skill_adherence' => 17     # 22 - 5
}

baseline_total = 17           # 12 + 5
context_total = 50            # 28 + 22
verdict = context_total >= pass_threshold && (context_total - baseline_total) >= minimum_delta
```

## Directory Structure

The evaluator relies on a strict directory convention:

```bash
project-root/
├── skill-bench.json              # Provider configuration
├── skills/
│   └── my-service/
│       └── SKILL.md              # Skill instructions
├── evals/
│   └── my-first-eval/
│       ├── task.md               # Agent prompt
│       └── criteria.json         # Scoring rules
└── .skill-bench-trends.json      # Benchmark history (auto-generated)
```

A `.skill-bench-trends.json.bak` file is created automatically as a backup of the trend file.

### Skill Discovery

Skills are discovered recursively. These are all valid:

```bash
skills/my-service/SKILL.md
skills/api/rest-collection/SKILL.md
skills/workflows/tdd-loop/SKILL.md
```

The `SkillResolver` walks `skills/` recursively and matches by directory name.

### Eval Discovery

Evals are resolved in this order:

1. If the path contains `/`, use it as-is (e.g., `evals/my-eval`)
2. Otherwise, prepend `evals/` (e.g., `my-eval` → `evals/my-eval`)

The eval directory must contain at minimum:

- `task.md` — the agent prompt
- `criteria.json` — the scoring rules (optional; defaults to empty criteria if missing)
