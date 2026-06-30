# 🧠 LLM Clients Layer

The `lib/skill_bench/clients` directory is the **Intelligence Bridge** of the SkillBench system. It provides a standardized, unified interface to interact with diverse Large Language Model (LLM) providers, from global leaders like OpenAI and Anthropic to local powerhouses via Ollama.

---

## 🏛️ Architecture & Patterns

The client layer is built on the **Template Method pattern** and a **Decoupled Provider Registry**, ensuring that adding a new AI backend requires zero changes to the core evaluation engine.

### System Flow

```mermaid
graph TD
    %% Nodes
    Dispatcher[SkillBench::Client]
    Registry[Provider Registry]
    Base[BaseClient]
    
    %% Providers
    OpenAI[OpenAI]
    Anthropic[Anthropic]
    Gemini[Gemini]
    Azure[AzureOpenAI]
    Ollama[Ollama]

    %% Connections
    Dispatcher -->|1. resolve| Registry
    Registry -->|2. instantiate| Base
    
    subgraph "Inheritance Chain"
        Base -.-> OpenAI
        Base -.-> Anthropic
        Base -.-> Gemini
        Base -.-> Azure
        Base -.-> Ollama
    end

    %% Styling
    style Dispatcher fill:#2563eb,color:#fff,stroke-width:2px
    style Registry fill:#7c3aed,color:#fff
    style Base fill:#475569,color:#fff
```

### Core Components

- **`BaseClient`**: The abstract backbone. It handles connection management (Faraday), JSON orchestration, standardized error recovery, and performance logging.
- **`ProviderRegistry`**: The discovery mechanism. It allows providers to self-register using unique symbols, enabling dynamic selection at runtime.
- **`RequestBuilder`**: Handles Faraday connection setup with configurable timeouts (default: 120s for LLM calls).
- **`ResponseParser`**: Robust JSON parsing with nil-safety for diverse provider response formats.
- **`ResponseErrorHandler`**: Standardized error handling with Rails logger integration.
- **`ToolSet` Integration**: Clients are natively aware of tool definitions, translating them into the specific JSON schema required by each provider.

---

## 🛠️ Supported Providers

| Provider | Registry Key | Config Identity | Deployment Strategy |
| :--- | :--- | :--- | :--- |
| **OpenAI** | `:openai` | `OPENAI_*` | Global Cloud (GPT-4o, GPT-4 Turbo) |
| **Anthropic** | `:anthropic` | `ANTHROPIC_*` | Global Cloud (Claude 3.5 Sonnet, Opus) |
| **Google Gemini** | `:gemini` | `GEMINI_*` | Vertex AI / Google Cloud Platform |
| **Azure OpenAI** | `:azure` | `AZURE_OPENAI_*` | Enterprise Private Cloud (Azure) |
| **Ollama** | `:ollama` | `OLLAMA_*` | Local-First (Llama 3, Qwen, Mistral) |
| **Groq** | `:groq` | `GROQ_*` | High-speed inference |
| **DeepSeek** | `:deepseek` | `DEEPSEEK_*` | Cost-effective alternative |
| **OpenCode** | `:opencode` | `OPENCODE_*` | **Custom endpoint required** (self-hosted proxy / LiteLLM / vLLM) |
| **Null Client** | `:null` | N/A | Mock / Fallback testing |

---

## 🔌 Configuration & Setup

### Environment Variable Mapping

The system supports direct injection via environment variables for rapid prototyping:

- **Azure OpenAI**: `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_API_VERSION`
- **Gemini**: `GEMINI_API_KEY`, `GEMINI_PROJECT_ID`, `GEMINI_LOCATION`
- **Anthropic**: `ANTHROPIC_API_KEY`

### Registry Key Alignment

> [!IMPORTANT]
> When using the `SkillBench::Config.set_provider(:key)` method, ensure the key matches the registry. Note that for Azure, the key is simply `:azure`.

---

## 🚀 Standardized Contract

Every client, regardless of its internal complexity, guarantees a standard response format. This allows SkillBench to process results without caring about the source.

```ruby
# The "Golden" Response Format
{
  success: true,
  response: { 
    message: { 
      'content' => '...',      # String content
      'tool_calls' => [...]    # Optional tool interactions
    } 
  }
}
```

---

## 🧪 Adding Your Own Provider

1. **Subclass `BaseClient`**: Create `lib/skill_bench/clients/providers/my_ai.rb`.
2. **Implement Methods**: Define `base_url`, `request_path`, `extract_message`, `valid_config?`, and `request_headers` (override to inject auth headers).
3. **Register It**:

   ```ruby
   SkillBench::Clients::ProviderRegistry.register(:my_ai, self)
   ```

4. **Load It**: Ensure it is required in the main `lib/skill_bench/client.rb` or your entry point.

---

## 🛡️ Resilience & Observability

- **Timeouts**: Every request is guarded by a 120s timeout (configurable via `RequestBuilder`).
- **Silent Errors**: We prioritize "Fail Fast, Fail Clean". Errors are caught, logged with 5-line backtraces, and returned as `{ success: false }`.
- **JSON Safety**: Robust parsing prevents malformed LLM responses from crashing the system.
- **URL Sanitization**: All provider URL parameters are CGI-escaped to prevent injection attacks.
- **Base URL Validation**: `ProviderConfig` runs every provider's transport URL (`base_url`, and Azure's `endpoint`) through `BaseUrlValidator` at config-load time. A URL must be an absolute `http(s)` URL with a host; blank/relative/garbage values are rejected. When a credential (API key / bearer token) is attached, **non-loopback hosts must use `https`** so the token is never sent in cleartext (mitigating SSRF + token exfiltration). Loopback hosts (`localhost`, `127.0.0.1`, `::1`) may use `http` — the legitimate self-hosted/Ollama case — and `allow_insecure_base_url: true` is an explicit opt-in for cleartext to a non-loopback host. Error messages describe only the transport and never include the credential.

