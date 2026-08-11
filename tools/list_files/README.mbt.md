# tools/list_files

List files tool — enumerates files and directories within the agent's working directory.

## API

```mbt nocheck
pub fn new(@file.Manager) -> @tool.Tool
```

Creates a `list_files` tool that lists directory contents with optional recursive traversal and ignore patterns.