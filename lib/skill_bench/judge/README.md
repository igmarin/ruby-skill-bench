# Judge Subsystem

Evaluates AI-generated code modifications by calling an LLM judge.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `judge.rb` | `Judge::Judge` | Orchestrates the LLM judge call |
| `prompt.rb` | `Judge::Prompt` | Builds structured prompts from task + criteria |
| `response.rb` | `Judge::Response` | Parses and validates judge JSON responses |
| `variance.rb` | `Judge::Variance` | Sample mean/stddev/spread over repeated totals |
| `test/fixtures/judge_traces/` | — | Golden judge JSON that must keep parsing |

## Usage

```ruby
response = SkillBench::Judge::Judge.new(task:, criteria:, output:).call
```
