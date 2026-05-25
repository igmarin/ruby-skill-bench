# SkillBench Services

This module contains service objects that implement the Single Responsibility Principle for the `EvaluateCommand` class. Each service handles a specific aspect of the evaluation workflow with proper error handling and standardized response formats.

## Services Overview

### RunnerService

Orchestrates the execution of an eval with baseline and context runs. Coordinates multiple services to resolve entities, spawn agents, and evaluate results.

**Responsibilities:**

- Coordinate the evaluation workflow
- Resolve eval, skills, and provider
- Spawn baseline and context agents
- Evaluate results and record trends

**Usage:**

```ruby
result = RunnerService.call(
  eval_name: 'test-eval',
  skill_names: ['test-skill'],
  pack: nil,
  registry_manifest: nil
)
# => { success: true, eval_name: 'test-eval', skill_name: 'test-skill', provider_name: 'mock', response: {...} }
```

### EvalResolver

Resolves an eval from a name or path.

**Responsibilities:**

- Resolve eval by name or full path
- Load eval configuration from disk

**Usage:**

```ruby
evaluation = EvalResolver.call('test-eval')
# => #<SkillBench::Models::Eval>
```

### SkillResolverService

Resolves skills from names, supporting both direct resolution and pack-based resolution.

**Responsibilities:**

- Resolve skills by name using SkillResolver
- Resolve skills from registry packs using PackResolver
- Handle registry manifest resolution

**Usage:**

```ruby
skills = SkillResolverService.call(['test-skill'], pack: nil, registry_manifest: nil)
# => [#<SkillBench::Models::Skill>]
```

### ProviderResolver

Resolves the provider and its configuration.

**Responsibilities:**

- Load provider from configuration
- Resolve provider config with error handling
- Return mock provider when config fails

**Usage:**

```ruby
result = ProviderResolver.call
# => { success: true, provider: <provider>, config: {...} }
```

### PromptBuilderService

Builds system prompts for baseline and context agent runs.

**Responsibilities:**

- Build baseline system prompt without skill context
- Build context-aware system prompt with skill context
- Handle skill_bundle_xml mode with source code hydration

**Usage:**

```ruby
baseline_prompt = PromptBuilderService.build_baseline
context_prompt = PromptBuilderService.build_context(evaluation, skills, skill_context)
```

### AgentSpawnerService

Spawns and executes LLM agents for evaluation.

**Responsibilities:**

- Spawn agents with system prompts
- Handle mock provider for testing
- Capture agent output and iterations
- Include diff in output

**Usage:**

```ruby
result = AgentSpawnerService.call(evaluation, system_prompt, provider, config)
# => { result: '...', status: :success, iterations: [...] }
```

### ContextLoaderService

Loads and combines skill context from SKILL.md files.

**Responsibilities:**

- Load SKILL.md content from skill directories
- Combine multiple skill contexts with separators
- Handle missing SKILL.md files gracefully

**Usage:**

```ruby
context = ContextLoaderService.call(skills)
# => "Skill 1 content\n\n========================================\n\nSkill 2 content"
```

### SourcePathResolverService

Resolves the source path for context hydration.

**Responsibilities:**

- Check eval's source/ subdirectory first
- Fall back to SourcePathResolver inference
- Return nil if no source path found

**Usage:**

```ruby
source_path = SourcePathResolverService.call(evaluation)
# => '/path/to/source' or nil
```

### JudgeParamsBuilder

Builds judge parameters from provider configuration.

**Responsibilities:**

- Extract api_key, model, and provider from config
- Handle mock provider case
- Use provider llm when config model missing

**Usage:**

```ruby
params = JudgeParamsBuilder.call(provider, config)
# => { api_key: '...', model: 'gpt-4', provider: :openai }
```

### ErrorResponseBuilder

Builds standardized error responses with metadata.

**Responsibilities:**

- Build config error responses
- Build agent error responses
- Build empty context error responses
- Enrich existing errors with metadata

**Usage:**

```ruby
error = ErrorResponseBuilder.config_error(exception, evaluation, provider, skill_names)
# => { success: false, response: { error: { message: '...' } }, eval_name: '...', ... }
```

### TrendRecorderService

Records evaluation results and computes trends.

**Responsibilities:**

- Record evaluation results to history
- Compute trend deltas against previous runs
- Handle record failures gracefully

**Usage:**

```ruby
result = TrendRecorderService.call(evaluation_result, eval_name, skill_names)
# => { success: true, trend: { delta: 5 } }
```

### OutputFormatter

Formats agent output for evaluation.

**Responsibilities:**

- Convert agent result to string
- Handle nil and non-string inputs

**Usage:**

```ruby
output = OutputFormatter.call(agent_result)
# => "Agent output as string"
```

### OptionParserService

Handles parsing of CLI arguments using Ruby's OptionParser. Provides standardized error handling for invalid flags and missing arguments.

**Responsibilities:**

- Parse command-line options (-e, -s, -o)
- Handle help flag (-h/--help) behavior
- Return standardized success/error responses

**Usage:**

```ruby
result = OptionParserService.call(['-e', 'evals/test', '-o', 'output.json'])
# => { success: true, response: { eval: 'evals/test', output: 'output.json' } }
```

### JudgeScoreParserService

Parses judge score responses from evaluation results. Handles JSON strings with optional markdown code blocks, Hash inputs, and provides error handling for malformed data.

**Responsibilities:**

- Parse JSON strings (with or without markdown code blocks)
- Convert Hash inputs with string/symbol keys
- Handle malformed data gracefully

**Usage:**

```ruby
result = JudgeScoreParserService.call('{"baseline_score": 80, "context_score": 90}')
# => { success: true, response: { "baseline_score" => 80, "context_score" => 90 } }
```

### ResultPrinterService

Formats and prints evaluation results to stdout. Handles both successful evaluations and error cases with proper formatting.

**Responsibilities:**

- Print formatted evaluation results with banners
- Display judge scores and reasoning
- Show baseline and context diffs
- Handle parse errors gracefully

**Usage:**

```ruby
result = ResultPrinterService.call(evaluation_result, stdout: string_io)
# => { success: true, response: {} }
```

### OutputPersistenceService

Persists evaluation results to JSON files with proper formatting and directory creation.

**Responsibilities:**

- Create parent directories if needed
- Write formatted JSON output
- Handle file system errors gracefully

**Usage:**

```ruby
result = OutputPersistenceService.call(evaluation_result, output_path: 'output.json')
# => { success: true, response: { message: 'Report saved to output.json' } }
```

### ScoringService

Computes deterministic composite scores from eval results using weighted components.

**Responsibilities:**

- Calculate test pass rate (50% weight)
- Calculate timing compliance (30% weight)
- Calculate error handling score (20% weight)
- Load thresholds from criteria.json
- Return pass/fail decision with detailed breakdown

**Usage:**

```ruby
result = ScoringService.call(
  eval: eval_instance,
  result: { status: 'success', test_results: [...] },
  skill_name: 'my-skill',
  provider_name: 'openai'
)
# => {
#      pass: true,
#      score: 0.92,
#      eval_name: 'my-eval',
#      skill_name: 'my-skill',
#      provider_name: 'openai',
#      details: {
#        test_pass_rate: 1.0,
#        timing_score: 0.8,
#        error_score: 1.0,
#        pass_threshold: 0.8,
#        fail_threshold: 0.5
#      }
#    }
```

### TemplateRegistry

Resolves and renders evaluation templates by type and category. Provides pre-built templates for generating eval scaffolding (task descriptions, scoring criteria, and skill instructions) across supported Rails pattern categories.

**Responsibilities:**

- Provide template strings for task.md, criteria.json, and skill.md
- Support variable interpolation using `{{variable_name}}` syntax
- Validate template types and categories
- Return rendered template content

**Template Types:**

| Type | Output | Purpose |
|------|--------|---------|
| `task_md` | Markdown | Agent prompt with requirements |
| `criteria_json` | JSON | Scoring rules and dimensions |
| `skill_md` | Markdown | Skill instructions for the agent |

**Supported Categories:**

| Category | Use Case |
|----------|----------|
| `crud` | Service Objects with Create, Read, Update, Delete |
| `api` | API clients with authentication and error handling |
| `background_job` | ActiveJob/Sidekiq workers with retry logic |
| `controller` | RESTful controllers with strong parameters |
| `model` | ActiveRecord models with validations |
| `migration` | Database migrations with indexes |
| `concern` | ActiveSupport::Concern modules |
| `policy` | Authorization policies (Pundit-style) |
| `form_object` | Form objects with validations |
| `view_component` | ViewComponent components with previews |

**Usage:**

```ruby
# Generate a task template for a CRUD service
task_content = TemplateRegistry.call(:task_md, :crud, skill_name: "UserCreator")
# => "# Task: Implement UserCreator (crud)\n\n## Objective\n..."

# Generate criteria JSON for an API client
criteria_content = TemplateRegistry.call(:criteria_json, :api)
# => "{\n  \"category\": \"api\",\n  \"dimensions\": [...]"

# Generate skill instructions for a background job
skill_content = TemplateRegistry.call(:skill_md, :background_job, skill_name: "OrderProcessor")
# => "# Skill: OrderProcessor (background_job)\n\n## Pattern\n..."
```

**Variable Interpolation:**

Templates support `{{variable_name}}` syntax for dynamic content:

```ruby
# Custom variables are interpolated into templates
task = TemplateRegistry.call(
  :task_md, 
  :api, 
  skill_name: "PaymentGateway",
  endpoint: "/api/v1/payments"
)

# Unmatched placeholders are left intact
template = TemplateRegistry.call(:task_md, :crud)
# => Contains "{{skill_name}}" if no variable provided
```

**Error Handling:**

- Raises `ArgumentError` for invalid template types (must be `:task_md`, `:criteria_json`, or `:skill_md`)
- Raises `ArgumentError` for invalid categories (must be one of the 10 supported categories)
- Error messages include the invalid value and list valid options

**Integration Example:**

```ruby
require 'fileutils'
require 'skill_bench'

# Generate eval scaffolding programmatically
skill_name = "OrderService"

task_md = SkillBench::Services::TemplateRegistry.call(:task_md, :crud, skill_name: skill_name)
criteria_json = SkillBench::Services::TemplateRegistry.call(:criteria_json, :crud)
skill_md = SkillBench::Services::TemplateRegistry.call(:skill_md, :crud, skill_name: skill_name)

# Write to disk
FileUtils.mkdir_p("evals/order-service")
File.write("evals/order-service/task.md", task_md)
File.write("evals/order-service/criteria.json", criteria_json)

FileUtils.mkdir_p("skills/order-service")
File.write("skills/order-service/SKILL.md", skill_md)
```

## Response Contract

All services follow the standardized response contract:

```ruby
# Success response
{ success: true, response: { <data> } }

# Error response
{ success: false, response: { error: { message: 'human-readable reason' } } }
```

## Error Handling

Each service implements proper error handling:

- **OptionParserService**: Catches `OptionParser::ParseError` and returns standardized error responses
- **JudgeScoreParserService**: Handles `JSON::ParserError` and nil inputs gracefully
- **ResultPrinterService**: Uses JudgeScoreParserService internally and handles parse errors
- **OutputPersistenceService**: Catches `SystemCallError` for file system operations
- **ScoringService**: Handles missing keys, empty arrays, and division-by-zero edge cases

## Testing

All services have comprehensive test coverage including:

- Success cases with various input formats
- Error cases and edge conditions
- Integration testing with the main EvaluateCommand
- Proper mocking of external dependencies

## Integration

The services are designed to work together within the `EvaluateCommand` class:

```ruby
def call
  # Parse options
  options_result = Services::OptionParserService.call(@argv)
  return 1 unless options_result[:success]
  
  # Run evaluation
  result = SkillBench::Runner.call(...)
  
  # Print results
  Services::ResultPrinterService.call(result, stdout: @stdout)
  
  # Persist output
  Services::OutputPersistenceService.call(result, output_path: options[:output])
  
  # Record history
  SkillBench::HistoryRecorder.record(...)
end
```

## Benefits

This refactoring provides:

1. **Single Responsibility**: Each service has one clear purpose
2. **Testability**: Services can be tested in isolation
3. **Reusability**: Services can be used independently in other contexts
4. **Maintainability**: Changes to specific functionality are isolated
5. **Error Handling**: Consistent error handling across all operations
6. **Documentation**: Comprehensive YARD documentation for all public methods
