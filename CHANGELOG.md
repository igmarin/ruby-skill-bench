# Changelog

All notable changes to `ruby-skill-bench` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0]

> In progress — the v1.2.0 quality program (security, performance, documentation, examples). The release date is set when the version is tagged.

### Added
- `skill-bench validate` (alias `doctor`): a pre-flight check that validates `criteria.json` via `CriteriaValidator`, schema-checks `skill-bench.json`, and reports missing provider API keys — all without running an eval or hitting the network (#45).
- `--format html`: a self-contained HTML report rendering the delta-score table and the baseline/context iteration timelines, with all dynamic text escaped (#44).
- Per-run token & cost accounting: agent token usage is threaded through the run, an estimated USD cost is shown in the human report (`Tokens: N | Est. Cost: $X.XXXX`) and exposed in JSON output; new `Services::CostCalculator` with a per-model price table (#40).
- Opt-in content-addressed response caching via `--cache` / `SKILL_BENCH_CACHE`: identical agent/judge calls — notably `compare`'s twice-run skill-less baseline — reuse a cached response instead of hitting the network. Default off (#42).
- Batch CI surfaces: a `--summary` JSON gate (aggregate pass/fail counts, summed tokens/cost, worst-delta eval) and per-eval `<testcase>` aggregation in JUnit output, plus a top-level composite `action.yml` so downstream repos can gate skill changes with `uses: igmarin/ruby-skill-bench@v1` (#46).
- Mistral provider, an OpenAI-compatible client subclass (#47).
- `skill-bench init --mock` scaffolds a ready-to-run offline `mock` config (`{"provider":"mock","max_execution_time":30}`) (#53).
- Community-health files: `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), issue templates, and a pull-request template (#38).
- Runnable, fully offline `examples/offline-quickstart/` that demonstrates a complete eval with the built-in `mock` provider — no API keys, no network (#49).
- Example files are now tracked: removed the blanket `examples/` rule from `.gitignore` (#48).

### Security
- Documented that the command allowlist authorizes only the base token, so any allowlisted wrapper binary (`rake`, `rspec`, `make`, `find`, `git`) is equivalent to arbitrary host execution, and tied this to the fail-closed host-execution model. Added an optional, default-off `command_argument_constraints` hook to constrain high-risk allowed commands (#21).

### Performance
- Provider resolution now parses `skill-bench.json` at most once per run via an mtime-memoized load, removing a redundant per-run file read + parse (#31).
- Baseline and context agent runs now execute concurrently, roughly halving the dominant agent phase of a run. The previously unused `parallel` dependency is now wired into the active `RunnerService` path (#26).

### Fixed
- An explicit `{"provider":"mock"}` config no longer prints a misleading "Config load failed" warning on a clean offline run; genuine load failures (missing/broken config) still warn (#54).
- `Judge::Prompt` no longer emits an empty `## Skill Context` section on baseline (skill-less) runs. The empty header had caused the `mock` provider to score baseline and context identically (delta 0); baseline prompts are now cleaner and offline scoring is correct (#58).

### Documentation
- `docs/architecture.md` now shows the correct `.skill-bench-trends.json` filename and notes the `.skill-bench-trends.json.bak` auto-backup (#39).
- Corrected the evaluation-history filename throughout the README and docs: the engine writes `.skill-bench-trends.json`, not the previously-documented `.skill-bench-history.json` (#34).

## [1.1.0] - 2026-06-23

### Added
- `CONTRIBUTING.md` with development setup, code-style, service-object, TDD, and security-reporting guidance.
- README "Security" / "Threat Model" section documenting the sandbox, command controls, and resource limits.
- `Clients::ResponseBuilder` service object for standardized success/error response hashes.
- `Clients::RetryHandler` for retrying transient provider HTTP failures.
- Command-safety constants including the `DANGEROUS_COMMANDS` blocklist.

### Security
- Hardened command execution in `tools/run_command.rb` (allowlist + dangerous-command blocklist, tokenized execution).
- Strengthened sandbox path/symlink validation in `execution/sandbox.rb`.
- Added file-size and symlink restrictions to context hydration in `execution/context_hydrator.rb`.

### Changed
- Refactored the HTTP client layer (`clients/base_client.rb`, `clients/request_builder.rb`, `clients/response_error_handler.rb`) around the new `ResponseBuilder` / `RetryHandler`.

## [1.0.0] - 2026-05-28

### Added
- `Mock` client provider for structured scoring simulations without hitting LLM API.
- `ecosystem-audit.rb` script for validating consistency across all sibling repositories in the ecosystem.
- `Config::Store#skill_sources` — multi-repo skill source mapping parsed from `skill-bench.json` (Phase 5)
- `SourcePathResolver` skill source fallback — when a skill is not found locally, iterates `skill_sources` config entries and returns first match
- `Registry::PackResolver` — resolves skill paths from ecosystem registry manifest (`registry.json` → `tile.json` → skill path)
- `--pack` flag on `skill-bench run` — resolve skills via registry manifest with configurable `--registry-manifest` path
- `skill-bench compare` command — run the same eval with two skill variants and print side-by-side comparison report
- 10 extracted atomic skill eval stubs: `write-yard-docs`, `create-service-object`, `define-domain-language`, `model-domain`, `triage-bug`, `integrate-api-client`, `implement-calculator-pattern`, `review-domain-boundaries`, `respond-to-review`, `skill-router`
- `ReactAgent::Step.call` now returns `:iteration` metadata (`:thought`, `:tools_used`, `:observation_summary`) for per-step timeline rendering
- `ReactAgent::LoopRunner` collects `:iterations` array into the final response
- `DeltaReport` now preserves full per-dimension judge reasoning via `baseline_dimensions` and `context_dimensions` attributes
- `RunnerService` captures `baseline_iterations` and `context_iterations` from sandboxed `ReactAgent` runs
- `OutputFormatter` human output now renders iteration timelines (`=== BASELINE ITERATIONS ===`, `=== CONTEXT ITERATIONS ===`)
- `OutputFormatter` human output now renders actionable feedback sections (`=== WHAT WENT WELL ===`, `=== WHAT WENT WRONG ===`, `=== ADVICE ===`) using an 80% score threshold
- `FormattingHelpers` shared module — `humanize`, `delta_str`, `truncate`, `trend_icon`
- `IterationFormatter` service — formats ReAct loop step timelines
- `DeltaTableFormatter` service — formats dimension scoring table, totals, trend, and verdict
- `FeedbackGenerator` service — categorizes dimension scores into well/wrong/advice from judge reasoning
- `JsonFormatter` service — extracted JSON formatting from `OutputFormatter`
- `JUnitFormatter` service — extracted JUnit XML formatting from `OutputFormatter`
- `max_iterations` default bumped from 10 to 25 (configurable via `skill-bench.json`)
- `TemplateRegistry` service for programmatic eval scaffolding with 10 Rails pattern categories (`crud`, `api`, `background_job`, `controller`, `model`, `migration`, `concern`, `policy`, `form_object`, `view_component`)
- `TemplateRegistry` supports three template types: `task_md`, `criteria_json`, `skill_md`
- `TemplateRegistry` variable interpolation using `{{variable_name}}` syntax
- `Eval` model now loads and exposes metadata from `metadata.json`
- `RunnerService` context-aware system prompts with `skill_bundle_xml` context mode
- `RunnerService` source path resolution via `SourcePathResolver` for context hydration
- `ProviderSchemas` registry for provider configuration templates (8 providers: OpenAI, Anthropic, Gemini, Azure, Ollama, Groq, DeepSeek, OpenCode)
- `SkillResolver` service for resolving skills by path or name with recursive discovery
- `Cli::InitCommand`, `Cli::RunCommand`, `Cli::SkillCommand`, `Cli::EvalCommand` — extracted CLI subcommand handlers
- `Cli::HelpPrinter`, `Cli::ResultPrinter` — extracted CLI output formatters
- `Config#to_provider` method for building Provider model from config
- `ResponseParser` now handles Array response bodies gracefully
- `SkillBench::HelpRequested` — shared sentinel exception for CLI help handlers
- `Sandbox#copy_source_files` — explicit file copy with symlink validation and dotfile support
- `Sandbox#docker_available?` — checks for Docker before attempting container start
- Top-level exception handler in `bin/skill-bench` for graceful error reporting
- `Judge#build_prompt` — extracted prompt builder with UUID-based delimiters to prevent prompt injection
- `Judge#escape_prompt_content` — escapes XML-like tags in user content before interpolation
- `EvalNew::ALLOWED_RUNTIMES` constant (`%w[ruby rails]`) with runtime validation guard
- `SkillResolver` sibling-directory prefix bypass test coverage

### Changed
- `Registry::PackResolver` recursively resolves deprecated skill redirects, traverses `depends_on` pack chains, and strips `/SKILL.md` suffix from path names.
- `SkillResolver` allows sibling paths inside `skill_sources` to bypass boundary checks.
- **BREAKING:** `skill-bench init` now requires a provider flag (`--openai`, `--gemini`, etc.)
- **BREAKING:** Config format changed from multi-provider to single-provider: `{ "provider": "...", "max_execution_time": N, "config": {...} }`
- **BREAKING:** `skill-bench run` no longer accepts `--provider` flag — reads provider from config
- `Skill.discover` now searches recursively for nested skill directories
- `Config` model switched from YAML (`.agent-eval.yml`) to JSON (`skill-bench.json`)
- `RunnerService` reads provider from config file instead of accepting `provider_name` parameter
- CLI refactored from monolithic class (~230 lines) to thin dispatcher (~45 lines) with extracted command modules
- `print_result` checks `result[:pass]` instead of `result[:success]` for correct scoring output
- **BREAKING:** Environment variable prefix changed from `AGENT_EVAL_` to `SKILL_BENCH_`
- `RunnerService` status values normalized from strings to symbols (`:success`, `:error`, `:passed`)
- `ScoringService#error_score` fixed: `.round` was called on Array instead of Numeric
- `ResultPrinter` now delegates to `OutputFormatter` for consistent human-readable output
- `OutputFormatter` refactored from 332-line monolith into thin dispatcher (125 lines) + 6 focused services under `SkillBench::Services`
- `ToolExecutor` suppresses `=== Calling Tool: ===` debug output during test runs (`defined?(Minitest)` guard)
- `ErrorLogger` now suppresses stderr output during test runs unless the test explicitly captures `$stderr` via `StringIO`
- `ReactAgent::LoopRunner#attach_step_number` and `#merge_iterations` now have YARD documentation
- `ReactAgent::Step` extracted local variables (`tool_calls_array`, `thought`) to eliminate duplicate method calls
- `Provider::ALLOWED_PROVIDERS` now derived from `ProviderSchemas.names` (single source of truth)
- `Config.store#assign_current_llm_provider` simplified from obfuscated array/grep pattern to simple conditional
- `ResponseErrorHandler.log_error` now delegates to `ErrorLogger` (DRY)
- `Sandbox` only starts Docker container when `docker` is available and Dockerfile exists
- `RunnerService` duplicated `provider.merged_config` rescue blocks extracted to `safe_merged_config` helper

### Fixed
- Added `Config.reset` call in CLI boot to initialize config, with test-suite override protection to avoid workspace test pollution.
- `CLI` HelpPrinter constant fully qualified to prevent NameError
- All CLI command help handlers return `0` instead of calling `exit` (composable/testable)
- `InitCommandTest` verifies no config file created on missing provider
- `InitCommandTest` verifies existing config preserved when `--force` not used
- `RunCommandTest` has explicit `require 'json'`
- `RunnerServiceTest` extracted `write_mock_config` helper to eliminate duplication
- `ResponseParser.parse_body` no longer crashes on Array response bodies
- `RunnerService.resolve_provider` builds proper `Models::Provider` instead of raw Hash
- `ProviderRegistry.for` now receives symbol keys for correct provider lookup
- `print_result` now displays actual error messages instead of "Unknown error"
- Reek: `NestedIterators` in `handle_init` extracted to `register_provider_options`
- Reek: `FeatureEnvy` in `RunnerService#resolve_provider` moved to `Config#to_provider`
- Reek: `DuplicateMethodCall` in `print_result` eliminated with local variables
- `Config#to_provider` now returns nil when provider_name is nil (prevents malformed Provider)
- `RunnerService` memoizes `resolve_provider` to avoid double Config.load calls
- `RunnerService.mock_provider` extracted to module-level `MOCK_PROVIDER` constant Struct
- `SkillResolver.resolve_by_name` now detects and raises on duplicate skill names
- `ProviderSchemas.for` returns a dup of the schema to prevent registry mutation
- `ProviderSchemas::PROVIDER_SCHEMAS` inner hashes are now frozen (deep freeze)
- `Cli::InitCommand` error message now dynamically lists available providers
- Removed stale `require 'yaml'` from `Config` model
- Test teardown in `InitTest` and `InitProviderTest` now restores original working directory
- `SkillTest` no longer uses global `Dir.chdir` — uses absolute temp paths instead
- Added missing `require 'json'` to `RunnerServiceTest`
- `OutputFormatter` no longer double-escapes `score` in JUnit XML failure messages
- `InitCommand` and `RunCommand` `return 0` inside OptionParser blocks replaced with `raise HelpRequested` (prevents LocalJumpError)
- `RunCommand` validates `--skill` is present before invoking `Commands::Run`
- `OutputFormatter#format_delta_report` cyclomatic/perceived complexity reduced from 12 to ≤10 by extracting `build_iteration_lines`
- `FeedbackGenerator#generate_feedback` ABC size reduced from 59 to ≤50 by extracting `categorize_dimensions`, `extract_values`, `compute_percentage`, `build_categorization`, `assemble_feedback_lines`, and `append_section`
- `ContextHydrator` escapes file content with `CGI.escapeHTML` before XML insertion
- `Sandbox.capture_diff` uses separator-aware path validation (`tmp_prefix + File::SEPARATOR`)
- `RunnerService` silent config errors now propagate clear error messages instead of falling back to mock provider
- `HelpPrinter` now documents `--format`, `eval generate`, and multi-skill chaining
- `EvalNew` default runtime changed from `'generic'` to `'ruby'`
- `OutputFormatter#format_junit` now reads from `result[:response][:report].verdict` (DeltaReport format) with legacy fallback
- `test_helper.rb` glob require replaced with canonical `require_relative '../lib/skill_bench'`
- `SimpleCov.start 'rails'` changed to `SimpleCov.start` (non-Rails gem)
- `OpenRouterTest` `$stderr` reassignment wrapped in `begin...ensure` to prevent leakage
- `ContextHydratorTest` hardcoded temp filename replaced with unique suffix (`Process.pid + Time.now.to_f`)
- `OpenCode` provider docs now reference correct `SKILL_BENCH_OPENCODE_BASE_URL` env var
- `README` config precedence wording aligned with hierarchy section
- `README` "Step 2" heading clarified: "Run the Eval (Baseline + Context)"
- `SourcePathResolver` caches `extract_skill_name` result to avoid redundant method calls
- `PackResolver` adds nil guard for source before string split to prevent NoMethodError
- `PackResolver` validates resolved skill paths are inside source directory to prevent directory traversal
- `AgentSpawnerService` wraps sandbox execution in rescue block to catch exceptions and return standardized error shape
- `AgentSpawnerService` extracts `run_agent` method to reduce cyclomatic complexity from 11 to 5
- `ComparisonReporter` matches dimensions by name instead of index for robust comparison
- `ComparisonReporter` uses `to_h` instead of `map{}.to_h` for dimension lookup
- `ExitCodeCalculator` handles both Hash and object report types for verdict extraction
- `JudgeParamsBuilder` catches specific exceptions (KeyError, NoMethodError) and removes useless rescue
- `ProviderResolver` catches config loading errors (JSON::ParserError, ArgumentError, Errno::ENOENT) with fallback to mock
- `VariantResolver` adds require for `ManifestFinder` to fix load order
- `VariantResolver` raises ArgumentError on unknown variant types instead of returning nil
- `ProviderResolverTest` resets Config state in teardown to prevent test leakage
- `CompareCommandTest` wraps stdout capture in begin/ensure for exception safety
- `CompareCommandTest` removes duplicate variant parser tests (already in variant_parser_test.rb)
- `RunnerServiceTest` updated to expect mock provider fallback instead of raising on missing config

### Security
- **CRITICAL:** `allowed_commands` nil default no longer allows unrestricted command execution — now returns clear error
- Sandbox copies dotfiles (hidden files) instead of skipping them via `Dir.glob('*')`
- Sandbox validates symlinks don't escape source directory before copying
- `allowed_commands` error message no longer discloses the full allowlist to the agent
- Judge prompt uses UUID-based delimiters to prevent XML tag breakout injection
- Judge escapes `</` sequences in user-provided content before interpolation
- Docker sandbox gracefully skips when Dockerfile is missing (prevents host execution without isolation)
- `Provider.merged_config` error message no longer discloses exact ENV variable name
- `Migration::ProviderMigrator` disables YAML aliases (`aliases: false`) to prevent amplification attacks
- `EvaluateCommand#safe_expand_path` now resolves symlinks with `File.realpath` before boundary validation; rejects `ENOENT`/`EACCES`
- `SkillResolver#resolve_by_path` uses path-separator-aware prefix match (`cwd + File::SEPARATOR`) to prevent sibling-directory bypass
- `ContextHydrator#collect_context_files` explicitly rejects `File.symlink?(f)` before inclusion
- `OutputFormatter#format_junit` now defensively XML-escapes `score` in failure message attributes
- `ResponseParser#strip_markdown_fences` guards against `nil`/`non-String` input
- `BaseClient` now explicitly requires `retry_handler` (removes load-order dependency)
- Legacy evaluation pipeline (`EvaluateCommand`, `Runner`, `TaskEvaluator`, and associated services) marked `@deprecated` and removed from `skill_bench.rb` require chain

### Removed
- `ScoringService` dead code: `DEFAULT_FAIL_THRESHOLD` and `fail_threshold` (never used in scoring logic)
- `Config.load` redundant `recursive_symbolize_keys` (JSON.parse already symbolizes keys)
- `RunnerService` useless `@resolve_provider ||=` memo (instances are single-use)
- `Provider` ActiveSupport dependency for `deep_symbolize_keys` (replaced with manual symbolization)
- `lib/skill_bench/mcp/` directory — MCP server stub (never required, dead code)

### Quality
- 631 tests, 0 failures
- 91.82% line coverage
- Rubocop: 0 offenses
- Reek: 0 warnings

## [0.1.0] - 2026-05-07

### Added
- Deterministic scoring engine (`ScoringService`) with composite scoring: test pass rate (50%), timing compliance (30%), error handling (20%)
- Hierarchical configuration loading: code defaults → home JSON → local JSON → environment variables
- `criteria.json` integration with configurable pass/fail thresholds
- 7 LLM providers: OpenAI, Anthropic, Gemini, Azure OpenAI, Ollama, Groq, DeepSeek
- OpenCode provider support
- 4 core CLI commands: `init`, `run`, `skill new`, `eval new`
- Rails skill templates: service object, concern, ActiveRecord model
- Git sandbox isolation for all evaluation runs
- ReAct loop with tool execution (run_command, read_file, write_file)
- LLM-powered judge for code diff evaluation
- JUnit XML output for CI/CD integration
- Benchmark history persistence with atomic writes

### Changed
- Renamed from `agent-eval` to `ruby-skill-bench`
- Merged `Evaluator::` and `AgentEval::` namespaces into `SkillBench::`
- Renamed CLI executable from `evaluate` to `skill-bench`
- Config file format from `.agent-eval.yml` to `.skill-bench.json`
- Increased LLM request timeout from 10s to 120s (configurable)
- Replaced `puts` with `warn` for debug output in ReAct loop

### Security
- `ContextHydrator` now escapes file paths with `CGI.escapeHTML` to prevent XML injection
- `Sandbox.capture_diff` validates sandbox directory is within temp directory to prevent path traversal
- `Provider.merged_config` validates provider name against allowlist before env var interpolation
- `Sandbox` now explicitly requires `open3` (was implicitly loaded)
- `ReactAgent::Step` duplicates messages array to prevent caller mutation
- `OutputFormatter.format_junit` escapes failure message content in XML attributes
- Path validation to prevent directory traversal in eval paths
- URL parameter sanitization with `CGI.escape` for all provider endpoints
- YAML Symbol DoS prevention (`permitted_classes: []`)
- Atomic file writes with `flock` to prevent race conditions
- `EVALUATOR_HISTORY_FILE` path validation against allowed prefixes

### Fixed
- `Config.reset` now applies full pipeline (defaults → JSON → ENV)
- Nil-safety across agent response handling
- Judge response key type mismatch (symbol vs string)
- `Dir.home` crash in container environments
- AgentRunner return type confusion in TaskEvaluator

### Quality
- 317 tests, 0 failures
- 89.9% line coverage
- Rubocop: 0 offenses
- Reek: 0 warnings
