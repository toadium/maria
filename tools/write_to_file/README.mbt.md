# tools/write_to_file

Write file tool — creates or overwrites files within the agent's working directory.

## API

```mbt nocheck
pub fn new(String) -> @tool.Tool
pub fn json_input(content~ : String, path~ : String, separator? : String) -> Json
```

Creates a `write_to_file` tool that writes content to the specified path. The `json_input` helper constructs the tool call arguments JSON.