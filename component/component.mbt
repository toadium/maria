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
pub enum ComponentType {
  Tool
  Skill
  Prompt
} derive(Eq, ToJson, FromJson, Debug)

///|
pub(open) trait Component {
  fn component_type(Self) -> ComponentType
  fn name(Self) -> String
  fn version(Self) -> String
  fn input_schema(Self) -> @tool.JsonSchema
  fn output_schema(Self) -> @tool.JsonSchema
  fn enabled(Self) -> Bool
}

///|
pub(open) trait ToolComponent: Component {
  fn execute(Self) -> async (Json) -> @tool.ToolResult noraise
}

///|
pub(open) trait SkillComponent: Component {
  fn apply(Self) -> async (Array[@ai.Message]) -> Unit
}

///|
pub(open) trait PromptComponent: Component {
  fn render(Self) -> (Map[String, Json]) -> String
}
