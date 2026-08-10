///|
pub struct SessionId(@uuid.Uuid) derive(Eq, Hash, Debug)

///|
pub impl ToJson for SessionId with fn to_json(self : SessionId) -> Json {
  ToJson::to_json(self.0)
}

///|
pub impl @json.FromJson for SessionId with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> SessionId raise {
  let uuid : @uuid.Uuid = @json.FromJson::from_json(json, json_path)
  SessionId(uuid)
}

///|
pub impl Show for SessionId with fn output(self : SessionId, logger : &Logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
pub fn[Source : @uuid.Source] SessionId::new(source : Source) -> SessionId {
  SessionId(@uuid.generator(source).v4())
}

///|
pub fn SessionId::to_uuid(self : SessionId) -> @uuid.Uuid {
  self.0
}

///|
pub fn SessionId::from_uuid(uuid : @uuid.Uuid) -> SessionId {
  SessionId(uuid)
}

///|
pub fn SessionId::to_string(self : SessionId) -> String {
  self.0.to_string()
}

///|
pub fn SessionId::is_nil(self : SessionId) -> Bool {
  self.0 == @uuid.nil
}

///|
pub let nil : SessionId = SessionId(@uuid.nil)
