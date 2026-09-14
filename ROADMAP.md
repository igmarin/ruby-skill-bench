# Roadmap

Current product intent after 1.3.1. Historical design notes live in [`plans/`](plans/README.md) and are not the backlog.

## 1. Eval corpus quality

Bundled evals under `evals/skills/*/basic/` are short task stubs. Example: `evals/skills/create-service-object/basic/task.md` is four bullets and has no fixture tree for the agent to edit. The engine's claim is that skill context beats baseline. These evals cannot measure that.

Do: turn a small set of those evals into fixture-backed tasks with `task.md`, `criteria.json`, and a starting codebase. Do not add providers in the same change.

## 2. xAI / Grok provider

Shipped: `Clients::Providers::Xai`, `skill-bench init --xai`.

## 3. AWS Bedrock provider

Shipped: `Clients::Providers::Bedrock` (Runtime OpenAI-compatible path + Bedrock API key). IAM SigV4 is still deferred.

## 4. Judge reliability

In progress. Golden parser fixture: `test/fixtures/judge_traces/canonical.json`. Sample variance: `Judge::Variance`. Remaining: record inter-run totals from live evals (no verdict-math change).
