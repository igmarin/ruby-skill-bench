# SkillBench Core (`lib/skill_bench/`)

This directory contains the core logic for the Ruby Skill Bench evaluation system.

## Architecture Overview

The system is built around several decoupled domains to ensure maintainability and separation of concerns:

- **`clients/`**: LLM provider integrations via Faraday.
  - **`base_client.rb`**: Abstract base implementing Template Method pattern for all providers.
  - **`provider_registry.rb`**: Extensible registry for provider lookup (replaces case statements).
  - **`request_builder.rb`**: Faraday connection setup with configurable timeouts.
  - **`response_parser.rb`**: Robust JSON parsing with nil-safety.
  - **`response_error_handler.rb`**: Standardized error handling.
  - **`providers/`**: Provider implementations (OpenAI, Anthropic, Gemini, Azure, Ollama, Groq, DeepSeek, OpenCode).
- **`config/`**: Hierarchical configuration loading (Defaults → Home JSON → Local JSON → ENV).
- **`SourcePathResolver`**: Infers the source skill or workflow directory from an eval target, while still allowing explicit overrides.
- **`ContextHydrator`**: Injects necessary context into the prompt, mapping source markdown files to XML blocks.
- **`ReactAgent`** (in `react_agent/`): Implements the ReAct (Reasoning and Acting) loop. See [react_agent/README.md](react_agent/README.md).
- **`Tools`** (in `tools/`): Actionable capabilities the agent can use to interact with its environment.
- **`Runner`**: The central orchestrator that glues these components together to execute a skill evaluation.
  - Uses `TaskEvaluator` for individual task evaluation.
  - Uses `TaskFileReader` for safe file I/O with error handling.
- **`services/`**: Service objects for CLI parsing, scoring, output formatting, and persistence. See [services/README.md](services/README.md).

## Design Philosophy

- **Service Objects (POODR / Sandi Metz):** The code aims for the Single Responsibility Principle. Complex loops (like ReAct) are broken down into discrete objects like `Step` and `ToolExecutor`.
- **Statelessness:** State is mostly kept in the message history passed back and forth, allowing components to remain pure and stateless where possible.
- **Security First:** Actions interacting with the OS (like `tools`) validate boundaries before execution. Dangerous commands are always blocked. URL parameters are CGI-escaped.
- **Registry Pattern:** Providers are registered dynamically via `ProviderRegistry` for extensibility.
