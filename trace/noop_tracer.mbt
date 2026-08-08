///|
pub struct NoopTracer {}

///|
pub fn NoopTracer::new() -> NoopTracer {
  NoopTracer::{  }
}

///|
pub impl Tracer for NoopTracer with fn start_span(
  self : NoopTracer,
  name~ : String,
  kind~ : SpanKind,
  parent~ : SpanContext?,
) -> Span {
  ignore(self)
  ignore(parent)
  Span::{
    context: SpanContext::{
      trace_id: TraceId::nil(),
      span_id: SpanId::nil(),
      parent_span_id: None,
    },
    kind,
    name,
    status: SpanStatus::Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([]),
  }
}

///|
pub impl Tracer for NoopTracer with fn end_span(
  self : NoopTracer,
  span : Span,
  status~ : SpanStatus,
) -> Unit {
  ignore(self)
  ignore(span)
  ignore(status)
}

///|
pub impl Tracer for NoopTracer with fn export_spans(
  self : NoopTracer,
  spans : Array[Span],
) -> Json {
  ignore(self)
  ignore(spans)
  Json::array([])
}
