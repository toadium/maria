# tools/search_files

Search files tool — searches file contents using regex patterns within the agent's working directory.

## API

```mbt nocheck
pub fn new(String) -> @tool.Tool
```

Creates a `search_files` tool that performs ripgrep-style content search with regex pattern matching, file type filters, and result limiting.