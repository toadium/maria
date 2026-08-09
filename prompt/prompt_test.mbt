///|
/// PromptTemplate 构造：默认 name 为 "prompt"
test "prompt_template_new_default_name" {
  let pt = @prompt.PromptTemplate::new(template="hello world")
  inspect(@component.Component::name(pt), content="prompt")
  inspect(pt.template(), content="hello world")
}

///|
/// PromptTemplate 构造：自定义 name
test "prompt_template_new_custom_name" {
  let pt = @prompt.PromptTemplate::new(template="hello", name="greeting")
  inspect(@component.Component::name(pt), content="greeting")
  inspect(pt.template(), content="hello")
}

///|
/// Component::component_type 返回 Prompt
test "prompt_template_component_type" {
  let pt = @prompt.PromptTemplate::new(template="hello")
  json_inspect(
    @component.Component::component_type(pt) == @component.ComponentType::Prompt,
    content=true,
  )
}

///|
/// Component::version 返回 "0.1.0"
test "prompt_template_component_version" {
  let pt = @prompt.PromptTemplate::new(template="hello")
  inspect(@component.Component::version(pt), content="0.1.0")
}

///|
/// Component::input_schema 返回空对象 JsonSchema
test "prompt_template_component_input_schema" {
  let pt = @prompt.PromptTemplate::new(template="hello")
  json_inspect(
    @component.Component::input_schema(pt) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}

///|
/// Component::output_schema 返回空对象 JsonSchema
test "prompt_template_component_output_schema" {
  let pt = @prompt.PromptTemplate::new(template="hello")
  json_inspect(
    @component.Component::output_schema(pt) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}

///|
/// Component::enabled 返回 true
test "prompt_template_component_enabled" {
  let pt = @prompt.PromptTemplate::new(template="hello")
  json_inspect(@component.Component::enabled(pt), content=true)
}

///|
/// PromptComponent::render 忽略 context 返回 template 内容
test "prompt_template_render" {
  let pt = @prompt.PromptTemplate::new(template="hello world")
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content="hello world")
}

///|
/// PromptComponent::render 忽略非空 context
test "prompt_template_render_ignores_context" {
  let pt = @prompt.PromptTemplate::new(template="static template")
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([("key", "value".to_json())])
  inspect(render_fn(context), content="static template")
}

///|
/// prelude_component 返回 prelude 模板的 PromptTemplate 实例
test "prelude_component" {
  let pt = @prompt.prelude_component()
  inspect(@component.Component::name(pt), content="prelude")
  // template 内容为 @prompt.prelude（非空系统提示词）
  json_inspect(pt.template().length() > 0, content=true)
  // component_type 为 Prompt
  json_inspect(
    @component.Component::component_type(pt) == @component.ComponentType::Prompt,
    content=true,
  )
}

///|
/// prelude_component 的 render 返回 prelude 内容
test "prelude_component_render" {
  let pt = @prompt.prelude_component()
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content=@prompt.prelude)
}

///|
/// 边界条件：空 template 字符串，template() 与 render 均返回空字符串
test "prompt_template_empty_template" {
  let pt = @prompt.PromptTemplate::new(template="")
  inspect(pt.template(), content="")
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content="")
}

///|
/// 边界条件：template 包含换行符的多行字符串
test "prompt_template_multiline_template" {
  let template = "line1\nline2\nline3"
  let pt = @prompt.PromptTemplate::new(template~)
  inspect(pt.template(), content=template)
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content=template)
}

///|
/// 边界条件：template 包含 Unicode 字符（中文、emoji、日文）
test "prompt_template_unicode_template" {
  let template = "你好世界 🌍 日本語"
  let pt = @prompt.PromptTemplate::new(template~)
  inspect(pt.template(), content=template)
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content=template)
}

///|
/// 边界条件：name 为空字符串（构造允许，name() 返回空字符串）
test "prompt_template_empty_name" {
  let pt = @prompt.PromptTemplate::new(template="hello", name="")
  inspect(@component.Component::name(pt), content="")
  inspect(pt.template(), content="hello")
}

///|
/// 边界条件：render 对多种不同 context 返回相同结果（验证忽略 context 契约）
test "prompt_template_render_various_contexts" {
  let pt = @prompt.PromptTemplate::new(template="invariant")
  let render_fn = @component.PromptComponent::render(pt)
  let ctx_empty : Map[String, Json] = Map([])
  let ctx_one : Map[String, Json] = Map([("a", "1".to_json())])
  let ctx_multi : Map[String, Json] = Map([
    ("a", "1".to_json()),
    ("b", "2".to_json()),
    ("c", "3".to_json()),
  ])
  inspect(render_fn(ctx_empty), content="invariant")
  inspect(render_fn(ctx_one), content="invariant")
  inspect(render_fn(ctx_multi), content="invariant")
}

///|
/// 状态交互：render 返回值与 template() 访问器返回值一致
/// 验证行为契约后置条件：PromptComponent::render(pt)(ctx) == pt.template()
test "prompt_template_render_equals_template_accessor" {
  let template = "consistency check"
  let pt = @prompt.PromptTemplate::new(template~)
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(pt.template(), content=template)
  inspect(render_fn(context), content=template)
}

///|
/// 状态交互：render 多次调用返回相同结果（纯函数性质）
test "prompt_template_render_pure_function" {
  let pt = @prompt.PromptTemplate::new(template="pure")
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content="pure")
  inspect(render_fn(context), content="pure")
  inspect(render_fn(context), content="pure")
}

///|
/// 状态交互：prelude_component 的 template() 与 @prompt.prelude 完全一致（向后兼容契约）
test "prelude_component_template_equals_prelude" {
  let pt = @prompt.prelude_component()
  inspect(pt.template(), content=@prompt.prelude)
}

///|
/// 状态交互：prelude_component 的 render 返回值与 template() 一致
test "prelude_component_render_equals_template" {
  let pt = @prompt.prelude_component()
  let render_fn = @component.PromptComponent::render(pt)
  let context : Map[String, Json] = Map([])
  inspect(render_fn(context), content=@prompt.prelude)
  inspect(pt.template(), content=@prompt.prelude)
}

///|
/// 状态交互：Component trait 各方法返回值相互独立，组合一致
test "prompt_template_component_methods_independent" {
  let pt = @prompt.PromptTemplate::new(template="t", name="n")
  inspect(@component.Component::name(pt), content="n")
  inspect(pt.template(), content="t")
  inspect(@component.Component::version(pt), content="0.1.0")
  json_inspect(@component.Component::enabled(pt), content=true)
  json_inspect(
    @component.Component::component_type(pt) == @component.ComponentType::Prompt,
    content=true,
  )
  json_inspect(
    @component.Component::input_schema(pt) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
  json_inspect(
    @component.Component::output_schema(pt) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}
