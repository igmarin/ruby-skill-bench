# ReactAgent (`lib/react_agent`)

The `ReactAgent` namespace implements the Reasoning and Acting (ReAct) paradigm. It handles the continuous loop of prompting the LLM, parsing its intent, executing tools, and returning observations.

## Components

### `ReactAgent` ([react_agent.rb](react_agent.rb))
- **Purpose**: The main entry point. Sets up configuration and kicks off the loop.
- **Returns**: `{ success: bool, response: { content: '...' } }`

### `LoopRunner` ([loop_runner.rb](loop_runner.rb))
- **Purpose**: Executes the ReAct loop iterations until completion or max iterations.
- **Note**: Console output removed - uses return values only.

### `Step` ([step.rb](step.rb))
- **Purpose**: Represents a single interaction turn with the LLM. It sends the current messages and extracts either a final text response or a tool call request.

### `ToolExecutor` ([tool_executor.rb](tool_executor.rb))
- **Purpose**: Bridges the LLM's requests with actual Ruby code. It takes a tool call definition, finds the corresponding class in `Evaluator::Tools`, executes it securely, and formats the output (or error) back into a message the LLM can understand.
