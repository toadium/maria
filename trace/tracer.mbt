///|
pub(open) trait Tracer {
  fn start_span(
    self : Self,
    name~ : String,
    kind~ : SpanKind,
    parent~ : SpanContext?,
  ) -> Span
  fn end_span(self : Self, span : Span, status~ : SpanStatus) -> Unit
  fn export_spans(self : Self, spans : Array[Span]) -> Json
}
