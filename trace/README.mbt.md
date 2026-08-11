# trace

Full-stack observability — distributed tracing with `Tracer`, `Span`, `TraceId`, and `SpanId`.

## Overview

- `Tracer` trait: `start_span(name) -> Span` + `end_span(span)`
- `NoopTracer`: zero-overhead tracer for production when tracing is disabled
- `Span`: holds `span_id` / `parent_id` / `trace_id` / `name` / `start_time` / attributes
- `TraceId` / `SpanId`: newtype wrappers over `@uuid.Uuid`

## Usage

```mbt nocheck
///|
let tracer = @trace.NoopTracer::new()
let span = tracer->@trace.Tracer::start_span("tool_execution")
span.set_attribute("tool.name", "read_file")
span.set_attribute("tool.args", "{\"path\": \"README.md\"}")
tracer->@trace.Tracer::end_span(span)
```

## Tracer Trait

```mbt nocheck
///|
pub(open) trait Tracer {
  fn start_span(self : Self, name~ : String) -> Span
  fn end_span(self : Self, span : Span) -> Unit
}
```

## Span

```mbt nocheck
///|
pub(all) struct Span {
  span_id : SpanId
  parent_id : SpanId?
  trace_id : TraceId
  name : String
  start_time : @clock.Timestamp
  mut attributes : Map[String, String]
}
```

## Integration

The `Agent` struct holds a `&Tracer` reference. When trace is enabled, the agent emits spans for:
- Conversation requests
- Tool executions
- Context pruning
- Event processing