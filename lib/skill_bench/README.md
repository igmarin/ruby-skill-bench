# SkillBench Domain (`lib/skill_bench/`)

The `SkillBench` namespace is responsible for creating a safe, observable environment in which the agent can be tested, and subsequently judging its performance.

## Components

### `Sandbox`
- **Purpose**: Creates an isolated environment (`mktmpdir`) for the agent to work in.
- **Mechanism**: It copies the target directory, initializes a Git repository, and commits the initial state. This allows the system to easily capture the agent's work via `git diff` at the end of the run.
- **Code**: [sandbox.rb](sandbox.rb)

### `AgentRunner`
- **Purpose**: Sets up the initial system prompt, hydrates context, and kicks off the ReAct loop.
- **Mechanism**: Orchestrates the communication between the `ReactAgent`, the `SourcePathResolver`, and the `ContextHydrator`.
- **Code**: [agent_runner.rb](agent_runner.rb)
- **Note**: Console output removed — returns structured data only.

### `SourcePathResolver`
- **Purpose**: Resolve the source skill or workflow directory for an eval target without requiring callers to pass `--skill` in the common case.
- **Mechanism**: Maps `evals/skills/...` to `skills/...` and `evals/workflows/...` to `workflows/...`, while honoring explicit overrides.
- **Code**: [source_path_resolver.rb](source_path_resolver.rb)

### `Judge`
- **Purpose**: Evaluates the outcome of the agent's work.
- **Mechanism**: Compares the resulting `git diff` against the instructions and context, and uses the LLM to score the performance out of 100, providing an explanation for its score.
- **Code**: [judge.rb](judge.rb)
- **Returns**: Structured response `{ success: bool, response: { content: '...' } }`

### `TaskFileReader`
- **Purpose**: Safely reads `task.md` and `criteria.json` files with proper error handling.
- **Mechanism**: Returns structured responses with file contents or error messages.
- **Code**: [task_file_reader.rb](task_file_reader.rb)

### `TaskEvaluator`
- **Purpose**: Orchestrates evaluation of a single task (baseline + context runs).
- **Mechanism**: Uses `TaskFileReader`, `AgentRunner`, and `Judge` to evaluate one task.
- **Code**: [task_evaluator.rb](task_evaluator.rb)
- **Note**: Extracted from `Runner` to follow Single Responsibility Principle.

### `ScoringService`
- **Purpose**: Computes deterministic composite scores from eval results.
- **Mechanism**: Weights test pass rate (50%), timing compliance (30%), and error handling (20%). Loads thresholds from `criteria.json`.
- **Code**: [services/scoring_service.rb](services/scoring_service.rb)

## Services (`lib/skill_bench/services/`)

See [services/README.md](services/README.md) for details on:
- `OptionParserService` — CLI argument parsing
- `JudgeScoreParserService` — Judge response parsing
- `ResultPrinterService` — Output formatting
- `OutputPersistenceService` — JSON file persistence
- `ScoringService` — Deterministic scoring engine

## Configuration (`lib/skill_bench/config/`)

Hierarchical configuration loading:

1. **Defaults** — built-in code defaults
2. **Home JSON** — `~/.skill-bench.json`
3. **Local JSON** — `./.skill-bench.json`
4. **Environment variables** — provider API keys and models

Key classes:
- `Config` — public facade
- `Config::Store` — mutable state holder
- `Config::Defaults` — built-in defaults
- `Config::JsonLoader` — JSON file loading with validation
- `Config::EnvOverrides` — environment variable mapping
- `Config::Applier` — applies loaded config to the store
