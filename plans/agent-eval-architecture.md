# Agent-Eval Architecture Plan

## 1. Context & Problem Statement
- Existing repo has skills (modular capabilities) and evals (test scenarios)
- Current gem requires code-level provider config → poor usability
- Feels like a library, not a tool
- Naming/scope unclear (rails-agent-eval vs agent-eval)
- Core value (skills + eval execution) not accessible via CLI
- UX for config/execution undefined

## 2. User & Scope Decisions
- Target: Rails-first hybrid (Rails primary, extensible to other stacks)
- Skill role: Combination (context injection + workflow script + runtime dependency)
- Provider: Agent runtime + LLM (e.g., OpenCode + OpenAI)
- First run setup: One-time `init` command to generate config
- Eval portability: Optional coupling (can specify runtime, default agnostic)
- MCP server: Optional add-on
- CI output: Both human-readable and machine-readable (JSON/JUnit)

## 3. Architecture Direction: Hybrid Dual-Mode
### Rationale
Aligns with all user decisions:
- Rails users get Ruby integration, general users get simple YAML/MD config
- Supports combination skill role (Ruby for complex logic, YAML/MD for simple)
- Optional eval coupling
- One-time init, both output formats

### Core Components
1. **Config System**: `.agent-eval.yml` (default) with YAML or Ruby override. Env var fallback for secrets (API keys).
2. **Skill System**: Dual mode (simple: YAML/MD; advanced: Ruby classes). Discovery via `skills/` directory or config-specified paths. Composition via workflow orchestration in advanced mode.
3. **Eval System**: Portable by default, optional runtime coupling. Structure: `task.md`, `criteria.json`, source code. Scoring via LLM or custom Ruby scorer.
4. **Provider Abstraction**: Register agent runtimes (subprocess or Ruby class) and LLMs. Configured via YAML, Ruby, or env vars. Fallback hierarchy: CLI flag > config file > env var.
5. **CLI**: Ruby gem with `agent-eval` executable. Supports interactive (local use) and scriptable (CI) modes.
6. **Output**: Human-readable terminal default, `--ci` flag for JSON/JUnit with pass/fail exit codes.

## 4. CLI Interface (First Version)
### Commands
| Command | Description | Flags |
|---------|-------------|-------|
| `agent-eval init [--rails]` | Generate `.agent-eval.yml` config. `--rails` adds Rails defaults | `--rails` |
| `agent-eval skill new <name> [--mode=simple|advanced]` | Scaffold new skill | `--mode` (default: simple) |
| `agent-eval eval new <name> [--runtime=rails|generic]` | Scaffold new eval | `--runtime` (default: generic) |
| `agent-eval run <eval> [--skill=<name>] [--provider=<runtime:llm>] [--ci]` | Run specified eval | `--skill`, `--provider`, `--ci` |
| `agent-eval list skills|evals|providers` | List available resources | - |
| `agent-eval score <eval> --result=<path>` | Score existing eval result | `--result` |

### Global Flags
- `--config=<path>`: Custom config file (default: `.agent-eval.yml`)
- `--verbose`: Debug logging
- `--no-mcp`: Disable optional MCP server

### Examples
```bash
# Initial setup
agent-eval init --rails

# Run eval with skill and provider
agent-eval run evals/refactor-controller --skill=skills/service-objects --provider=opencode:openai

# CI mode
agent-eval run evals/refactor-controller --ci
```

## 5. Implementation Steps (Mandatory TDD Workflow)
All steps MUST follow this strict flow:
1. Write failing test first (RED)
2. Implement minimal code to pass test (GREEN)
3. Run full test suite to verify all tests are GREEN
4. Run linters: `rubocop` and `reek` (configure .reek.yml to ignore acceptable warnings)
5. Add YARD documentation to all new methods
6. Add README.md to any new folder explaining its purpose and code structure
7. Verify tests still pass after changes

1. **Core Models**: Define `Skill`, `Eval`, `Provider`, `Config` classes with YARD docs. Test model validation/serialization.
2. **Init Command**: Implement `init` with `--rails` flag. Generate `.agent-eval.yml` with default and Rails-specific config. Test config generation.
3. **Scaffolding**: Implement `skill new` and `eval new` commands. Test scaffolding output matches spec.
4. **Provider Abstraction**: Build provider registry. Load runtimes (subprocess/Ruby class) and LLMs from config. Env var fallback for API keys. Test provider loading.
5. **Run Command Core**: Implement eval execution flow: load eval + skill → spawn agent runtime → collect result → score. Test end-to-end with mock provider.
6. **Output Formatting**: Add human-readable terminal output, JSON/JUnit for `--ci`. Test output parsing and exit codes.
7. **Rails Extensions**: Add Rails-specific skill templates, ActiveSupport integrations. Test Rails mode.
8. **Migration**: Migrate existing providers from code-level config to new YAML/Ruby system. Test backward compatibility.
9. **Documentation**: Write 5-minute first-eval guide. Test guide steps.

## 6. Next Steps
- Review this plan for accuracy and completeness
- Approve plan structure
- Exit plan mode to write plan to `plans/agent-eval-architecture.md`
- Begin implementation with step 1 (Core Models)
