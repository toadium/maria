# tools/list_jobs

List jobs tool — lists active and completed background jobs managed by `@job.Manager`.

## API

```mbt nocheck
pub fn new(@job.Manager) -> @tool.Tool
```

Creates a `list_jobs` tool that returns all job statuses (running/completed/failed) with metadata.