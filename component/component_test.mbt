///|
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
  @tool.JsonSchema::from_json({ "type": "object" })
}

///|
impl Component for MockComponent with fn output_schema(self) {
  @tool.JsonSchema::from_json({ "type": "object" })
}

///|
impl Component for MockComponent with fn enabled(self) {
  self.cenabled
}

///|
fn mock_tool(name~ : String, enabled? : Bool = true) -> MockComponent {
  MockComponent::{
    ctype: Tool,
    cname: name,
    cversion: "1.0",
    cenabled: enabled,
  }
}

///|
fn mock_skill(name~ : String, enabled? : Bool = true) -> MockComponent {
  MockComponent::{
    ctype: Skill,
    cname: name,
    cversion: "1.0",
    cenabled: enabled,
  }
}

///|
fn mock_prompt(name~ : String, enabled? : Bool = true) -> MockComponent {
  MockComponent::{
    ctype: Prompt,
    cname: name,
    cversion: "1.0",
    cenabled: enabled,
  }
}

///|
fn sorted_inspect(arr : Array[String], content~ : Array[String]) -> Unit {
  let sorted = arr.copy()
  sorted.sort()
  json_inspect(sorted, content~)
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
  json_inspect(
    @json.from_json[ComponentType]("Tool".to_json()),
    content=ComponentType::Tool,
  )
  json_inspect(
    @json.from_json[ComponentType]("Skill".to_json()),
    content=ComponentType::Skill,
  )
  json_inspect(
    @json.from_json[ComponentType]("Prompt".to_json()),
    content=ComponentType::Prompt,
  )
  json_inspect(
    @json.from_json[ComponentType](ComponentType::Tool.to_json()) ==
    ComponentType::Tool,
    content=true,
  )
  json_inspect(
    @json.from_json[ComponentType](ComponentType::Skill.to_json()) ==
    ComponentType::Skill,
    content=true,
  )
  json_inspect(
    @json.from_json[ComponentType](ComponentType::Prompt.to_json()) ==
    ComponentType::Prompt,
    content=true,
  )
}

///|
test "registry_new" {
  let registry = ComponentRegistry::new()
  sorted_inspect(registry.list(), content=[])
  json_inspect(registry.is_enabled("any"), content=false)
  json_inspect(registry.get("any").is_empty(), content=true)
}

///|
test "register_get" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  inspect(registry.get("tool1").unwrap().name(), content="tool1")
  json_inspect(
    registry.get("tool1").unwrap().component_type(),
    content=ComponentType::Tool,
  )
  json_inspect(registry.get("tool1").unwrap().enabled(), content=true)
  json_inspect(registry.get("nonexistent").is_empty(), content=true)
}

///|
test "unregister" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.unregister("tool1")
  json_inspect(registry.get("tool1").is_empty(), content=true)
  json_inspect(registry.is_enabled("tool1"), content=false)
  sorted_inspect(registry.list(), content=[])
  // 注销不存在无操作
  registry.register(component=mock_tool(name="tool2"))
  registry.unregister("nonexistent")
  json_inspect(registry.get("tool2").is_empty(), content=false)
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
  registry.register(component=mock_tool(name="tool2"))
  registry.register(component=mock_skill(name="skill1"))
  registry.register(component=mock_prompt(name="prompt1"))
  sorted_inspect(registry.list_by_type(type=Tool), content=["tool1", "tool2"])
  sorted_inspect(registry.list_by_type(type=Skill), content=["skill1"])
  sorted_inspect(registry.list_by_type(type=Prompt), content=["prompt1"])
}

///|
test "set_enabled" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_tool(name="tool2"))
  json_inspect(registry.is_enabled("tool1"), content=true)
  json_inspect(registry.is_enabled("tool2"), content=true)
  registry.set_enabled("tool1", enabled=false)
  json_inspect(registry.is_enabled("tool1"), content=false)
  // 隔离性：tool2 未被误改
  json_inspect(registry.is_enabled("tool2"), content=true)
  registry.set_enabled("tool1", enabled=true)
  json_inspect(registry.is_enabled("tool1"), content=true)
  // 不存在无操作，且不误改已注册组件
  registry.set_enabled("nonexistent", enabled=true)
  json_inspect(registry.is_enabled("nonexistent"), content=false)
  json_inspect(registry.is_enabled("tool1"), content=true)
  json_inspect(registry.is_enabled("tool2"), content=true)
}

///|
test "set_enabled_names" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_tool(name="tool2"))
  registry.register(component=mock_tool(name="tool3"))
  registry.set_enabled_names(Set::from_array(["tool1", "tool3"]))
  json_inspect(registry.is_enabled("tool1"), content=true)
  json_inspect(registry.is_enabled("tool2"), content=false)
  json_inspect(registry.is_enabled("tool3"), content=true)
  // 空 Set 边界：全量禁用所有已注册组件
  registry.set_enabled_names(Set::from_array([]))
  json_inspect(registry.is_enabled("tool1"), content=false)
  json_inspect(registry.is_enabled("tool2"), content=false)
  json_inspect(registry.is_enabled("tool3"), content=false)
}

///|
test "register_overwrite" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=true))
  json_inspect(registry.is_enabled("tool1"), content=true)
  registry.register(component=mock_tool(name="tool1", enabled=false))
  json_inspect(registry.is_enabled("tool1"), content=false)
  json_inspect(registry.get("tool1").unwrap().enabled(), content=false)
}

///|
test "get_is_enabled_nonexistent" {
  let registry = ComponentRegistry::new()
  json_inspect(registry.get("nonexistent").is_empty(), content=true)
  json_inspect(registry.is_enabled("nonexistent"), content=false)
}

///|
test "enabled_relationship" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=true))
  // register 后 is_enabled == component.enabled()
  json_inspect(registry.is_enabled("tool1"), content=true)
  // set_enabled 修改运行时状态，不影响 component.enabled()
  registry.set_enabled("tool1", enabled=false)
  json_inspect(registry.is_enabled("tool1"), content=false)
  json_inspect(registry.get("tool1").unwrap().enabled(), content=true)
}

///|
test "list_by_type_disjoint_union" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_skill(name="skill1"))
  registry.register(component=mock_prompt(name="prompt1"))
  let tools = registry.list_by_type(type=Tool)
  let skills = registry.list_by_type(type=Skill)
  let prompts = registry.list_by_type(type=Prompt)
  // 各类型结果互不相交：并集大小 == 各类型大小之和
  let mut union : Array[String] = []
  for name in tools {
    union.push(name)
  }
  for name in skills {
    union.push(name)
  }
  for name in prompts {
    union.push(name)
  }
  // 并集（排序后）== list()（排序后）
  sorted_inspect(union, content=["prompt1", "skill1", "tool1"])
  sorted_inspect(registry.list(), content=["prompt1", "skill1", "tool1"])
}

///|
test "set_enabled_names_nonexistent" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1"))
  registry.register(component=mock_tool(name="tool2"))
  // names 含未注册名称，不影响已注册组件的启用/禁用语义
  registry.set_enabled_names(Set::from_array(["tool1", "nonexistent"]))
  json_inspect(registry.is_enabled("tool1"), content=true)
  json_inspect(registry.is_enabled("tool2"), content=false)
  // 未注册名称本身仍不可启用
  json_inspect(registry.is_enabled("nonexistent"), content=false)
}

///|
test "register_overwrite_resets_runtime_state" {
  let registry = ComponentRegistry::new()
  registry.register(component=mock_tool(name="tool1", enabled=true))
  // 修改运行时状态为 false
  registry.set_enabled("tool1", enabled=false)
  json_inspect(registry.is_enabled("tool1"), content=false)
  // 覆盖后 is_enabled 取新组件默认值 true，而非旧运行时状态 false
  registry.register(component=mock_tool(name="tool1", enabled=true))
  json_inspect(registry.is_enabled("tool1"), content=true)
}
