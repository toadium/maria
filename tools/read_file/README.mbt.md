# tools/read_file

Read file tool — reads file contents within the agent's working directory.

## API

```mbt nocheck
pub fn new(@file.Manager) -> @tool.Tool
```

Creates a `read_file` tool that reads file9les relative to the working directory, with line number support and size limits.