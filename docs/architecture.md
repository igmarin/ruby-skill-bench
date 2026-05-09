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

## Data Structures

The evaluator relies on a strict directory mirroring convention:
- **Skill**: `skills/<category>/<skill_name>`
- **Eval**: `evals/<eval_name>` or a local path containing `task.md` and `criteria.json`

Skill discovery works recursively, supporting nested directories (e.g., `skills/api/ruby-api-client-integration/SKILL.md`).
