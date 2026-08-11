# tools/replace_in_file

Replace in file tool — performs targeted string replacements within files.

## API

```mbt nocheck
pub fn new(@file.Manager) -> @tool.Tool
```

Creates a `replace_in_file` tool that replaces specific text segments in a file. Supports multiple replacements in a single call with exact match requirements.