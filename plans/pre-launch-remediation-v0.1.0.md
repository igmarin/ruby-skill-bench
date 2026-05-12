# Pre-Launch Remediation Plan v0.1.0

## Overview

Pre-launch security, UX, and code quality fixes for ruby-skill-bench before the first public release.

**Current Status:** ALL PHASES COMPLETE. 511 tests pass, 0 failures, 0 errors. Rubocop: 0 offenses. Reek: 0 smells.

---

## Phase 0: Foundation

### 0.1 Rubocop & Reek Baseline
- [x] Run `bundle exec rubocop` and capture all offenses
- [x] Run `bundle exec reek` and capture all code smells
- [x] Update `.reek.yml` to suppress smells that are intentional architectural decisions
- [x] Ensure both tools pass cleanly

### 0.2 Test Suite Gate
- [x] Run `bundle exec rake test` — confirm 491 pass, 0 failures
- [x] This is the **characterization test suite** — it must remain green after every change
- [x] **CURRENT STATUS:** 512 pass, 0 failures, 0 errors

---

## Phase 1: Critical — User Experience Killers

### 1.1 Fix RunnerService Silent Config Errors → Clear Error Messages ✅
**File:** `lib/skill_bench/services/runner_service.rb`
**TDD:**
- [x] (a) Write failing spec — when `merged_config` raises `ArgumentError`, expect the error message to be propagated, not swallowed
- [x] (b) Run spec — verify it fails with "mock provider" fallback
- [x] (c) Refactor `resolve_provider` and `spawn_agent` to rescue only `ArgumentError` and include the original message in the warning
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 506 pass

**Changes made:**
- Extracted `resolve_provider_config` method that returns a result envelope `{ success: bool, config: Hash | error: Exception }`
- `call` method now returns a clear `config_error_result` immediately when provider config is invalid
- Added `config_error_result` private method for standardized error formatting
- Added `test_call_returns_config_error_when_api_key_missing` test

**Code standards:** Service Object, SRP, YARD `@raise`

---

### 1.2 Fix OpenCode Environment Variable Mismatch ✅
**Files:** `lib/skill_bench/config/env_overrides.rb`, `lib/skill_bench/models/provider.rb`
**TDD:**
- [x] (a) Write failing spec — `SKILL_BENCH_OPENCODE_BASE_URL` should be mapped to `opencode.base_url`
- [x] (b) Run spec — verify fails
- [x] (c) Update `ENV_TO_PROVIDER_SETTINGS` to support `SKILL_BENCH_` prefixed variants for all provider settings
- [x] (d) Run spec — verify passes
- [x] (e) Update `Provider.merged_config` to support `SKILL_BENCH_<PROVIDER>_<SETTING>`, `_MODEL`, `_ENDPOINT`, etc.
- [x] (f) Run full suite — verify 506 pass

**Changes made:**
- `EnvOverrides`: Added `SKILL_BENCH_*` prefixed variants for ALL providers and settings. Also added missing providers (groq, deepseek, openrouter).
- `Provider.merged_config`: Complete rewrite. Now resolves ALL settings (`api_key`, `model`, `base_url`, `endpoint`, `location`, `project_id`, `api_version`) from env vars.
- Supports both `SKILL_BENCH_<PROVIDER>_<SETTING>` (documented standard) and `<PROVIDER>_<SETTING>` (legacy backward compatibility).
- Prefixed env vars take precedence over legacy ones.
- Added `test/evaluator/models/provider_test.rb` with 7 tests covering all env var resolution scenarios.
- Added env var isolation to `test/integration_test.rb` and `test/agent_eval/services/runner_service_test.rb` to prevent shell env from leaking into tests.

**Code standards:** DRY, YARD docs, SRP

---

### 1.3 Fix HelpPrinter Missing CLI Features ✅
**File:** `lib/skill_bench/cli/help_printer.rb`
**TDD:**
- [x] (a) Write failing spec — assert help text contains `--format`, `eval generate`, and multi-skill note
- [x] (b) Run spec — verify fails
- [x] (c) Update `HelpPrinter` to include all missing flags and subcommands
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 506 pass

**Changes made:**
- Added `--format FORMAT` flag documentation (human, json, junit)
- Added `eval generate` subcommand documentation
- Added note that `--skill` can be specified multiple times
- Added `test_call_includes_format_flag`, `test_call_includes_eval_generate_subcommand`, `test_call_notes_multi_skill_support`

**Code standards:** YAGNI (only document what exists), YARD docs

---

### 1.4 Fix JUnit XML Output ✅
**File:** `lib/skill_bench/output_formatter.rb`
**TDD:**
- [x] (a) Write failing spec — format a modern `DeltaReport` result as JUnit, assert verdict and score are correct
- [x] (b) Run spec — verify fails (JUnit currently uses legacy `result[:pass]`)
- [x] (c) Refactor `format_junit` to read from `result[:response][:report].verdict` and compute score from `baseline_total`/`context_total`
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 506 pass

**Changes made:**
- `format_junit` now checks for `result.dig(:response, :report)` first (modern DeltaReport format)
- Falls back to legacy `result[:pass]` for backward compatibility
- Added `test_format_junit_with_delta_report_pass` and `test_format_junit_with_delta_report_fail`

**Code standards:** Service Object, SRP, backward compatibility

---

### 1.5 Fix EvalNew Default Runtime ✅
**File:** `lib/skill_bench/commands/eval_new.rb`
**TDD:**
- [x] (a) Write failing spec — assert default runtime is `'ruby'` when not provided
- [x] (b) Run spec — verify fails (currently `'generic'`)
- [x] (c) Change default from `'generic'` to `'ruby'`
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 506 pass

**Changes made:**
- Changed default runtime from `'generic'` to `'ruby'` in `EvalNew.run`
- Updated YARD comment to reflect the new default
- Updated `test_run_creates_generic_eval` to `test_run_creates_eval_with_default_runtime` and added assertion for `'Evaluate ruby task'` context

**Code standards:** YAGNI

---

## Phase 2: High — Security & Stability

### 2.1 Fix Path Traversal in `safe_expand_path` ✅
**File:** `lib/skill_bench/evaluate_command.rb`
**TDD:**
- [x] (a) Write failing spec — absolute path `/etc/passwd` should raise `ArgumentError`
- [x] (b) Run spec — verify fails
- [x] (c) Refactor `safe_expand_path` to always validate against CWD, not just when `..` is present
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 506 pass

**Changes made:**
- Replaced the `..`-only check with `Pathname#relative_path_from` check
- Now validates ALL paths (relative and absolute) against the current working directory
- Uses `relative.start_with?('..')` to detect paths that escape the CWD
- Added `require 'pathname'` to the file
- Added `test_safe_expand_path_rejects_absolute_paths_outside_cwd` and `test_safe_expand_path_allows_paths_within_cwd`

**Discovered and fixed during work:**
- `test/agent_eval/commands/eval_new_test.rb` had a teardown bug: `Dir.chdir('/')` broke test isolation for all subsequent tests. Fixed to restore `@original_dir`.

**Code standards:** SRP, YARD `@raise`

---

### 2.2 Fix ContextHydrator Symlink Following ✅
**File:** `lib/skill_bench/context_hydrator.rb`
**TDD:**
- [x] (a) Write failing spec: `test/evaluator/context_hydrator_test.rb` — symlink in skill dir pointing outside should be rejected
- [x] (b) Run spec — verify fails
- [x] (c) Add symlink check in `collect_context_files` (reject `File.symlink?(f)`)
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 506 pass

**Changes made:**
- `collect_context_files` now rejects `File.symlink?(f)` before `File.size` check
- Added `test_rejects_symlinks` with 5 assertions

**Code standards:** DRY (reuse validation pattern from `Sandbox`)

---

### 2.3 Fix SkillResolver Absolute Path Validation ✅
**File:** `lib/skill_bench/services/skill_resolver.rb`
**TDD:**
- [x] (a) Write failing spec: `test/services/skill_resolver_test.rb` — `--skill=/absolute/path` outside project should raise
- [x] (b) Run spec — verify fails
- [x] (c) Add boundary check in `resolve_by_path` to ensure path is within CWD
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 511 pass

**Changes made:**
- `resolve_by_path` now validates that `File.expand_path(normalized_path)` starts with `File.expand_path(Dir.pwd)`
- Added 3 tests: `test_resolve_by_path_rejects_absolute_paths_outside_cwd`, `test_resolve_by_path_rejects_traversal_outside_cwd`, `test_resolve_by_path_allows_paths_within_cwd`

**Code standards:** SRP

---

### 2.4 Fix `OptionParserService` Calling `exit` in Library Code ✅
**File:** `lib/skill_bench/services/option_parser_service.rb`
**TDD:**
- [x] (a) Write failing spec: `test/evaluator/services/option_parser_service_test.rb` — `--help` should raise `HelpRequested`, not call `exit`
- [x] (b) Run spec — verify fails
- [x] (c) Replace `exit` with `raise SkillBench::HelpRequested`
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 511 pass

**Changes made:**
- `opts.on('-h', '--help', ...)` block now raises `SkillBench::HelpRequested` instead of calling `exit`
- Test updated from `assert_raises(SystemExit)` to `assert_raises(SkillBench::HelpRequested)`

**Code standards:** SRP

---

### 2.5 Fix `HistoryRecorder` Default Path Inside Gem Directory ✅
**File:** `lib/skill_bench/history_recorder.rb`
**TDD:**
- [x] (a) Write failing spec: `test/evaluator/history_recorder_test.rb` — default path should resolve to CWD, not gem dir
- [x] (b) Run spec — verify fails
- [x] (c) Update `HISTORY_FILE` from `File.join(__dir__, '..', 'benchmarks.json')` to `'benchmarks.json'`
- [x] (d) Run spec — verify passes
- [x] (e) Run full suite — verify 511 pass

**Changes made:**
- `HISTORY_FILE` constant now resolves relative to CWD instead of the gem installation directory

**Code standards:** DRY

---

## Phase 3: Medium — Code Quality & Cleanup

### 3.1 Unify Environment Variable Naming Convention ✅
**Files:** `lib/skill_bench/config/env_overrides.rb`, `lib/skill_bench/models/provider.rb`, `README.md`
**Status:** COMPLETED as part of Phase 1.2
- [x] (a) Write failing spec — both `OPENAI_API_KEY` and `SKILL_BENCH_OPENAI_API_KEY` should work
- [x] (b) Run spec — verify fails for prefixed variant
- [x] (c) Update `EnvOverrides` to check both prefixed and unprefixed variants
- [x] (d) Run spec — verify passes
- [x] (e) README already documents only `SKILL_BENCH_*` convention
- [x] (f) Run full suite — verify 511 pass

---

### 3.2 Remove or Deprecate Legacy Evaluation Pipeline ✅
**Files:** `lib/skill_bench/evaluate_command.rb`, `lib/skill_bench/runner.rb`, `lib/skill_bench/task_evaluator.rb`, `lib/skill_bench/services/result_printer_service.rb`, `lib/skill_bench/services/option_parser_service.rb`, `lib/skill_bench/services/judge_score_parser_service.rb`, `lib/skill_bench/services/output_persistence_service.rb`
**TDD:**
- [x] (a) Verified these files are NOT required by the modern CLI path (RunCommand → RunnerService)
- [x] (b) Removed from `lib/skill_bench.rb` require chain
- [x] (c) Added `@deprecated` YARD tags to all 7 legacy files; updated legacy tests with explicit `require_relative`
- [x] (d) Run full suite — verify 511 pass

**Code standards:** YAGNI

---

### 3.3 Fix `test_helper.rb` Loading All Files Alphabetically ✅
**File:** `test/test_helper.rb`
**TDD:**
- [x] (a) Replaced glob require with `require_relative '../lib/skill_bench'`
- [x] (b) Added missing `require_relative 'skill_bench/config'` to `lib/skill_bench.rb`
- [x] (c) Run full suite — verify 511 pass

**Code standards:** DRY

---

### 3.4 Fix SimpleCov Rails Profile ✅
**File:** `test/test_helper.rb`
- [x] (a) Changed `SimpleCov.start 'rails'` to `SimpleCov.start`
- [x] (b) Run full suite — verify 511 pass and coverage report is generated correctly (91.41%)

---

### 3.5 Remove MCP Server Stub ✅
**File:** `lib/skill_bench/mcp/server.rb`
- [x] (a) Removed `lib/skill_bench/mcp/` directory (was not required by `skill_bench.rb`)
- [x] (b) Run full suite — verify 511 pass

**Code standards:** YAGNI

---

## Phase 4: Documentation & Final Verification

### 4.1 Update Inline YARD Documentation ✅
- [x] Added YARD docs for `Provider.merged_config`, `Provider.resolve_env_setting`, `RunnerService.resolve_provider_config`, `RunnerService.config_error_result`
- [x] Added `@deprecated` YARD tags to all 7 legacy pipeline files
- [x] Run `yard stats --list-undoc` — 0 undocumented public methods (94.05% documented overall)

### 4.2 Final Linter Gate ✅
- [x] `bundle exec rubocop` — 0 offenses
- [x] `bundle exec reek` — 0 smells
- [x] `.reek.yml` updated with documented intentional exclusions

### 4.3 Final Test Gate ✅
- [x] `bundle exec rake test` — 511 pass, 0 failures, 0 errors, 0 skips
- [x] Coverage: 91.41%

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

### Phase 1.3: HelpPrinter Missing CLI Features ✅
- **Problem:** Built-in `--help` text was missing `--format`, `eval generate`, and multi-skill chaining.
- **Fix:** Updated `HelpPrinter` to include all missing flags and subcommands.
- **Tests:** Added 3 new tests for help text completeness.

### Phase 1.4: JUnit XML Output ✅
- **Problem:** JUnit output used legacy `result[:pass]` which is not populated by the modern pipeline.
- **Fix:** `format_junit` now reads from `result[:response][:report].verdict` first, with backward compatibility for legacy format.
- **Tests:** Added 2 new tests for DeltaReport-based JUnit output.

### Phase 1.5: EvalNew Default Runtime ✅
- **Problem:** Default runtime was `'generic'` but documentation and help text said `'ruby'`.
- **Fix:** Changed default from `'generic'` to `'ruby'`.
- **Tests:** Updated existing test to verify new default.

### Phase 2.1: Path Traversal in `safe_expand_path` ✅
- **Problem:** `safe_expand_path` only checked for `..` in paths, allowing absolute paths like `/etc/passwd` to bypass validation.
- **Fix:** Replaced with `Pathname#relative_path_from` check that validates ALL paths against CWD.
- **Tests:** Added 2 tests for path validation.
- **Bonus fix:** Discovered and fixed test isolation bug in `eval_new_test.rb` teardown (`Dir.chdir('/')` → restore original dir).

### Ancillary Fixes
- `.rubocop.yml`: Added `test/**/*` exclusion for `Metrics/ClassLength`
- `anthropic_test.rb`: Removed redundant `# rubocop:disable Metrics/ClassLength` directive
- `integration_test.rb` & `runner_service_test.rb`: Added env var isolation to prevent shell environment from leaking into tests

---

## Remaining Work

**ALL ITEMS COMPLETE.** No remaining work for this plan.

---

## Completed Work Summary (This Session)

### Phase 2.2: ContextHydrator Symlink Following ✅
- **Problem:** `Dir.glob` follows symlinks by default, allowing a malicious skill directory with a symlink pointing outside the project to exfiltrate files.
- **Fix:** Added `File.symlink?(f)` rejection in `collect_context_files` before the `File.size` check.
- **Tests:** `test_rejects_symlinks` with 5 assertions.

### Phase 2.3: SkillResolver Absolute Path Validation ✅
- **Problem:** `resolve_by_path` accepted any path containing `/`, including absolute paths and `..` traversal outside the project.
- **Fix:** `resolve_by_path` now validates that `File.expand_path(normalized_path)` starts with `File.expand_path(Dir.pwd)`.
- **Tests:** Added 3 tests for absolute path rejection, traversal rejection, and allowed paths within CWD.

### Phase 2.4: OptionParserService `exit` in Library Code ✅
- **Problem:** `--help` handler called `exit`, killing the Ruby process and making the class unusable in tests or programmatically.
- **Fix:** Replaced `exit` with `raise SkillBench::HelpRequested`.
- **Tests:** Updated `test_call_with_help_flag` to expect `SkillBench::HelpRequested`.

### Phase 2.5: HistoryRecorder Default Path Inside Gem Directory ✅
- **Problem:** `HISTORY_FILE` was `File.join(__dir__, '..', 'benchmarks.json')`, resolving to `lib/benchmarks.json` inside the gem installation directory.
- **Fix:** Changed to `'benchmarks.json'`, which resolves relative to CWD.
- **Tests:** Added `test_default_history_file_resolves_to_cwd`.

### Phase 3.2: Deprecate Legacy Evaluation Pipeline ✅
- **Files affected:** `evaluate_command.rb`, `runner.rb`, `task_evaluator.rb`, `result_printer_service.rb`, `option_parser_service.rb`, `judge_score_parser_service.rb`, `output_persistence_service.rb`
- **Changes:**
  - Removed all 7 files from `lib/skill_bench.rb` require chain
  - Added `@deprecated` YARD tags with modern replacements
  - Updated 7 legacy test files with explicit `require_relative` to load the files they test

### Phase 3.3: Fix `test_helper.rb` Glob Loading ✅
- **Problem:** `test_helper.rb` used `Dir.glob` to load ALL `.rb` files alphabetically, masking missing requires in `skill_bench.rb`.
- **Fix:** Replaced glob with `require_relative '../lib/skill_bench'`.
- **Bonus fix:** Added missing `require_relative 'skill_bench/config'` to `lib/skill_bench.rb` (the main `Config` class was only loaded by the glob).

### Phase 3.4: Fix SimpleCov Rails Profile ✅
- **Problem:** `SimpleCov.start 'rails'` was used in a non-Rails gem.
- **Fix:** Changed to `SimpleCov.start`.

### Phase 3.5: Remove MCP Server Stub ✅
- **Problem:** `lib/skill_bench/mcp/server.rb` was dead code (never required by `skill_bench.rb`).
- **Fix:** Removed the entire `lib/skill_bench/mcp/` directory.

---

## Decisions Log

1. **HistoryRecorder vs BenchmarkRecorder:** `HistoryRecorder` will be updated to use the same CWD-based path as `BenchmarkRecorder`. Both are retained for now since they serve different callers.
2. **Legacy pipeline:** Will be marked `@deprecated` and removed from the require chain, not deleted entirely (preserves git history).
3. **Env var naming:** Support BOTH `SKILL_BENCH_*` and unprefixed variants for backward compatibility. Document only `SKILL_BENCH_*`.
4. **Path traversal:** Fixed in `EvaluateCommand` (legacy path). The primary CLI path (`RunCommand` → `RunnerService`) was never vulnerable because it doesn't use `EvaluateCommand`.
