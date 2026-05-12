# Changelog

All notable changes to `ruby-skill-bench` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- `Provider::ALLOWED_PROVIDERS` now derived from `ProviderSchemas.names` (single source of truth)
- `Config.store#assign_current_llm_provider` simplified from obfuscated array/grep pattern to simple conditional
- `ResponseErrorHandler.log_error` now delegates to `ErrorLogger` (DRY)
- `Sandbox` only starts Docker container when `docker` is available and Dockerfile exists
- `RunnerService` duplicated `provider.merged_config` rescue blocks extracted to `safe_merged_config` helper

### Fixed
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
- 513 tests, 0 failures
- 91.47% line coverage
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