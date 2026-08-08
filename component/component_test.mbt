///|
/// mock 组件，通过字段配置不同 component_type/name/version/enabled
struct MockComponent {
  ctype : ComponentType
  cname : String
  cversion : String
  cenabled : Bool
}

///|
impl Component for MockComponent with fn component_type(self) {
  self.ctype
}

///|
impl Component for MockComponent with fn name(self) {
  self.cname
}

///|
impl Component for MockComponent with fn version(self) {
  self.cversion
}

///|
impl Component for MockComponent with fn input_schema(self) {
  ignore(self)
  @tool.JsonSchema::from_json({ "type": "object" })
}

///|
impl Component for MockComponent with fn output_schema(self) {
  ignore(self)
  @tool.JsonSchema::from_json({ "type": "object" })
}

///|
impl Component for MockComponent with fn enabled(self) {
  self.cenabled
}

///|
fn mock_tool(name~ : String, enabled? : Bool = true) -> MockComponent {
  MockComponent::{
    ctype: ComponentType::Tool,
    cname: name,
    cversion: "1.0",
    cenabled: enabled,
  }
}

///|
fn mock_skill(name~ : String, enabled? : Bool = true) -> MockComponent {
  MockComponent::{
    ctype: ComponentType::Skill,
    cname: name,
    cversion: "1.0",
    cenabled: enabled,
  }
}

///|
fn mock_prompt(name~ : String, enabled? : Bool = true) -> MockComponent {
  MockComponent::{
    ctype: ComponentType::Prompt,
    cname: name,
    cversion: "1.0",
    cenabled: enabled,
  }
}

///|
/// 排序数组后 inspect，消除 Map 遍历顺序不确定性
fn sorted_inspect(arr : Array[String], content~ : Array[String]) -> Unit raise {
  let sorted1 = arr.copy()
  sorted1.sort()
  let sorted2 = content.copy()
  sorted2.sort()
  json_inspect(sorted1, content=sorted2.to_json())
}

///|
test "component_type_eq" {
  json_inspect(ComponentType::Tool == ComponentType::Tool, content=true)
  json_inspect(ComponentType::Skill == ComponentType::Skill, content=true)
  json_inspect(ComponentType::Prompt == ComponentType::Prompt, content=true)
  json_inspect(ComponentType::Tool == ComponentType::Skill, content=false)
  json_inspect(ComponentType::Tool == ComponentType::Prompt, content=false)
  json_inspect(ComponentType::Skill == ComponentType::Prompt, content=false)
}

///|
test "component_type_to_json_from_json" {
  json_inspect(ComponentType::Tool.to_json(), content="Tool")
  json_inspect(ComponentType::Skill.to_json(), content="Skill")
  json_inspect(ComponentType::Prompt.to_json(), content="Prompt")
  let rt_tool : ComponentType = @json.from_json("Tool")
  let rt_skill : ComponentType = @json.from_json("Skill")
  let rt_prompt : ComponentType = @json.from_json("Prompt")
  json_inspect(rt_tool == ComponentType::Tool, content=true)
  json_inspect(rt_skill == ComponentType::Skill, content=true)
  json_inspect(rt_prompt == ComponentType::Prompt, content=true)
}

///|
test "registry_new" {
  let registry = ComponentRegistry::new()
  sorted_inspect(registry.list(), content=[])
  json_inspect(registry.is_enabled("any"), content=false)
  json_inspect(registry.get("any") is None, content=true)
}

///|
test "register_get" {
  let registry = ComponentRegistry::new()
  let tool = mock_tool(name="tool1")
  registry.register(component=tool)
  match registry.get("tool1") {
    Some(c) => inspect(c.name(), content="tool1")
    None => fail("expected Some")
  }
  json_inspect(registry.get("nonexistent") is None, content=true)
}

///|
test "unregister" {
  let registry = ComponentRegistry::new()
  let tool = mock_tool(name="tool1")
  registry.register(component=tool)
  registry.unregister("tool1")
  json_inspect(registry.get("tool1") is None, content=true)
  json_inspect(registry.is_enabled("tool1"), content=false)
  json_inspect(registry.list().contains("tool1"), content=false)
  // 注销不存在无操作
  registry.unregister("nonexistent")
  json_inspect(registry.list().length(), content=0)
}

///|
test "list" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_skill(name="skill1"))
  registry.register(component=mock_prompt(name="prompt1"))
  sorted_inspect(registry.list(), content=["prompt1", "skill1", "tool1"])
}

///|
test "list_by_type" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_skill(name="skill1"))
  registry.register(component=mock_prompt(name="prompt1"))
  sorted_inspect(registry.list_by_type(ctype=ComponentType::Tool), content=[
    "tool1",
  ])
  sorted_inspect(registry.list_by_type(ctype=ComponentType::Skill), content=[
    "skill1",
  ])
  sorted_inspect(registry.list_by_type(ctype=ComponentType::Prompt), content=[
    "prompt1",
  ])
}

///|
test "list_by_type_disjoint_union" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_skill(name="skill1"))
  registry.register(component=mock_prompt(name="prompt1"))
  let union : Array[String] = []
  union.push_iter(registry.list_by_type(ctype=ComponentType::Tool).iter())
  union.push_iter(registry.list_by_type(ctype=ComponentType::Skill).iter())
  union.push_iter(registry.list_by_type(ctype=ComponentType::Prompt).iter())
  union.sort()
  sorted_inspect(registry.list(), content=union)
}

///|
test "set_enabled" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=true))
  json_inspect(registry.is_enabled("tool1"), content=true)
  registry.set_enabled("tool1", enabled=false)
  json_inspect(registry.is_enabled("tool1"), content=false)
  registry.set_enabled("tool1", enabled=true)
  json_inspect(registry.is_enabled("tool1"), content=true)
  // 不存在无操作
  registry.set_enabled("nonexistent", enabled=true)
  json_inspect(registry.is_enabled("nonexistent"), content=false)
}

///|
test "set_enabled_names" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=false))
  registry.register(component=mock_skill(name="skill1", enabled=true))
  registry.register(component=mock_prompt(name="prompt1", enabled=true))
  registry.set_enabled_names(Set(["tool1", "skill1"]))
  json_inspect(registry.is_enabled("tool1"), content=true)
  json_inspect(registry.is_enabled("skill1"), content=true)
  json_inspect(registry.is_enabled("prompt1"), content=false)
}

///|
test "set_enabled_names_nonexistent" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=false))
  registry.set_enabled_names(Set(["tool1", "nonexistent"]))
  json_inspect(registry.is_enabled("tool1"), content=true)
}

///|
test "register_overwrite" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=true))
  registry.set_enabled("tool1", enabled=false)
  registry.register(component=mock_tool(name="tool1", enabled=false))
  match registry.get("tool1") {
    Some(c) => json_inspect(c.enabled(), content=false)
    None => fail("expected Some")
  }
  json_inspect(registry.is_enabled("tool1"), content=false)
}

///|
test "register_overwrite_resets_runtime_state" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=true))
  registry.set_enabled("tool1", enabled=false)
  // 覆盖后 is_enabled 取新默认值，非旧运行时状态
  registry.register(component=mock_tool(name="tool1", enabled=true))
  json_inspect(registry.is_enabled("tool1"), content=true)
}

///|
test "get_is_enabled_nonexistent" {
  let registry = ComponentRegistry::new()
  json_inspect(registry.get("nonexistent") is None, content=true)
  json_inspect(registry.is_enabled("nonexistent"), content=false)
}

///|
test "enabled_relationship" {
  let registry = ComponentRegistry::new()
  let tool = mock_tool(name="tool1", enabled=true)
  registry.register(component=tool)
  // Component::enabled() 始终返回组件自身声明的默认值
  match registry.get("tool1") {
    Some(c) => {
      json_inspect(c.enabled(), content=true)
      registry.set_enabled("tool1", enabled=false)
      // set_enabled 不影响 Component::enabled() 方法返回值
      json_inspect(c.enabled(), content=true)
    }
    None => fail("expected Some")
  }
  // is_enabled 返回运行时状态
  json_inspect(registry.is_enabled("tool1"), content=false)
}

///|
test "tool_component_type" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  json_inspect(
    Component::component_type(tool) == ComponentType::Tool,
    content=true,
  )
}

///|
test "tool_component_name" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  inspect(Component::name(tool), content="test_tool")
}

///|
test "tool_component_version" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  inspect(Component::version(tool), content="0.1.0")
}

///|
test "tool_component_input_schema" {
  let schema = @tool.JsonSchema::from_json({ "type": "object" })
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema~,
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  json_inspect(Component::input_schema(tool) == schema, content=true)
}

///|
test "tool_component_output_schema" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  json_inspect(
    Component::output_schema(tool) == @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}

///|
test "tool_component_enabled" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  json_inspect(Component::enabled(tool), content=true)
}

///|
async test "tool_component_execute" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  let execute_fn = ToolComponent::execute(tool)
  let result = execute_fn(Json::empty_object())
  json_inspect(result.to_json(), content=["Success", "ok"])
}

///|
test "tool_as_component" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  // as_component 返回的 Tool 的 Component::name 与原 Tool 的 desc.name 一致
  inspect(Component::name(as_component(tool)), content="test_tool")
}

///|
/// 契约9：ComponentRegistry 注册真实 Tool —— register 后 get 返回 Some，is_enabled 返回 true。
test "registry_register_tool" {
  let tool = @tool.Tool::new(
    description="test tool",
    name="test_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    @tool.ToolFn(_ => @tool.success("ok")),
  )
  let registry = ComponentRegistry::new()
  registry.register(component=as_component(tool))
  // registry.get 返回 Some，name 一致
  match registry.get("test_tool") {
    Some(c) => {
      inspect(c.name(), content="test_tool")
      // Component::enabled 默认 true
      json_inspect(c.enabled(), content=true)
    }
    None => fail("expected Some")
  }
  // is_enabled 返回 true（Component::enabled 默认 true）
  json_inspect(registry.is_enabled("test_tool"), content=true)
}
