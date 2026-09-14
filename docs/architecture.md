# SkillBench architecture

## Executive summary

Ruby Skill Bench is a Ruby gem that runs the same coding task twice: once without skill context (baseline) and once with it (context). An LLM judge scores each run independently. `DeltaReport` then decides pass or fail from the context total and the delta.

Source of truth for a run is the eval directory (`task.md` + `criteria.json`), the skill files loaded into context, and `skill-bench.json` (plus env overrides). Runtime artifacts are a temp git sandbox and `.skill-bench-trends.json`.

The rule a contributor must not break: host command execution is fail-closed. `run_command` runs inside the Docker `evaluator-sandbox` image when a daemon and image are available. Otherwise it refuses unless `allow_host_execution` is explicitly true.

### System architecture

```text
User / CI
    |
    v
bin/skill-bench  ->  SkillBench::CLI
    |
    +-- init / validate / skill / eval / compare
    +-- run  ->  Commands::Run  ->  Services::RunnerService
                                      |
                                      +-- EvalResolver, SkillResolverService, ProviderResolver
                                      +-- ContextLoaderService (ContextHydrator)
                                      +-- Parallel: baseline agent | context agent
                                      |     Sandbox (tmp git, optional Docker)
                                      |     ReactAgent + Tools + Client
                                      +-- Evaluation::Runner (blind Judge x2, concurrent)
                                      +-- DeltaReport
                                      +-- TrendRecorderService
                                      +-- CostCalculator
                                      v
                                 OutputFormatter (human / json / junit / html)
```

Outside the gem: LLM HTTP APIs (OpenAI-compatible and native), optional Docker daemon, optional ecosystem `registry.json` for `--pack`.

### Dependency hierarchy

```text
CLI  ->  Commands  ->  Services (RunnerService, BatchRunnerService, ComparisonRunner)
                         |
                         +--> Agent / Tools
                         +--> Execution (Sandbox, ContextHydrator)
                         +--> Evaluation::Runner -> Judge -> Clients
                         +--> Config
                         +--> Models (Eval, Skill, Criteria, Provider)
```

Dependencies point inward: CLI does not call providers; agents do not load config files; clients do not know about evals. Adding a provider means a `Clients::Providers::*` class plus a `ProviderSchemas` entry. Adding a command means a `Cli::*Command` plus a `Commands::*` object. Do not reverse that.

---

## Eval run lifecycle

Exact order for `skill-bench run <eval> --skill <name>`:

1. `SkillBench::CLI` shifts the subcommand and calls `Cli::RunCommand`.
2. `RunCommand` parses flags (`--skill`, `--pack`, `--format`, `--all`, `--evals-dir`, `--summary`, `--cache`). `--cache` sets `SKILL_BENCH_CACHE=1`.
3. `Commands::Run` calls `Services::RunnerService.call`.
4. `EvalResolver` loads `task.md` and `criteria.json`. Path with `/` is used as-is; otherwise `evals/` is prepended.
5. `SkillResolverService` resolves skills (local path, `skill_sources`, or `--pack` via `Registry::PackResolver`).
6. `ProviderResolver` builds a `Models::Provider` from `Config` (defaults, then `~/.skill-bench.json`, then `./skill-bench.json`, then `ENV`).
7. `ContextLoaderService` / `Execution::ContextHydrator` reads skill files. Allowed extensions: `.md`, `.rb`, `.json`, `.yml`, `.yaml`, `.txt`. Per-file cap 50_000 bytes. Total cap 1_000_000 bytes. Symlinks are skipped. Empty context is an error.
8. `RunnerService` runs baseline and context agents concurrently (`Parallel.map`, two threads). Each agent runs inside `Execution::Sandbox.run`: copy sources into `Dir.mktmpdir`, hardened `git init`, start Docker if available, yield, stop container, delete the tempdir.
9. `Evaluation::Runner` judges baseline and context concurrently. Baseline judge gets an empty skill context. Context judge gets the XML skill bundle. The judge never sees both outputs in one call.
10. `DeltaReport` computes per-dimension deltas. Verdict is `context_total >= pass_threshold AND total_delta >= minimum_delta`.
11. `TrendRecorderService` appends `.skill-bench-trends.json` and keeps `.skill-bench-trends.json.bak`.
12. `CostCalculator` estimates USD from aggregated token usage.
13. `Cli::ResultPrinter` / `SkillBench::OutputFormatter` prints human, json, junit, or html and returns exit 0 or 1.

Batch mode (`--all` / `--evals-dir`) uses `BatchRunnerService` instead of a single `RunnerService` call. `compare` runs `RunnerService` twice via `ComparisonRunner`.

Failure behavior:

- Missing provider config returns a config error envelope; it does not raise through the CLI.
- Agent `:error` status short-circuits judging.
- Judge parse failure returns `{ success: false, response: { error: { message: } } }`.
- `run_command` with no container and `allow_host_execution` false returns `HOST_EXECUTION_REFUSED` and does not exec.

---

## Components

### `SkillBench::CLI`

Owns ARGV dispatch and exit codes. Does not own eval scoring. Subcommands: `init`, `run`, `compare`, `skill`, `eval`, `validate`/`doctor`, `help`.

### `Services::RunnerService`

Owns one eval's baseline+context orchestration, token aggregation, and the envelope passed to the printer. Does not own HTTP or git. Depends on resolvers, sandbox/agent spawners, `Evaluation::Runner`, `TrendRecorderService`, `CostCalculator`.

### `Execution::Sandbox`

Owns the temp directory, hardened git (`core.hooksPath=/dev/null`, no source `.git` copy), and container lifecycle. Image ref is `evaluator-sandbox:<VERSION>`. Docker run flags: `--network none`, non-root `--user uid:gid`, `--cap-drop ALL` (then CHOWN and DAC_OVERRIDE), `--security-opt no-new-privileges`, volume mount of the sandbox. Does not own command allowlisting (`Tools::RunCommand` does).

### `Execution::ContextHydrator`

Owns packing skill files into XML for the agent system prompt. Does not own skill path resolution.

### `Agent::ReactAgent`

Owns the Thought → Tool → Observation loop, capped at `max_iterations` (default 25). Tools: `read_file`, `write_file`, `run_command`. Does not own judging.

### `Evaluation::Runner`

Owns blind judging and the call to `DeltaReport`. Two judge HTTP calls, concurrent, order preserved. Does not own agent execution.

### `DeltaReport`

Owns per-dimension arithmetic and the boolean verdict. Does not call the network.

### `Clients::BaseClient` and `ProviderRegistry`

Own HTTP to LLM providers (Faraday, retries, response normalization). Registered providers: openai, anthropic, gemini, ollama, azure, groq, deepseek, mistral, opencode, openrouter, plus mock and null. Do not own eval files.

### `Config`

Owns the hierarchy Defaults → home JSON → local JSON → ENV. `EnvOverrides` maps `SKILL_BENCH_*` keys. Mistral has no env mapping; its key is `config.api_key` in JSON. Azure env key is `SKILL_BENCH_AZURE_OPENAI_API_KEY`.

### `SkillBench::OutputFormatter`

Owns user-facing result text. Delegates to `JsonFormatter`, `JUnitFormatter`, `HtmlFormatter`, `DeltaTableFormatter`, `IterationFormatter`, `FeedbackGenerator`. Distinct from `Services::OutputFormatter`, which stringifies agent output for the judge.

### `ErrorLogger`

Logs message plus first five backtrace lines. Uses `Rails.logger` when `Rails` is defined; otherwise `warn`.

---

## Command isolation

See [docker.md](docker.md) for the image contract and `rake docker:build`. Live Docker tests are opt-in via `SKILL_BENCH_DOCKER_TESTS=1`.

---

## Source map

| Concept | Authoritative file |
| --- | --- |
| CLI dispatch | `lib/skill_bench/cli.rb` |
| Single eval | `lib/skill_bench/services/runner_service.rb` |
| Blind judge | `lib/skill_bench/evaluation/runner.rb` |
| Verdict | `lib/skill_bench/delta_report.rb` |
| Sandbox + Docker | `lib/skill_bench/execution/sandbox.rb` |
| Host exec gate | `lib/skill_bench/tools/run_command.rb` |
| Context caps | `lib/skill_bench/constants.rb` (`ContextHydration`) |
| Config hierarchy | `lib/skill_bench/config.rb` |
| Provider env keys | `lib/skill_bench/config/env_overrides.rb` |
| Provider list | `lib/skill_bench/clients/provider_schemas.rb` |
| Image contract | `docs/docker.md` |

Deprecated entry points still in the tree, not on the live path: `SkillBench::Runner`, `EvaluateCommand`, `Task::Evaluator`.

---

## Verification

| Claim | Evidence |
| --- | --- |
| CLI subcommands | `SkillBench::CLI#call` case in `lib/skill_bench/cli.rb` |
| Concurrent agents | `RunnerService#run_agents_concurrently` |
| Concurrent judges | `Evaluation::Runner#run_judges_concurrently` |
| Verdict formula | `DeltaReport#determine_verdict` |
| Fail-closed host exec | `Tools::RunCommand` + `Sandbox` comments and `allow_host_execution` default |
| Docker flags | `Sandbox#start_container` |
| Context size caps | `Constants::ContextHydration` + `ContextHydrator#collect_context_files` |
| `--cache` | `Cli::RunCommand` sets `ENV['SKILL_BENCH_CACHE']`; `HelpPrinter` documents it |
| OpenRouter env | `EnvOverrides::ENV_TO_PROVIDER_SETTINGS` |

Evidence gap: whether every provider in `ProviderSchemas` is registered at boot is covered by client tests under `test/evaluator/clients/`, not by a single registry integration test named in this document.
