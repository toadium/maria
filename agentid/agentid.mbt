// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
pub struct AgentId(@uuid.Uuid) derive(Eq, Hash, Debug)

///|
pub impl ToJson for AgentId with fn to_json(self : AgentId) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for AgentId with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> AgentId raise {
  let uuid : @uuid.Uuid = @json.FromJson::from_json(json, json_path)
  AgentId(uuid)
}

///|
pub impl Show for AgentId with fn output(self : AgentId, logger : &Logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
pub fn[Source : @uuid.Source] AgentId::new(source : Source) -> AgentId {
  AgentId(@uuid.generator(source).v4())
}

///|
pub fn AgentId::to_uuid(self : AgentId) -> @uuid.Uuid {
  self.0
}

///|
pub fn AgentId::from_uuid(uuid : @uuid.Uuid) -> AgentId {
  AgentId(uuid)
}

///|
pub fn AgentId::to_string(self : AgentId) -> String {
  self.0.to_string()
}

///|
pub fn AgentId::is_nil(self : AgentId) -> Bool {
  self.0 == @uuid.nil
}

///|
pub let nil : AgentId = AgentId(@uuid.nil)
