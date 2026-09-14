# Roadmap

Current product intent after 1.3.1. Historical design notes live in [`plans/`](plans/README.md) and are not the backlog.

## 1. Eval corpus quality

Bundled evals under `evals/skills/*/basic/` are short task stubs. Example: `evals/skills/create-service-object/basic/task.md` is four bullets and has no fixture tree for the agent to edit. The engine's claim is that skill context beats baseline. These evals cannot measure that.

Do: turn a small set of those evals into fixture-backed tasks with `task.md`, `criteria.json`, and a starting codebase. Do not add providers in the same change.

## 2. xAI / Grok provider

No `Clients::Providers` class exists for xAI. The surrounding skill ecosystem already runs on Grok. Pattern to copy: OpenAI-compatible subclass (see Mistral and OpenRouter).

Do not fold Bedrock into this item.

## 3. AWS Bedrock provider

Closed issue [#47](https://github.com/igmarin/ruby-skill-bench/issues/47) named Bedrock as the larger follow-up to Mistral. This is not a one-file client: auth, regions, and model IDs differ from the OpenAI-compatible adapters.

Do not start this before OpenRouter (already shipped) is documented and xAI is decided.

## 4. Judge reliability

Scores come from an LLM judge (`Evaluation::Runner` → `Judge`) with no golden-trace fixture set and no recorded inter-run variance. Deltas are not product truth until that exists.

Do not change dimension names or verdict math in the same change as adding traces.
