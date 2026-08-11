# tools/wait_job

Wait job tool — waits for a background job to complete and returns its result.

## API

```mbt nocheck
pub fn new(@job.Manager) -> @tool.Tool
```

Creates a `wait_job` tool that blocks until the specified job ID completes, returning the job output or error.