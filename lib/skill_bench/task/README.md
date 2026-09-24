# Task Subsystem

Manages individual evaluation tasks.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `directory_finder.rb` | `Task::DirectoryFinder` | Finds the root task or nested task directories in sorted order |
| `evaluator.rb` | `Task::Evaluator` | Orchestrates baseline + context runs + judge scoring |
| `file_reader.rb` | `Task::FileReader` | Safely reads task.md and criteria.json |

## Find eval task directories

```ruby
root = Pathname.new('evals')
task_dirs = SkillBench::Task::DirectoryFinder.call(root)
```

When `evals/task.md` exists, the result contains only `evals`. Otherwise, it contains the nested directories with a `task.md`, sorted by path. `SkillBench::Runner.discover_task_dirs` remains available for older callers.
