///|
/// 提示词模板组件，包装模板字符串适配 PromptComponent trait。
/// 可注册到 ComponentRegistry 统一管理，支持 context → 渲染字符串的 render 契约。
/// 静态模板忽略 context 直接返回 template 内容；变量替换留待 P1/P2 阶段完善。
pub struct PromptTemplate {
  template : String
  name : String
} derive(Debug)

///|
/// 构造 PromptTemplate。
/// - `template`: 模板内容字符串
/// - `name`: 组件名称，默认 "prompt"
pub fn PromptTemplate::new(
  template~ : String,
  name? : String = "prompt",
) -> PromptTemplate {
  PromptTemplate::{ template, name }
}

///|
/// 访问 template 字段。
pub fn PromptTemplate::template(self : PromptTemplate) -> String {
  self.template
}

///|
/// PromptTemplate 实现 Component trait，暴露提示词组件元信息。
/// version 硬编码 "0.2.0"（当前模块版本，moon.mod 中 version = "0.2.0"）。
pub impl @component.Component for PromptTemplate with fn component_type(self) {
  ignore(self)
  @component.ComponentType::Prompt
}

///|
pub impl @component.Component for PromptTemplate with fn name(self) {
  self.name
}

///|
pub impl @component.Component for PromptTemplate with fn version(self) {
  ignore(self)
  "0.2.0"
}

///|
pub impl @component.Component for PromptTemplate with fn input_schema(self) {
  ignore(self)
  @tool.JsonSchema(Json::empty_object())
}

///|
pub impl @component.Component for PromptTemplate with fn output_schema(self) {
  ignore(self)
  @tool.JsonSchema(Json::empty_object())
}

///|
pub impl @component.Component for PromptTemplate with fn enabled(self) {
  ignore(self)
  true
}

///|
/// PromptTemplate 实现 PromptComponent trait，render 忽略 context 返回 template 内容。
pub impl @component.PromptComponent for PromptTemplate with fn render(self) {
  _ => self.template
}

///|
/// 返回 prelude 的 PromptTemplate 实例，组件名称 "prelude"。
pub fn prelude_component() -> PromptTemplate {
  PromptTemplate::new(template=prelude, name="prelude")
}
