# Ruby Skill Bench
<img width="800" height="429" alt="agent-eval-logo" src="https://github.com/user-attachments/assets/71688c48-af32-4c6d-87aa-dc2a2865e448" />

*A high-fidelity evaluation engine for benchmarking AI agent skills across any stack (Rails-first, but extensible).*

---

## Features

- **Side-by-Side Evaluation**: Quantify the "ROI of Context" by comparing baseline vs. skill-enhanced agent runs.
- **Isolated Git Sandboxes**: Every run operates in a temporary repo. Clean diffs, zero side-effects, 100% reproducibility.
- **Blind Judging with Dimensions**: LLM judge scores baseline and context independently across 5 canonical dimensions (Correctness, Skill Adherence, Code Quality, Test Coverage, Documentation). Eval authors configure weights and thresholds via `criteria.json`.
- **Sophisticated ReAct Loop**: Employs a robust `Thought → Tool → Observation` loop to handle complex, multi-step engineering tasks.
- **Multi-Provider Ecosystem**: Native support for **OpenAI**, **Anthropic**, **Google Gemini**, **Azure OpenAI**, **Ollama**, **Groq**, **DeepSeek**, and **OpenCode**.
- **Standardized Intelligence**: Consistent reporting format regardless of the underlying LLM provider.

---

## Architecture Overview

The system decoupling allows the reasoning engine to remain agnostic of the execution environment.

```text
CLI / API → RunnerService → Sandbox + ReAct Agent → LLM Client Layer → Provider
                                                              ↓
                                         EvaluationRunner (baseline + context)
                                                              ↓
                                                    Judge (blind scoring)
                                                              ↓
                                                    DeltaReport
```

---

## Configuration & Orchestration

### Environment Variable Mapping

| Provider | Required Env Variables | Registry Key |
| :--- | :--- | :--- |
| **OpenAI** | `SKILL_BENCH_OPENAI_API_KEY` | `:openai` |
| **Anthropic** | `SKILL_BENCH_ANTHROPIC_API_KEY` | `:anthropic` |
| **Gemini** | `SKILL_BENCH_GEMINI_API_KEY` | `:gemini` |
| **Azure** | `SKILL_BENCH_AZURE_API_KEY` | `:azure` |
| **Ollama** | — | `:ollama` |
| **Groq** | `SKILL_BENCH_GROQ_API_KEY` | `:groq` |
| **DeepSeek** | `SKILL_BENCH_DEEPSEEK_API_KEY` | `:deepseek` |
| **OpenCode** | `SKILL_BENCH_OPENCODE_API_KEY` | `:opencode` |

> **Note:** Environment variables are loaded automatically. You can also configure provider settings in `skill-bench.json` (created by `skill-bench init`).

### Command Allowlist

By default, no shell commands are permitted. You must configure `allowed_commands` in `skill-bench.json`:

```json
{
  "provider": "openai",
  "max_execution_time": 30,
  "allowed_commands": ["rspec", "bundle", "ruby", "git"],
  "config": {
    "api_key": null,
    "model": "gpt-4o"
  }
}
```

> **Security:** The agent can only execute commands on this list. Dangerous commands (bash, curl, sudo, etc.) are always blocked regardless of configuration.

### Configuration Hierarchy

Configuration is loaded in this order (later sources override earlier ones):

1. **Code defaults** — built-in defaults for provider, model, and timeout
2. **Home JSON** — `~/.skill-bench.json` for user-wide settings
3. **Local JSON** — `./skill-bench.json` for project-specific settings
4. **Environment variables** — provider API keys and models from `ENV`

---

## Getting Started

### Installation
```bash
gem install ruby-skill-bench
```

Or add to your `Gemfile`:
```ruby
gem 'ruby-skill-bench'
```

### Usage: The 4-Step Flow

#### 1. Initialize Configuration
```bash
skill-bench init --openai
```
This creates `skill-bench.json` with the provider config. Use `--force` to overwrite.

**Available providers:** `--openai`, `--anthropic`, `--gemini`, `--ollama`, `--azure`, `--groq`, `--deepseek`, `--opencode`

#### 2. Create a Skill
```bash
skill-bench skill new my-service --mode=rails --template=service_object
```
Creates `skills/my-service/SKILL.md` with the specified template.

#### 3. Create an Eval
```bash
skill-bench eval new my-first-eval --runtime=rails
```
Creates `evals/my-first-eval/` with `task.md` and `criteria.json`.

#### 4. Run the Eval
```bash
skill-bench run my-first-eval --skill=my-service
```
Provider is read from `skill-bench.json` — no `--provider` flag needed.

**Output Formats:**
- Human-readable (default)
- JSON: `--format json`
- JUnit XML: `--format junit`

---

## Scoring Engine

The engine runs every eval **twice** — once without skill context (baseline) and once with skill context — then uses an LLM judge to score both outputs independently across configurable dimensions.

### Canonical Dimensions

| Dimension | Default Description |
|-----------|---------------------|
| Correctness | Does the output fulfill the task requirements? |
| Skill Adherence | Did the agent follow patterns defined in the skill? |
| Code Quality | Is the code clean, well-structured, and free of smells? |
| Test Coverage | Are there meaningful tests following best practices? |
| Documentation | Is there adequate YARD documentation and clear intent? |

### `criteria.json` Format

```json
{
  "context": "Evaluate whether the skill helps build a proper API REST collection",
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 25 },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15 },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

**Rules:**
- `dimensions` max_scores must sum to exactly 100.
- `pass_threshold` is the minimum context score to pass (default 70).
- `minimum_delta` is the minimum total improvement over baseline (default 10).
- Dimension descriptions can be overridden per eval by adding a `description` field.

---

## Reliability & Security

- **Safe-by-Design**: No code execution occurs on the host system; everything happens in the sandbox.
- **Command Blocklist**: Dangerous commands (`bash`, `sh`, `python`, `curl`, etc.) are always blocked, even if listed in `allowed_commands`.
- **Path Validation**: Eval paths are validated to prevent directory traversal attacks.
- **Atomic History Writes**: Benchmark history uses file locking to prevent corruption from concurrent writes.
- **URL Sanitization**: All provider URL parameters are CGI-escaped to prevent injection.
- **YAML Safety**: Config loading uses `permitted_classes: []` to prevent symbol DoS attacks.
- **Traceability**: Every thought and tool call is logged with full backtrace for post-mortem analysis.
- **Robust Error Recovery**: Handles provider outages and rate limits gracefully with standardized error logging.
- **XML-Safe Output**: JUnit XML output is properly escaped to prevent injection attacks.
- **Test Coverage**: 373+ tests covering core engine, CLI commands, and all provider clients.

## Testing

The project uses Minitest with WebMock for HTTP stubbing.

```bash
# Run all tests
bundle exec rake test

# Run with coverage
bundle exec rake test COVERAGE=true

# Run specific test file
bundle exec ruby -Itest test/integration_test.rb
```

**Test Structure:**
- `test/evaluator/` — Core evaluation engine tests
- `test/agent_eval/` — CLI, models, and service tests
- `test/clients/` — Provider client tests

## CI/CD Integration

GitHub Actions workflow included (`.github/workflows/ci.yml`):
- Runs on push and pull requests
- Tests against Ruby 3.3 and 3.4
- Executes rubocop, reek, and minitest
- Outputs JUnit XML for test reporting

```bash
# Run locally with CI output
skill-bench run my-eval --skill=my-skill --format json
```

---

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
