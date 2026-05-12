# Config & Client Fixes — v0.1.0

**Status:** Planning — Awaiting Implementation

## Problem Statement

The `skill-bench run` command fails silently or with wrong errors for most non-OpenAI providers. Three root causes:

1. **Two parallel config systems exist but don't share state.** `Models::Config` (used by `RunnerService` → agent spawning) reads `skill-bench.json` correctly. But `Client` facade (used by `Judge` and `ReActAgent::Step`) reads from a separate `Config::Store` that uses a different JSON schema. The `init` command generates a format the `Client` facade can't parse.
2. **Judge never receives the API key.** `RunnerService` resolves the provider with its API key but `EvaluationRunner` and `Judge` never receive it — `Judge` calls `Client.call` with empty `client_params: {}`, relying on `Config.current_llm_provider` (defaults to `:openai`).
3. **Error results lack metadata.** When `EvaluationRunner` returns a failure, `eval_name`/`skill_name`/`provider_name` are not included, causing empty output fields.

Secondary issues:
- `ResponseParser#valid_message?` rejects messages with `content: null` even when valid `tool_calls` are present.
- No retry for transient HTTP errors (429, 503).

---

## Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Fix strategy | Pipe API key through pipeline (now) + unify config systems (follow-up plan) |
| 2 | `Client.call` provider override | Add optional `provider:` keyword argument to `Client.call` |
| 3 | Judge params | `RunnerService` passes provider config as `judge_params` through `EvaluationRunner` → `Judge` → `Client.call` |
| 4 | Auth method for non-OpenAI providers in Judge/ReAct | Explicitly pass `api_key:`, `model:`, `provider:` — the `Client.call(provider:)` override picks the correct client class |
| 5 | Response content validation | Accept `content: null` when `tool_calls` are present (valid LLM behavior) |
| 6 | Retry policy | Add 3-retry with exponential backoff for 429/503 in `BaseClient#execute_request` |
| 7 | Error result enrichment | `RunnerService` wraps `EvaluationRunner` failures with `eval_name`/`skill_name`/`provider_name` metadata |
| 8 | Backward compatibility | `Client.call` without `provider:` kwarg preserves existing `Config.current_llm_provider` fallback |
| 9 | Config format compatibility (Tech Debt) | Add `TechDebt` task to unify `Models::Config` and `Config::Store` in a follow-up plan |

---

## Architecture Changes

### Modified Classes

| Class | Change |
|-------|--------|
| `Client` | Add optional `provider:` keyword argument; when set, uses it instead of `Config.current_llm_provider` |
| `RunnerService` | Build `judge_params` hash from provider config (`api_key`, `model`, `provider` name); pass to `EvaluationRunner` |
| `EvaluationRunner` | Accept `judge_params:` keyword; pass through to `Judge.call` and embed in error results |
| `Judge` | Accept `client_params:` (already does); `EvaluationRunner` populates it with `judge_params` |
| `ResponseParser` | Fix `valid_message?` to accept `content: nil` when `tool_calls` are non-empty |
| `BaseClient` | Add retry with exponential backoff for 429/503 in `execute_request` |
| `RunnerService#call` | Wrap `EvaluationRunner.call` failures with metadata (`eval_name`, `skill_name`, `provider_name`) |
| `ReActAgent::Step` | Use `provider:` from `config[:client_params]` when present in `Client.call` (already passes `**config[:client_params]`) |

### New Files

| File | Purpose |
|------|---------|
| `lib/skill_bench/clients/retry_handler.rb` | Service object: retries HTTP requests with exponential backoff |

### Unchanged Classes

| Class | Notes |
|-------|-------|
| `Models::Config` | Stays as-is (System A) |
| `Models::Provider` | Stays as-is |
| `Config::Store` | Stays as-is (System B) |
| `Config::JsonLoader` | Stays as-is (fix in follow-up) |
| `Config::Applier` | Stays as-is |
| `Commands::Init` | Stays as-is (generates compatible format) |

### Omitted — Tech Debt

| Item | Reason |
|------|--------|
| Unify `Models::Config` + `Config::Store` | Requires format migration, backward compat. Will be a separate plan. |
| Update `Config::JsonLoader` to read init-command format | Requires careful dual-format parsing. Separate plan. |

---

## Hard Process Rules

These are **non-negotiable** for every implementation task:

1. **TDD**: Write failing test first, then implement. No exceptions.
2. **Service Object pattern**: Classes use `.call` class method as entry point.
3. **SRP**: Each class has one responsibility. Each method does one thing.
4. **Code review**: Self-review before marking task complete.
5. **YARD documentation**: Every public method gets `@param`, `@return`, `@raise` tags.
6. **Tests pass**: Full suite green before moving on. Run `bundle exec ruby -Ilib:test test/test_file.rb` for individual tests.
7. **`rubocop -A`**: Run and fix all offenses.
8. **`reek`**: Run and fix all warnings. If a warning makes no sense for the context, add it to `.reek.yml` — **never inline reek exclusions**.
9. **No implementation before test**: Tests are a GATE. Write test → run test → verify FAILS → implement → verify PASSES.
10. **User review checkpoint**: After ALL tasks in a phase are complete, user reviews and gives OK before continuing.

---

## Implementation Checklist

### Task 0: Setup

- [ ] 0.0 Create feature branch `feature/config-client-fixes`
- [ ] 0.1 Run full test suite and record baseline failures

### Task 1: Fix `ResponseParser#valid_message?` for null content + tool_calls

- [ ] 1.0a Write test: message with `content: nil` + non-empty `tool_calls` returns `valid_message? == true`
- [ ] 1.0b Write test: message with `content: nil` + empty `tool_calls` returns `valid_message? == false`
- [ ] 1.0c Write test: message with `content: nil` + no `tool_calls` returns `valid_message? == false`
- [ ] 1.0d Run tests — verify they FAIL
- [ ] 1.1a Implement fix in `Clients::ResponseParser.valid_message?`
- [ ] 1.1b Run tests — verify they PASS
- [ ] 1.1c Run `rubocop -A`, `reek`
- [ ] 1.1d Add/update YARD docs for `valid_message?`

### Task 2: Add `provider:` override to `Client.call`

- [ ] 2.0a Write test: `Client.call(provider: :deepseek, ...)` uses `Clients::Providers::DeepSeek`
- [ ] 2.0b Write test: `Client.call(provider: nil, ...)` falls back to `Config.current_llm_provider`
- [ ] 2.0c Write test: `Client.call(...)` without provider preserves backward compat
- [ ] 2.0d Run tests — verify they FAIL
- [ ] 2.1a Add `provider:` keyword argument to `Client.call`
- [ ] 2.1b Wire `provider` to `ProviderRegistry.for(provider)`
- [ ] 2.1c Run tests — verify they PASS
- [ ] 2.1d Run `rubocop -A`, `reek`
- [ ] 2.1e Add/update YARD docs for `Client.call`

### Task 3: Thread provider config through Judge pipeline

- [ ] 3.0a Write test: `RunnerService` passes `judge_params` to `EvaluationRunner` with `api_key`, `model`, `provider`
- [ ] 3.0b Write test: `EvaluationRunner` passes `client_params` to `Judge.call` with provider config
- [ ] 3.0c Write test: `Judge.call` passes `client_params` to `Client.call` as `**client_params`
- [ ] 3.0d Run tests — verify they FAIL
- [ ] 3.1a Update `RunnerService#call` to build `judge_params` from `provider.merged_config`
- [ ] 3.1b Add `judge_params:` keyword to `EvaluationRunner.call` and `#initialize`
- [ ] 3.1c Pass `judge_params` as `client_params:` in `EvaluationRunner#judge_run` → `Judge.call`
- [ ] 3.1d Run tests — verify they PASS
- [ ] 3.1e Run `rubocop -A`, `reek`
- [ ] 3.1f Add/update YARD docs

### Task 4: Enrich `EvaluationRunner` error results with metadata

- [ ] 4.0a Write test: `RunnerService` wraps `EvaluationRunner` failure with `eval_name`, `skill_name`, `provider_name`
- [ ] 4.0b Write test: `OutputFormatter.format_legacy_human` shows populated fields for wrapped error
- [ ] 4.0c Run tests — verify they FAIL
- [ ] 4.1a Update `RunnerService#call` to merge metadata into `EvaluationRunner` failure results
- [ ] 4.1b Run tests — verify they PASS
- [ ] 4.1c Run `rubocop -A`, `reek`
- [ ] 4.1d Add/update YARD docs

### Task 5: Add retry logic for transient HTTP errors

- [ ] 5.0a Write tests for `RetryHandler.call` — retries on 429, does not retry on 401/403, max 3 attempts, exponential backoff
- [ ] 5.0b Run tests — verify they FAIL
- [ ] 5.1a Create `lib/skill_bench/clients/retry_handler.rb` service object
- [ ] 5.1b Integrate `RetryHandler` into `BaseClient#execute_request`
- [ ] 5.1c Run tests — verify they PASS
- [ ] 5.1d Run `rubocop -A`, `reek`
- [ ] 5.1e Add/update YARD docs

### Task 6: Fix `ReActAgent::Step` to pass provider through `Client.call`

- [ ] 6.0a Write test: `Step.call(messages, config)` with `config[:provider]` in client_params passes it to `Client.call`
- [ ] 6.0b Run test — verify it FAILS
- [ ] 6.1a Update `Step.call` to extract `provider:` from `config[:client_params]` and pass to `Client.call`
- [ ] 6.1b Run test — verify it PASSES
- [ ] 6.1c Run `rubocop -A`, `reek`
- [ ] 6.1d Add/update YARD docs

### Task 7: Integration test — full pipeline with non-OpenAI provider

- [ ] 7.0a Write integration test: `RunnerService` with `deepseek` provider config, mock agent + mock judge, verify judge receives `api_key` + `model` + `provider` from agent config
- [ ] 7.0b Run test — verify it PASSES
- [ ] 7.0c Run full test suite — verify all green
- [ ] 7.0d Run `rubocop -A`, `reek`

### Task 8: Tech Debt — Log config system unification as follow-up

- [ ] 8.0a Create `plans/config-system-unification-v0.1.0.md` stub with problem statement and link to this plan
- [ ] 8.0b Note in this plan that Task 8 is the future unification of `Models::Config` + `Config::Store`

**Checkpoint: User review and OK**

---

## Relevant Files (Current)

### Core (must modify)
- `lib/skill_bench/client.rb` — Add `provider:` kwarg override
- `lib/skill_bench/services/runner_service.rb` — Build `judge_params` from provider, enrich error results
- `lib/skill_bench/evaluation_runner.rb` — Accept and forward `judge_params`
- `lib/skill_bench/judge.rb` — Already accepts `client_params:`; ensure it passes `provider:` through
- `lib/skill_bench/clients/response_parser.rb` — Fix `valid_message?` for null content + tool_calls
- `lib/skill_bench/clients/base_client.rb` — Add retry to `execute_request`
- `lib/skill_bench/react_agent/step.rb` — Pass `provider:` through to `Client.call`

### New files to create
- `lib/skill_bench/clients/retry_handler.rb` — Retry service object

### Tests to create/update
- `test/evaluator/clients/response_parser_test.rb` — New tests for null content + tool_calls
- `test/agent_eval/services/runner_service_test.rb` — Update for judge_params + error enrichment
- `test/evaluation_runner_test.rb` — Update for judge_params forwarding
- `test/judge_test.rb` — Update for client_params with provider
- `test/evaluator/clients/client_factory_test.rb` — New tests for provider override in Client.call
- `test/evaluator/clients/retry_handler_test.rb` — New tests for retry logic
- `test/integration_test.rb` — New integration test for non-OpenAI provider pipeline
- `test/react_agent/step_test.rb` — Update for provider passthrough

### Unchanged
- `lib/skill_bench/models/config.rb`
- `lib/skill_bench/models/provider.rb`
- `lib/skill_bench/config.rb`
- `lib/skill_bench/config/store.rb`
- `lib/skill_bench/config/json_loader.rb`
- `lib/skill_bench/config/applier.rb`
- `lib/skill_bench/config/defaults.rb`
- `lib/skill_bench/config/env_overrides.rb`
- `lib/skill_bench/commands/init.rb`

---

## New Files to Create

- `lib/skill_bench/clients/retry_handler.rb`
- `test/evaluator/clients/retry_handler_test.rb`

## Files to Modify

- `lib/skill_bench/client.rb`
- `lib/skill_bench/services/runner_service.rb`
- `lib/skill_bench/evaluation_runner.rb`
- `lib/skill_bench/judge.rb`
- `lib/skill_bench/clients/response_parser.rb`
- `lib/skill_bench/clients/base_client.rb`
- `lib/skill_bench/react_agent/step.rb`
- `test/evaluator/clients/response_parser_test.rb`
- `test/agent_eval/services/runner_service_test.rb`
- `test/evaluation_runner_test.rb`
- `test/judge_test.rb`
- `test/integration_test.rb`
