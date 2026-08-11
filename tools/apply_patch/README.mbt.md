# tools/apply_patch

Apply patch tool — applies structured patches to files (add/update/delete operations).

## API

```mbt nocheck
pub fn new(String) -> @tool.Tool
pub fn parse_patch(String) -> ParsedPatch raise ParseError
```

Creates an `apply_patch` tool that applies multi-file patches in a single operation. The `parse_patch` function parses patch text into a `ParsedPatch` structure for validation before application.