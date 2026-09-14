# Comparing skill revisions

Use the same task, fixture commit, acceptance tests, criteria file, model, host configuration, and repetition count for no skills, current skills, and revised skills. Keep a held-out task set. Run the current and revised conditions against the same no-skills baseline protocol; archive the actual outputs and provenance alongside each report.

`Evaluation::Runner` gives both independent judges the same task and criteria. Skill instructions are supplied only to the executing agent. Its `skill_context` argument remains accepted for compatibility but is deliberately omitted from judging. The active evaluator scores one output per independent request, so there is no paired presentation order. A future paired judge must shuffle anonymous outputs and map scores back outside its prompt.

Write criteria as observable task requirements before generating outputs. The legacy `skill_adherence` dimension name remains supported; its description must state an independently assessable requirement rather than ask the judge to infer whether a skill was used. Keep treatment names and instructions out of criteria and agent summaries sent to the judge.

Executable acceptance tests take precedence over prose scores. Preserve test failures and unavailable checks as evidence; a prose score cannot turn either into a passing execution result. Report repetitions, fixture and skill commits, host/model versions, actual usage, and incomplete runs. A small or inconclusive sample establishes no statistical improvement. Paid comparisons require a manual invocation and an explicit usage cap; the unit suite makes no provider calls.
