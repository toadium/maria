# tools/execute_command

Execute command tool — runs shell commands within(working directory, managed by `@job.Manager`.

## API

```mbt nocheck
pub fn new(@job.Manager) -> @tool.Tool
```

Creates an `execute_command` tool that spawns subprocess commands with timeout and output capture. Results include stdout/stderr/exit_code.