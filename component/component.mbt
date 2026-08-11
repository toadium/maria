///|
/// 组件分类（Tool/Skill/Prompt），用于 Registry 按类型查询。
pub(all) enum ComponentType {
  Tool
  Skill
  Prompt
} derive(Eq, ToJson, FromJson, Debug)

///|
/// 所有可复用单元（tool/skill/prompt）的统一公共元信息契约。
pub(open) trait Component {
  fn component_type(Self) -> ComponentType
  fn name(Self) -> String
  fn version(Self) -> String
  fn input_schema(Self) -> @tool.JsonSchema
  fn output_schema(Self) -> @tool.JsonSchema
  fn enabled(Self) -> Bool
}

///|
/// 工具组件执行契约，对应 tool 组件（Json → ToolResult）。
pub(open) trait ToolComponent: Component {
  fn execute(Self) -> async (Json) -> @tool.ToolResult noraise
}

///|
/// Skill 组件契约，对应 skill 组件（变换 messages）。
pub(open) trait SkillComponent: Component {
  fn apply(Self) -> async (Array[@ai.Message]) -> Unit
}

///|
/// Prompt 组件契约，对应 prompt 组件（context → 渲染字符串）。
pub(open) trait PromptComponent: Component {
  fn render(Self) -> (Map[String, Json]) -> String
}

///|
/// `@tool.Tool` 实现 `Component` trait，暴露工具的元信息。
/// version 硬编码 "0.2.0"（当前模块版本，moon.mod 中 version = "0.2.0"）。
pub impl Component for @tool.Tool with fn component_type(self) {
  ignore(self)
  ComponentType::Tool
}

///|
pub impl Component for @tool.Tool with fn name(self) {
  self.desc.name
}

///|
pub impl Component for @tool.Tool with fn version(self) {
  ignore(self)
  "0.2.0"
}

///|
pub impl Component for @tool.Tool with fn input_schema(self) {
  self.desc.schema
}

///|
pub impl Component for @tool.Tool with fn output_schema(self) {
  ignore(self)
  @tool.JsonSchema(Json::empty_object())
}

///|
pub impl Component for @tool.Tool with fn enabled(self) {
  ignore(self)
  true
}

///|
/// `@tool.Tool` 实现 `ToolComponent` trait，execute 委托 `Tool::call`。
pub impl ToolComponent for @tool.Tool with fn execute(self : @tool.Tool) -> async (
  Json,
) -> @tool.ToolResult noraise {
  args => self.call(args)
}

///|
/// 标识方法：将 Tool 视为组件。Tool 已实现 ToolComponent，as_component 返回 self。
/// 供 ComponentRegistry 注册时类型转换使用。
/// 命名 as_component 表"视为组件"语义，比 to_component 更准确表达标识方法意图。
/// 注：MoonBit 不允许为外部类型定义方法（E4059），故用全局函数而非 @tool.Tool::as_component。
pub fn as_component(tool : @tool.Tool) -> @tool.Tool {
  tool
}
