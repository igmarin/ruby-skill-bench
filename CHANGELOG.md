# Changelog

All notable changes to the `agent-eval` gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New LLM provider: **Anthropic Claude** support via Messages API (`lib/clients/providers/anthropic.rb`)
- **ProviderRegistry** system for extensible provider lookup (replaces hard-coded case statements)
  - `lib/clients/provider_registry.rb` - Central registry for all providers
  - Providers self-register using `ProviderRegistry.register(:name, self)`
  - Returns `NullClient` for unregistered providers
- **TaskEvaluator** service object for single task evaluation
- **TaskFileReader** service object for safe file I/O with error handling
- `set_provider_base_url` method to Config facade for Ollama base URL configuration
- Comprehensive test coverage for ProviderRegistry (4 new tests)
- Runner error path tests (missing `task.md`, missing `criteria.json`)
- YARD `@raise` tags to `BaseClient` public methods
- README files updated with code references across all directories:
  - `lib/README.md` - Updated with provider list and architecture links
  - `lib/clients/README.md` - New file with provider documentation
  - `lib/evaluator/README.md` - Updated with code links
  - `lib/tools/README.md` - Updated with code references
  - `lib/react_agent/README.md` - Updated with code links
- `doc/` and `tmp/rubycritic/` added to `.gitignore`

### Changed
- **Refactored Runner** to follow Single Responsibility Principle:
  - Extracted `TaskEvaluator` for single task orchestration
  - Extracted `TaskFileReader` for safe file I/O
  - Removed console output (`puts`) from Runner, AgentRunner, and LoopRunner
- **Standardized service object return contracts**:
  - All services now return `{ success: bool, response: { ... } }`
  - `Dispatcher` returns raw tool output (not wrapped in hash)
  - `Judge` returns structured responses
  - `ProviderRegistry.for()` replaces case statement in `Client`
- **Updated all provider require statements** in `lib/client.rb` (added Anthropic)
- **ProviderRegistry** now requires `NullClient` internally for self-containment

### Fixed
- **Ollama implementation**:
  - Fixed `valid_config?` (removed redundant `!!@model` check)
  - Fixed tautological test `test_base_url_uses_config_when_set`
  - Removed redundant `attr_reader` (inherited from BaseClient)
  - Added `set_provider_base_url` to Config facade
- **Reek warnings**: 0 total warnings (fixed InstanceVariableAssumption, FeatureEnvy, UtilityFunction)
- **Rubocop offenses**: 0 total offenses (fixed AssertRaisesWithRegexpArgument)
- **Test isolation**:
  - ProviderRegistry tests save/restore original state
  - Ollama tests call `Config.reset` for clean state
  - Runner tests use proper Judge stubs (hash format, not strings)
- **Dispatcher behavior**: Reverted to raw tool output, re-raises exceptions (not error hashes)
- **TaskEvaluator**: Propagates Judge failures instead of embedding them in success payload
- **Runner**: Normalizes task results to uniform envelope, computes overall success flag
- **CI issues**:
  - Fixed Bundler version mismatch (locked to 2.6.9)
  - Removed Ruby 3.1 from CI matrix (public_suffix requires >= 3.2)
- **NullClient**: Now extends `BaseClient` for interface consistency

### Removed
- Console output (`puts`) from Runner, AgentRunner, and LoopRunner
- Inline `:reek:` comments (moved to `.reek.yml`)
- Auto-generated documentation from `doc/` folder (added to `.gitignore`)

### Security
- All service objects follow error logging standards (message AND backtrace)
- Dispatcher re-raises exceptions for proper error propagation

## [0.0.1] - 2024-05-04

### Added
- Initial release of `agent-eval`
- Support for OpenAI and Gemini providers
- ReAct loop implementation
- Side-by-side evaluation (baseline vs context-hydrated)
- LLM-powered judging
- Tool system (read_file, write_file, run_command)
- Sandbox isolation with Git diff capture
- Basic test suite
