///|
/// MCP 远程工具组件，实现 Component/ToolComponent trait，通过回调函数发起远程调用。
pub struct McpTool {
  name : String
  description : String
  input_schema : @tool.JsonSchema
  priv call_fn : async (Json) -> @tool.ToolResult noraise
}

///|
pub fn McpTool::new(
  name~ : String,
  description~ : String,
  input_schema~ : @tool.JsonSchema,
  call_fn~ : async (Json) -> @tool.ToolResult noraise,
) -> McpTool {
  McpTool::{ name, description, input_schema, call_fn }
}

///|
/// version 硬编码 "0.1.0"（当前模块版本，moon.mod 中 version = "0.1.0"）。
/// R24 版本升级时此处须同步更新，避免版本号遗漏。
pub impl @component.Component for McpTool with fn component_type(self) {
  ignore(self)
  @component.ComponentType::Tool
}

///|
pub impl @component.Component for McpTool with fn name(self) {
  self.name
}

///|
pub impl @component.Component for McpTool with fn version(self) {
  ignore(self)
  "0.1.0"
}

///|
pub impl @component.Component for McpTool with fn input_schema(self) {
  self.input_schema
}

///|
pub impl @component.Component for McpTool with fn output_schema(self) {
  ignore(self)
  @tool.JsonSchema(Json::empty_object())
}

///|
pub impl @component.Component for McpTool with fn enabled(self) {
  ignore(self)
  true
}

///|
pub impl @component.ToolComponent for McpTool with fn execute(self : McpTool) -> async (
  Json,
) -> @tool.ToolResult noraise {
  args => (self.call_fn)(args)
}
