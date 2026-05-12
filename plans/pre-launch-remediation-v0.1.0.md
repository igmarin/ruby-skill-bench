# Pre-Launch Remediation Plan v0.1.0

## Overview

Pre-launch security, UX, and code quality fixes for ruby-skill-bench before the first public release.

---

## Phase 0: Foundation

### 0.1 Rubocop & Reek Baseline
- [x] Run `bundle exec rubocop` and capture all offenses
- [x] Run `bundle exec reek` and capture all code smells
- [x] Update `.reek.yml` to suppress smells that are intentional architectural decisions
- [x] Ensure both tools pass cleanly before any code changes
- [ ] **REMAINING:** 3 rubocop offenses introduced by Phase 1.2 changes (see notes below)

### 0.2 Test Suite Gate
- [x] Run `bundle exec rake test` — confirm 491 pass, 0 failures
- [x] This is the **characterization test suite** — it must remain green after every change
- [x] **CURRENT STATUS:** 499 pass, 0 failures, 0 errors

---

## Phase 1: Critical — User Experience Killers

### 1.1 Fix RunnerService Silent Config Errors → Clear Error Messages
**File:** `lib/skill_bench/services/runner_service.rb`
**TDD:**
- [x] (a) Write failing spec — when `merged_config` raises `ArgumentError`, expect the error message to be propagated, not swallowed
- [x] (b) Run spec — verify it fails with "mock provider" fallback
- [x] (c) Refactor `resolve_provider` and `spawn_agent` to rescue only `ArgumentError` and include the original message in the warning
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 499 pass

**Changes made:**
- Extracted `resolve_provider_config` method that returns a result envelope `{ success: bool, config: Hash | error: Exception }`
- `call` method now returns a clear `config_error_result` immediately when provider config is invalid
- Added `config_error_result` private method for standardized error formatting
- Added `test_call_returns_config_error_when_api_key_missing` test

**Code standards:** Service Object, SRP, YARD `@raise`

---

### 1.2 Fix OpenCode Environment Variable Mismatch
**Files:** `lib/skill_bench/config/env_overrides.rb`, `lib/skill_bench/models/provider.rb`
**TDD:**
- [x] (a) Write failing spec — `SKILL_BENCH_OPENCODE_BASE_URL` should be mapped to `opencode.base_url`
- [x] (b) Run spec — verify fails
- [x] (c) Update `ENV_TO_PROVIDER_SETTINGS` to support `SKILL_BENCH_` prefixed variants for all provider settings
- [x] (d) Run spec — verify passes
- [x] (e) Update `Provider.merged_config` to support `SKILL_BENCH_<PROVIDER>_<SETTING>`, `_MODEL`, `_ENDPOINT`, etc.
- [x] (f) Run full suite — verify 499 pass

**Changes made:**
- `EnvOverrides`: Added `SKILL_BENCH_*` prefixed variants for ALL providers and settings. Also added missing providers (groq, deepseek, openrouter).
- `Provider.merged_config`: Complete rewrite. Now resolves ALL settings (`api_key`, `model`, `base_url`, `endpoint`, `location`, `project_id`, `api_version`) from env vars.
- Supports both `SKILL_BENCH_<PROVIDER>_<SETTING>` (documented standard) and `<PROVIDER>_<SETTING>` (legacy backward compatibility).
- Prefixed env vars take precedence over legacy ones.
- Added `test/evaluator/models/provider_test.rb` with 7 tests covering all env var resolution scenarios.
- Added env var isolation to `test/integration_test.rb` and `test/agent_eval/services/runner_service_test.rb` to prevent shell env from leaking into tests.

**Code standards:** DRY, YARD docs, SRP

**NOTE:** This change introduced 3 rubocop offenses that autocorrect could not fully resolve. Run `bundle exec rubocop` to identify and fix.

---

### 1.3 Fix HelpPrinter Missing CLI Features
**File:** `lib/skill_bench/cli/help_printer.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/cli/help_printer_test.rb` — assert help text contains `--format`, `eval generate`, and multi-skill note
- [ ] (b) Run spec — verify fails
- [ ] (c) Update `HelpPrinter` to include all missing flags and subcommands
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** YAGNI (only document what exists), YARD docs

---

### 1.4 Fix JUnit XML Output
**File:** `lib/skill_bench/output_formatter.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/output_formatter_test.rb` — format a modern `DeltaReport` result as JUnit, assert verdict and score are correct
- [ ] (b) Run spec — verify fails (JUnit currently uses legacy `result[:pass]`)
- [ ] (c) Refactor `format_junit` to read from `result[:response][:report].verdict` and compute score from `baseline_total`/`context_total`
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** Service Object, SRP, YARD `@param`

---

### 1.5 Fix EvalNew Default Runtime
**File:** `lib/skill_bench/commands/eval_new.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/commands/eval_new_test.rb` — assert default runtime is `'ruby'` when not provided
- [ ] (b) Run spec — verify fails (currently `'generic'`)
- [ ] (c) Change default from `'generic'` to `'ruby'`
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** YAGNI

---

## Phase 2: High — Security & Stability

### 2.1 Fix Path Traversal in `safe_expand_path`
**File:** `lib/skill_bench/evaluate_command.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/evaluate_command_test.rb` — absolute path `/etc/passwd` should raise `ArgumentError`
- [ ] (b) Run spec — verify fails
- [ ] (c) Refactor `safe_expand_path` to always validate against CWD, not just when `..` is present
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** SRP, YARD `@raise`

---

### 2.2 Fix ContextHydrator Symlink Following
**File:** `lib/skill_bench/context_hydrator.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/context_hydrator_test.rb` — symlink in skill dir pointing outside should be rejected
- [ ] (b) Run spec — verify fails
- [ ] (c) Add symlink check in `collect_context_files` (reject `File.symlink?(f)`)
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** DRY (reuse validation pattern from `Sandbox`)

---

### 2.3 Fix SkillResolver Absolute Path Validation
**File:** `lib/skill_bench/services/skill_resolver.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/services/skill_resolver_test.rb` — `--skill=/absolute/path` outside project should raise
- [ ] (b) Run spec — verify fails
- [ ] (c) Add boundary check in `resolve_by_path` to ensure path is within `skills/` or CWD
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** SRP

---

### 2.4 Fix `OptionParserService` Calling `exit` in Library Code
**File:** `lib/skill_bench/services/option_parser_service.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/services/option_parser_service_test.rb` — `--help` should raise `HelpRequested`, not call `exit`
- [ ] (b) Run spec — verify fails
- [ ] (c) Replace `exit` with `raise SkillBench::HelpRequested`
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** SRP

---

### 2.5 Fix `HistoryRecorder` Default Path Inside Gem Directory
**File:** `lib/skill_bench/history_recorder.rb`
**TDD:**
- [ ] (a) Write failing spec: `test/history_recorder_test.rb` — default path should resolve to CWD, not gem dir
- [ ] (b) Run spec — verify fails
- [ ] (c) Update `HISTORY_FILE` to use `BenchmarkRecorder::DEFAULT_HISTORY_FILE` or equivalent CWD-based resolution
- [ ] (d) Run spec — verify passes
- [ ] (e) Run full suite — verify 491 pass

**Code standards:** DRY

---

## Phase 3: Medium — Code Quality & Cleanup

### 3.1 Unify Environment Variable Naming Convention
**Files:** `lib/skill_bench/config/env_overrides.rb`, `lib/skill_bench/models/provider.rb`, `README.md`
**Status:** COMPLETED as part of Phase 1.2
- [x] (a) Write failing spec — both `OPENAI_API_KEY` and `SKILL_BENCH_OPENAI_API_KEY` should work
- [x] (b) Run spec — verify fails for prefixed variant
- [x] (c) Update `EnvOverrides` to check both prefixed and unprefixed variants
- [x] (d) Run spec — verify passes
- [ ] (e) Update README to document only the `SKILL_BENCH_*` convention
- [x] (f) Run full suite — verify 499 pass

---

### 3.2 Remove or Deprecate Legacy Evaluation Pipeline
**Files:** `lib/skill_bench/evaluate_command.rb`, `lib/skill_bench/runner.rb`, `lib/skill_bench/task_evaluator.rb`, `lib/skill_bench/services/result_printer_service.rb`, `lib/skill_bench/services/judge_score_parser_service.rb`, `lib/skill_bench/services/option_parser_service.rb`, `lib/skill_bench/services/output_persistence_service.rb`
**TDD:**
- [ ] (a) Verify these files are NOT required by `lib/skill_bench.rb` or the CLI path
- [ ] (b) Run full suite — verify 491 pass with files removed from require chain
- [ ] (c) Either delete files or add `@deprecated` YARD tags and remove from `skill_bench.rb` require
- [ ] (d) Run full suite — verify 491 pass

**Code standards:** YAGNI

---

### 3.3 Fix `test_helper.rb` Loading All Files Alphabetically
**File:** `test/test_helper.rb`
**TDD:**
- [ ] (a) Replace glob require with `require_relative '../lib/skill_bench'`
- [ ] (b) Run full suite — verify 491 pass

**Code standards:** DRY

---

### 3.4 Fix SimpleCov Rails Profile
**File:** `test/test_helper.rb`
- [ ] (a) Change `SimpleCov.start 'rails'` to `SimpleCov.start`
- [ ] (b) Run full suite — verify 491 pass and coverage report is generated correctly

---

### 3.5 Remove MCP Server Stub
**File:** `lib/skill_bench/mcp/server.rb`
- [ ] (a) Remove `lib/skill_bench/mcp/` directory and its require from `skill_bench.rb`
- [ ] (b) Run full suite — verify 491 pass

**Code standards:** YAGNI

---

## Phase 4: Documentation & Final Verification

### 4.1 Update Inline YARD Documentation
- [x] Added YARD docs for `Provider.merged_config`, `Provider.resolve_env_setting`, `RunnerService.resolve_provider_config`, `RunnerService.config_error_result`
- [ ] Run `yard stats --list-undoc` and identify any remaining undocumented public methods

### 4.2 Final Linter Gate
- [ ] `bundle exec rubocop` — 0 offenses (currently 3 remaining after Phase 1.2)
- [x] `bundle exec reek` — 0 smells
- [x] Update `.reek.yml` if new intentional smells are introduced

### 4.3 Final Test Gate
- [x] `bundle exec rake test` — 499 pass, 0 failures, 0 errors, 0 skips
- [x] Coverage: 91.16%

---

## Completed Work Summary

### Phase 1.1: RunnerService Silent Config Errors ✅
- **Problem:** `RunnerService` silently swallowed ALL config errors and fell back to a mock provider, giving users no actionable error message.
- **Fix:** Refactored `call` to use a `resolve_provider_config` method that returns a result envelope. Only `ArgumentError` is rescued, and the original error message is propagated in a clear `Configuration error: ...` response.
- **Tests:** Added `test_call_returns_config_error_when_api_key_missing`.
- **Result:** Users now see "Configuration error: API key not found for provider 'openai'. Set SKILL_BENCH_OPENAI_API_KEY..." instead of "Config load failed, using mock provider."

### Phase 1.2: OpenCode Environment Variable Mismatch ✅
- **Problem:** README documented `SKILL_BENCH_OPENCODE_BASE_URL` but the code only read `OPENCODE_BASE_URL`. `Provider.merged_config` only resolved `api_key` from env vars, ignoring `base_url`, `model`, etc.
- **Fix:**
  - `EnvOverrides`: Added `SKILL_BENCH_*` prefixed variants for ALL provider settings across all 9 providers.
  - `Provider.merged_config`: Complete rewrite to resolve ALL settings from env vars, supporting both prefixed and legacy naming conventions.
- **Tests:** Added comprehensive `test/evaluator/models/provider_test.rb` with 7 tests.
- **Result:** OpenCode `base_url` now works via `SKILL_BENCH_OPENCODE_BASE_URL` as documented. All provider settings can be overridden via env vars.

### Ancillary Fixes (discovered during work)
- `.rubocop.yml`: Added `test/**/*` exclusion for `Metrics/ClassLength` (test classes are naturally long)
- `anthropic_test.rb`: Removed redundant `# rubocop:disable Metrics/ClassLength` directive
- `integration_test.rb` & `runner_service_test.rb`: Added env var isolation to prevent shell environment from leaking into tests

---

## Remaining Work (for next session)

1. **Fix 3 rubocop offenses** introduced by `Provider` changes — run `bundle exec rubocop` to identify
2. **Phase 1.3:** HelpPrinter missing CLI features
3. **Phase 1.4:** JUnit XML output broken
4. **Phase 1.5:** EvalNew default runtime mismatch
5. **Phase 2.1-2.5:** Security fixes (path traversal, symlink validation, skill resolver boundaries, exit in library, history path)
6. **Phase 3.1-3.5:** Code cleanup (legacy pipeline, test_helper, SimpleCov, MCP stub)
7. **Update README** to document only `SKILL_BENCH_*` env var convention

---

## Decisions Log

1. **HistoryRecorder vs BenchmarkRecorder:** `HistoryRecorder` will be updated to use the same CWD-based path as `BenchmarkRecorder`. Both are retained for now since they serve different callers.
2. **Legacy pipeline:** Will be marked `@deprecated` and removed from the require chain, not deleted entirely (preserves git history).
3. **Env var naming:** Support BOTH `SKILL_BENCH_*` and unprefixed variants for backward compatibility. Document only `SKILL_BENCH_*`.
4. **Path traversal:** Moved to Phase 2 (High) rather than Phase 1 (Critical) because the primary CLI path (`RunCommand` → `RunnerService`) does not use `EvaluateCommand`. However, it is still a security risk if the legacy path is invoked.
