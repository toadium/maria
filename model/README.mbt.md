# model

LLM model configuration — API key, base URL, model name, and token limits.

## API

```mbt nocheck
///|
pub struct Model {
  api_key : String
  base_url : String
  name : String
  safe_zone_tokens : Int
}

///|
pub fn new(
  api_key~ : String,
  base_url~ : String,
  name~ : String,
  safe_zone_tokens~ : Int,
) -> Model
```

## Usage

```mbt nocheck
///|
let model = @model.new(
  api_key="sk-...",
  base_url="https://openrouter.ai/api/v1",
  name="anthropic/claude-haiku-4.5",
  safe_zone_tokens=200000,
)
```

The `safe_zone_tokens` field defines the context window budget. The agent uses this to determine when context pruning is needed.