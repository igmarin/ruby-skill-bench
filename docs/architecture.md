# SkillBench Architecture

Ruby Skill Bench provides a reproducible and isolated environment for testing AI agents. It consists of several decoupled components that orchestrate the evaluation flow.

## High-Level Flow

1. **`RunnerService`**: The entry point. It resolves the eval, skill, and provider, then orchestrates evaluation execution.
2. **`Sandbox`**: Creates a temporary directory, copies the task files into it, and initializes a Git repository. This ensures that every run starts from a clean state and that all modifications can be captured via Git diffs.
3. **`ContextHydrator`**: Reads skill/workflow documentation from the repository and converts it into a standardized XML format injected into the agent's system prompt.
4. **`ReactAgent`**: An autonomous agent that follows the **Reasoning and Acting** loop. It analyzes the task, decides which tools to use, executes them in the sandbox, and observes the results until the task is complete.
5. **`ScoringService`**: Computes deterministic composite scores based on test pass rate, timing compliance, and error handling.
6. **`Client`**: A provider-agnostic abstraction layer. It dispatches API calls to different LLM backends (OpenAI, Anthropic, Gemini, etc.) and handles standardized error reporting.

## Key Components

### `SkillBench::Services::RunnerService`

- Resolves eval, skill, and provider configuration.
- Spawns the agent and collects results.
- Falls back to mock provider when config is unavailable.

### `SkillBench::CLI` Commands

CLI command handlers for the `skill-bench` executable:
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