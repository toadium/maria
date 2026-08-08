///|
pub struct TraceId(String) derive(Eq, Hash, Debug)

///|
pub impl ToJson for TraceId with fn to_json(self : TraceId) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for TraceId with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> TraceId raise @json.JsonDecodeError {
  let str : String = @json.FromJson::from_json(json, json_path)
  guard str.length() == 32 else {
    raise @json.JsonDecodeError(
      (
        json_path,
        "TraceId::from_json: expected 32-char hex string, got \{str.length()} chars",
      ),
    )
  }
  TraceId(str)
}

///|
pub impl Show for TraceId with fn output(self : TraceId, logger : &Logger) -> Unit {
  logger.write_string(self.0)
}

///|
pub fn[Source : @uuid.Source] TraceId::new(source : Source) -> TraceId {
  let hex = @uuid.generator(source)
    .v4()
    .to_string()
    .replace_all(old="-", new="")
  TraceId(hex)
}

///|
pub fn TraceId::to_string(self : TraceId) -> String {
  self.0
}

///|
pub fn TraceId::is_nil(self : TraceId) -> Bool {
  self == TraceId::nil()
}

///|
pub fn TraceId::nil() -> TraceId {
  TraceId(@uuid.nil.to_string().replace_all(old="-", new=""))
}

///|
pub struct SpanId(String) derive(Eq, Hash, Debug)

///|
pub impl ToJson for SpanId with fn to_json(self : SpanId) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for SpanId with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> SpanId raise @json.JsonDecodeError {
  let str : String = @json.FromJson::from_json(json, json_path)
  guard str.length() == 16 else {
    raise @json.JsonDecodeError(
      (
        json_path,
        "SpanId::from_json: expected 16-char hex string, got \{str.length()} chars",
      ),
    )
  }
  SpanId(str)
}

///|
pub impl Show for SpanId with fn output(self : SpanId, logger : &Logger) -> Unit {
  logger.write_string(self.0)
}

///|
pub fn[Source : @uuid.Source] SpanId::new(source : Source) -> SpanId {
  let hex = @uuid.generator(source)
    .v4()
    .to_string()
    .replace_all(old="-", new="")
  SpanId(hex[:16].to_owned())
}

///|
pub fn SpanId::to_string(self : SpanId) -> String {
  self.0
}

///|
pub fn SpanId::is_nil(self : SpanId) -> Bool {
  self == SpanId::nil()
}

///|
pub fn SpanId::nil() -> SpanId {
  SpanId(@uuid.nil.to_string().replace_all(old="-", new="")[:16].to_owned())
}

///|
pub(all) struct SpanContext {
  trace_id : TraceId
  span_id : SpanId
  parent_span_id : SpanId?
} derive(Eq, Debug)

///|
pub impl ToJson for SpanContext with fn to_json(self : SpanContext) -> Json {
  match self.parent_span_id {
    Some(parent) =>
      {
        "trace_id": self.trace_id.to_json(),
        "span_id": self.span_id.to_json(),
        "parent_span_id": parent.to_json(),
      }
    None =>
      {
        "trace_id": self.trace_id.to_json(),
        "span_id": self.span_id.to_json(),
        "parent_span_id": Json::null(),
      }
  }
}

///|
pub impl @json.FromJson for SpanContext with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> SpanContext raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path=json_path)
  let trace_id : TraceId = object.required("trace_id", path=json_path)
  let span_id : SpanId = object.required("span_id", path=json_path)
  let parent_span_id : SpanId? = object.optional(
    "parent_span_id",
    path=json_path,
  )
  { trace_id, span_id, parent_span_id }
}

///|
pub(all) enum SpanKind {
  Session
  Model
  Tool
} derive(Eq, ToJson, FromJson, Debug)

///|
pub(all) enum SpanStatus {
  Unset
  Ok
  Error(String?)
} derive(Eq, Debug)

///|
pub impl ToJson for SpanStatus with fn to_json(self : SpanStatus) -> Json {
  match self {
    Unset => "Unset".to_json()
    Ok => "Ok".to_json()
    Error(Some(msg)) => { "type": "Error", "message": msg.to_json() }
    Error(None) => { "type": "Error", "message": Json::null() }
  }
}

///|
pub impl @json.FromJson for SpanStatus with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> SpanStatus raise @json.JsonDecodeError {
  match json {
    String(str) =>
      match str {
        "Unset" => Unset
        "Ok" => Ok
        _ =>
          raise @json.JsonDecodeError(
            (json_path, "SpanStatus::from_json: unknown status string: \{str}"),
          )
      }
    _ => {
      let object = @jsonx.as_object(json, path=json_path)
      let type_str : String = object.required("type", path=json_path)
      match type_str {
        "Error" => {
          let message : String? = object.optional("message", path=json_path)
          Error(message)
        }
        _ =>
          raise @json.JsonDecodeError(
            (
              json_path,
              "SpanStatus::from_json: unknown status type: \{type_str}",
            ),
          )
      }
    }
  }
}

///|
pub(all) struct Span {
  context : SpanContext
  kind : SpanKind
  name : String
  status : SpanStatus
  start_time : @clock.Timestamp
  end_time : @clock.Timestamp?
  attributes : Map[String, Json]
}

///|
pub impl ToJson for Span with fn to_json(self : Span) -> Json {
  let end_time_json : Json = match self.end_time {
    Some(t) => t.to_json()
    None => Json::null()
  }
  {
    "context": self.context.to_json(),
    "kind": self.kind.to_json(),
    "name": self.name.to_json(),
    "status": self.status.to_json(),
    "start_time": self.start_time.to_json(),
    "end_time": end_time_json,
    "attributes": Json::object(self.attributes),
  }
}

///|
pub impl @json.FromJson for Span with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Span raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path=json_path)
  let context : SpanContext = object.required("context", path=json_path)
  let kind : SpanKind = object.required("kind", path=json_path)
  let name : String = object.required("name", path=json_path)
  let status : SpanStatus = object.required("status", path=json_path)
  let start_time : @clock.Timestamp = object.required(
    "start_time",
    path=json_path,
  )
  let end_time : @clock.Timestamp? = object.optional("end_time", path=json_path)
  let attributes : Map[String, Json] = match object.get("attributes") {
    Some(Json::Object(map)) => map
    Some(Null) | None => Map([])
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Span::from_json: attributes must be a JSON object"),
      )
  }
  { context, kind, name, status, start_time, end_time, attributes }
}

///|
pub impl Eq for Span with fn equal(self : Span, other : Span) -> Bool {
  self.context == other.context &&
  self.kind == other.kind &&
  self.name == other.name &&
  self.status == other.status &&
  self.start_time == other.start_time &&
  self.end_time == other.end_time &&
  self.attributes == other.attributes
}

///|
pub impl @debug.Debug for Span with fn to_repr(self : Span) -> @debug.Repr {
  @debug.Repr::string(self.to_json().stringify())
}
