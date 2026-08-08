///|
test "trace_id_new_not_nil" {
  let id = @trace.TraceId::new(@rand.chacha8())
  json_inspect(id.is_nil(), content=false)
}

///|
test "trace_id_to_string_length" {
  let id = @trace.TraceId::new(@rand.chacha8())
  json_inspect(id.to_string().length(), content=32)
}

///|
test "trace_id_nil_is_nil" {
  json_inspect(@trace.TraceId::nil().is_nil(), content=true)
}

///|
test "trace_id_eq_hash" {
  let id = @trace.TraceId::new(@rand.chacha8())
  let id2 : @trace.TraceId = @json.from_json(id.to_json())
  json_inspect(id == id2, content=true)
  json_inspect(id.hash() == id2.hash(), content=true)
}

///|
test "trace_id_to_json_from_json" {
  let id = @trace.TraceId::new(@rand.chacha8())
  let roundtripped : @trace.TraceId = @json.from_json(id.to_json())
  json_inspect(roundtripped == id, content=true)
}

///|
test "trace_id_from_json_invalid_length" {
  // 长度不足
  try {
    let _ : @trace.TraceId = @json.from_json("too-short")
    fail("expected from_json to raise on invalid length")
  } catch {
    _ => ()
  }
  // 长度超长（34 字符）
  try {
    let _ : @trace.TraceId = @json.from_json(
      "0000000000000000000000000000000000",
    )
    fail("expected from_json to raise on invalid length")
  } catch {
    _ => ()
  }
}

///|
test "span_id_new_not_nil" {
  let id = @trace.SpanId::new(@rand.chacha8())
  json_inspect(id.is_nil(), content=false)
}

///|
test "span_id_to_string_length" {
  let id = @trace.SpanId::new(@rand.chacha8())
  json_inspect(id.to_string().length(), content=16)
}

///|
test "span_id_nil_is_nil" {
  json_inspect(@trace.SpanId::nil().is_nil(), content=true)
}

///|
test "span_id_to_json_from_json" {
  let id = @trace.SpanId::new(@rand.chacha8())
  let roundtripped : @trace.SpanId = @json.from_json(id.to_json())
  json_inspect(roundtripped == id, content=true)
}

///|
test "span_id_from_json_invalid_length" {
  // 长度不足（10 字符）
  try {
    let _ : @trace.SpanId = @json.from_json("too-short")
    fail("expected from_json to raise on invalid length")
  } catch {
    _ => ()
  }
  // 长度超长（18 字符）
  try {
    let _ : @trace.SpanId = @json.from_json("000000000000000000")
    fail("expected from_json to raise on invalid length")
  } catch {
    _ => ()
  }
}

///|
test "span_context_to_json_with_parent" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: Some(@trace.SpanId::nil()),
  }
  inspect(
    ctx.to_json().stringify(),
    content="{\"trace_id\":\"00000000000000000000000000000000\",\"span_id\":\"0000000000000000\",\"parent_span_id\":\"0000000000000000\"}",
  )
}

///|
test "span_context_to_json_without_parent" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  inspect(
    ctx.to_json().stringify(),
    content="{\"trace_id\":\"00000000000000000000000000000000\",\"span_id\":\"0000000000000000\",\"parent_span_id\":null}",
  )
}

///|
test "span_context_from_json_missing_parent" {
  let json : Json = {
    "trace_id": @trace.TraceId::nil().to_json(),
    "span_id": @trace.SpanId::nil().to_json(),
  }
  let ctx : @trace.SpanContext = @json.from_json(json)
  json_inspect(ctx.parent_span_id == None, content=true)
}

///|
test "span_context_from_json_null_parent" {
  let json : Json = {
    "trace_id": @trace.TraceId::nil().to_json(),
    "span_id": @trace.SpanId::nil().to_json(),
    "parent_span_id": Json::null(),
  }
  let ctx : @trace.SpanContext = @json.from_json(json)
  json_inspect(ctx.parent_span_id == None, content=true)
}

///|
test "span_context_to_json_from_json_roundtrip" {
  // parent_span_id = Some 往返
  let ctx_with_parent = @trace.SpanContext::{
    trace_id: @trace.TraceId::new(@rand.chacha8()),
    span_id: @trace.SpanId::new(@rand.chacha8()),
    parent_span_id: Some(@trace.SpanId::new(@rand.chacha8())),
  }
  let rt1 : @trace.SpanContext = @json.from_json(ctx_with_parent.to_json())
  json_inspect(rt1 == ctx_with_parent, content=true)
  // parent_span_id = None 往返
  let ctx_no_parent = @trace.SpanContext::{
    trace_id: @trace.TraceId::new(@rand.chacha8()),
    span_id: @trace.SpanId::new(@rand.chacha8()),
    parent_span_id: None,
  }
  let rt2 : @trace.SpanContext = @json.from_json(ctx_no_parent.to_json())
  json_inspect(rt2 == ctx_no_parent, content=true)
}

///|
test "span_kind_to_json_from_json" {
  json_inspect(@trace.Session.to_json(), content="Session")
  json_inspect(@trace.Model.to_json(), content="Model")
  json_inspect(@trace.Tool.to_json(), content="Tool")
  let s : @trace.SpanKind = @json.from_json(@trace.Session.to_json())
  json_inspect(s == @trace.Session, content=true)
  let m : @trace.SpanKind = @json.from_json(@trace.Model.to_json())
  json_inspect(m == @trace.Model, content=true)
  let t : @trace.SpanKind = @json.from_json(@trace.Tool.to_json())
  json_inspect(t == @trace.Tool, content=true)
}

///|
test "span_status_to_json_unset_ok" {
  json_inspect(@trace.Unset.to_json(), content="Unset")
  json_inspect(@trace.Ok.to_json(), content="Ok")
}

///|
test "span_status_to_json_error_with_message" {
  inspect(
    @trace.Error(Some("timeout")).to_json().stringify(),
    content="{\"type\":\"Error\",\"message\":\"timeout\"}",
  )
}

///|
test "span_status_to_json_error_without_message" {
  inspect(
    @trace.Error(None).to_json().stringify(),
    content="{\"type\":\"Error\",\"message\":null}",
  )
}

///|
test "span_status_from_json_unset_ok" {
  let u : @trace.SpanStatus = @json.from_json("Unset")
  json_inspect(u == @trace.Unset, content=true)
  let o : @trace.SpanStatus = @json.from_json("Ok")
  json_inspect(o == @trace.Ok, content=true)
}

///|
test "span_status_from_json_error_with_message" {
  let json : Json = { "type": "Error", "message": "timeout" }
  let s : @trace.SpanStatus = @json.from_json(json)
  json_inspect(s == @trace.Error(Some("timeout")), content=true)
}

///|
test "span_status_from_json_error_null_message" {
  let json : Json = { "type": "Error", "message": Json::null() }
  let s : @trace.SpanStatus = @json.from_json(json)
  json_inspect(s == @trace.Error(None), content=true)
}

///|
test "span_status_from_json_error_missing_message" {
  let json : Json = { "type": "Error" }
  let s : @trace.SpanStatus = @json.from_json(json)
  json_inspect(s == @trace.Error(None), content=true)
}

///|
test "span_status_from_json_unknown_type" {
  // 未知 type 字符串应 raise JsonDecodeError
  let json : Json = { "type": "Unknown" }
  try {
    let _ : @trace.SpanStatus = @json.from_json(json)
    fail("expected from_json to raise on unknown status type")
  } catch {
    _ => ()
  }
  // 未知状态字符串应 raise JsonDecodeError
  try {
    let _ : @trace.SpanStatus = @json.from_json("UnknownStatus")
    fail("expected from_json to raise on unknown status string")
  } catch {
    _ => ()
  }
}

///|
test "span_status_to_json_from_json_roundtrip" {
  let statuses = [
    @trace.Unset,
    @trace.Ok,
    @trace.Error(Some("timeout")),
    @trace.Error(None),
  ]
  for s in statuses {
    let roundtripped : @trace.SpanStatus = @json.from_json(s.to_json())
    json_inspect(roundtripped == s, content=true)
  }
}

///|
test "span_to_json_from_json" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::new(@rand.chacha8()),
    span_id: @trace.SpanId::new(@rand.chacha8()),
    parent_span_id: None,
  }
  // 变体 1：end_time=None，单 attribute，kind=Session，status=Unset
  let span1 = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(1000),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  let rt1 : @trace.Span = @json.from_json(span1.to_json())
  json_inspect(rt1 == span1, content=true)
  // 变体 2：end_time=Some，多 attributes 不同类型，kind=Model，status=Error
  let span2 = @trace.Span::{
    context: ctx,
    kind: @trace.Model,
    name: "llm_call",
    status: @trace.Error(Some("timeout")),
    start_time: @clock.Timestamp::from_ms(2000),
    end_time: Some(@clock.Timestamp::from_ms(3000)),
    attributes: Map([
      ("model", "gpt-4".to_json()),
      ("tokens", (100).to_json()),
      ("ok", true.to_json()),
    ]),
  }
  let rt2 : @trace.Span = @json.from_json(span2.to_json())
  json_inspect(rt2 == span2, content=true)
}

///|
test "span_end_time_none_to_json_null" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  let span = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([]),
  }
  inspect(
    span.to_json().stringify(),
    content="{\"context\":{\"trace_id\":\"00000000000000000000000000000000\",\"span_id\":\"0000000000000000\",\"parent_span_id\":null},\"kind\":\"Session\",\"name\":\"test\",\"status\":\"Unset\",\"start_time\":0,\"end_time\":null,\"attributes\":{}}",
  )
}

///|
test "span_attributes_to_json_object" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  let span = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  inspect(
    span.to_json().stringify(),
    content="{\"context\":{\"trace_id\":\"00000000000000000000000000000000\",\"span_id\":\"0000000000000000\",\"parent_span_id\":null},\"kind\":\"Session\",\"name\":\"test\",\"status\":\"Unset\",\"start_time\":0,\"end_time\":null,\"attributes\":{\"key\":\"val\"}}",
  )
}

///|
test "span_eq" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  let base = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  // 全字段相同 → 相等
  let same = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == same, content=true)
  // attributes 不同 → 不等
  let diff_attrs = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "different".to_json())]),
  }
  json_inspect(base == diff_attrs, content=false)
  // kind 不同 → 不等
  let diff_kind = @trace.Span::{
    context: ctx,
    kind: @trace.Model,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == diff_kind, content=false)
  // name 不同 → 不等
  let diff_name = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "other",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == diff_name, content=false)
  // status 不同 → 不等
  let diff_status = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Ok,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == diff_status, content=false)
  // start_time 不同 → 不等
  let diff_start = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(1),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == diff_start, content=false)
  // end_time 不同 → 不等
  let diff_end = @trace.Span::{
    context: ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: Some(@clock.Timestamp::from_ms(0)),
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == diff_end, content=false)
  // context 不同 → 不等
  let diff_ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::new(@rand.chacha8()),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  let diff_context = @trace.Span::{
    context: diff_ctx,
    kind: @trace.Session,
    name: "test",
    status: @trace.Unset,
    start_time: @clock.Timestamp::from_ms(0),
    end_time: None,
    attributes: Map([("key", "val".to_json())]),
  }
  json_inspect(base == diff_context, content=false)
}

///|
test "noop_tracer_start_span" {
  let tracer = @trace.NoopTracer::new()
  let span = tracer.start_span(name="test", kind=@trace.Session, parent=None)
  json_inspect(span.context.trace_id == @trace.TraceId::nil(), content=true)
  json_inspect(span.context.span_id == @trace.SpanId::nil(), content=true)
  json_inspect(span.context.parent_span_id == None, content=true)
  json_inspect(span.status == @trace.Unset, content=true)
  json_inspect(span.start_time == @clock.Timestamp::from_ms(0), content=true)
  json_inspect(span.end_time == None, content=true)
  json_inspect(span.attributes == Map([]), content=true)
  // 验证 kind/name 取入参（设计规格：NoopTracer::start_span "kind/name 取入参"）
  json_inspect(span.kind == @trace.Session, content=true)
  json_inspect(span.name == "test", content=true)
}

///|
test "noop_tracer_end_span_and_export" {
  let tracer = @trace.NoopTracer::new()
  let span = tracer.start_span(name="test", kind=@trace.Session, parent=None)
  tracer.end_span(span, status=@trace.Ok)
  // 空数组输入返回空数组
  json_inspect(tracer.export_spans([]) == Json::array([]), content=true)
  // 非空数组输入也返回空数组（契约 32 对任意 spans 成立）
  json_inspect(tracer.export_spans([span]) == Json::array([]), content=true)
}

///|
test "tracer_trait_dispatch" {
  let tracer = @trace.NoopTracer::new()
  let span = @trace.Tracer::start_span(
    tracer,
    name="test",
    kind=@trace.Session,
    parent=None,
  )
  json_inspect(span.context.trace_id == @trace.TraceId::nil(), content=true)
}

///|
test "span_from_json_invalid_attributes" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  // attributes 为数组 → raise
  let json_arr : Json = {
    "context": ctx.to_json(),
    "kind": @trace.Session.to_json(),
    "name": "test",
    "status": @trace.Unset.to_json(),
    "start_time": @clock.Timestamp::from_ms(0).to_json(),
    "end_time": Json::null(),
    "attributes": Json::array([]),
  }
  try {
    let _ : @trace.Span = @json.from_json(json_arr)
    fail("expected from_json to raise on array attributes")
  } catch {
    _ => ()
  }
  // attributes 为字符串 → raise
  let json_str : Json = {
    "context": ctx.to_json(),
    "kind": @trace.Session.to_json(),
    "name": "test",
    "status": @trace.Unset.to_json(),
    "start_time": @clock.Timestamp::from_ms(0).to_json(),
    "end_time": Json::null(),
    "attributes": "not-an-object",
  }
  try {
    let _ : @trace.Span = @json.from_json(json_str)
    fail("expected from_json to raise on string attributes")
  } catch {
    _ => ()
  }
}

///|
test "span_from_json_attributes_missing_or_null" {
  let ctx = @trace.SpanContext::{
    trace_id: @trace.TraceId::nil(),
    span_id: @trace.SpanId::nil(),
    parent_span_id: None,
  }
  // 变体 1：attributes 字段缺失 → 解析为空 Map
  let json_missing : Json = {
    "context": ctx.to_json(),
    "kind": @trace.Session.to_json(),
    "name": "test",
    "status": @trace.Unset.to_json(),
    "start_time": @clock.Timestamp::from_ms(0).to_json(),
    "end_time": Json::null(),
  }
  let span_missing : @trace.Span = @json.from_json(json_missing)
  json_inspect(span_missing.attributes == Map([]), content=true)
  // 变体 2：attributes 为 null → 解析为空 Map
  let json_null : Json = {
    "context": ctx.to_json(),
    "kind": @trace.Session.to_json(),
    "name": "test",
    "status": @trace.Unset.to_json(),
    "start_time": @clock.Timestamp::from_ms(0).to_json(),
    "end_time": Json::null(),
    "attributes": Json::null(),
  }
  let span_null : @trace.Span = @json.from_json(json_null)
  json_inspect(span_null.attributes == Map([]), content=true)
}
