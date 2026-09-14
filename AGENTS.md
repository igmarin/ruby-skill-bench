# Agent instructions

## Docs to trust

- Runtime shape and fail-closed host execution: `docs/architecture.md`
- User CLI and providers: `README.md`
- Docker image contract: `docs/docker.md`
- How to run evals: `docs/testing-guide.md`
- Contributor setup: `CONTRIBUTING.md`
- Next product work: `ROADMAP.md`
- `plans/` is historical. Do not treat those files as open work.

## How to change this repo

1. New behavior: write a failing Minitest under `test/`, run that file, then write the minimum code to pass.
2. File test: `bundle exec ruby -Itest test/<path>_test.rb`
3. Full suite: `bundle exec rake test`
4. Every `.rb` file starts with `# frozen_string_literal: true`.
5. Service objects expose `.call` and return `{ success:, response: }`.
6. Leave `repomix-output.*` and `coverage/` uncommitted.

## Code intelligence

Use these tools before dumping whole files or grepping the tree.

1. If `.codegraph/` exists, run `codegraph explore "<symbol or question>"` (or the CodeGraph MCP tools).
2. If `graphify-out/graph.json` exists, use Graphify (`graphify explain`, `graphify path`, or the Graphify MCP).
3. For a whole-repo pack, run `repomix` using `repomix.config.json`. Do not commit `repomix-output.*`.
4. Regenerate Graphify with `graphify extract . --backend deepseek --no-cluster` (DeepSeek is the global LLM). Rust workspaces also pass `--cargo`.
