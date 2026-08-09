///|
/// Skill::new 构造：必填字段 name/description/location
test "skill_new_basic" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  inspect(@component.Component::name(skill), content="test-skill")
}

///|
/// Skill::new 构造：可选字段 license/compatibility/allowed_tools/metadata
test "skill_new_with_optional_fields" {
  let skill = @skills.Skill::new(
    name="full-skill",
    description="Full skill",
    location="/tmp/full",
    license="Apache-2.0",
    compatibility="Requires moon",
    allowed_tools=["tool1", "tool2"],
    metadata={ "author": "test".to_json() },
  )
  inspect(@component.Component::name(skill), content="full-skill")
}

///|
/// Component::component_type 返回 Skill
test "skill_component_type" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="desc",
    location="/loc",
  )
  json_inspect(
    @component.Component::component_type(skill) ==
    @component.ComponentType::Skill,
    content=true,
  )
}

///|
/// Component::name 返回 self.name
test "skill_component_name" {
  let skill = @skills.Skill::new(
    name="my-skill",
    description="desc",
    location="/loc",
  )
  inspect(@component.Component::name(skill), content="my-skill")
}

///|
/// Component::version 返回 "0.1.0"
test "skill_component_version" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="desc",
    location="/loc",
  )
  inspect(@component.Component::version(skill), content="0.1.0")
}

///|
/// Component::input_schema 返回空对象 JsonSchema
test "skill_component_input_schema" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="desc",
    location="/loc",
  )
  json_inspect(
    @component.Component::input_schema(skill) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}

///|
/// Component::output_schema 返回空对象 JsonSchema
test "skill_component_output_schema" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="desc",
    location="/loc",
  )
  json_inspect(
    @component.Component::output_schema(skill) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}

///|
/// Component::enabled 返回 true
test "skill_component_enabled" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="desc",
    location="/loc",
  )
  json_inspect(@component.Component::enabled(skill), content=true)
}

///|
/// SkillComponent::apply async 函数值调用：找到 System message 路径
/// apply 返回 async 函数值，调用需在 async 上下文，故使用 async test
/// （参照 component/component_test.mbt:336 的 async test "tool_component_execute" 模式）
async test "skill_component_apply_with_system_message" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let apply_fn = @component.SkillComponent::apply(skill)
  let messages : Array[@ai.Message] = [
    @ai.system_message(content="original system"),
    @ai.user_message(content="user msg"),
  ]
  apply_fn(messages)
  // 第一个 message 为 System，内容为 original + "\n\n" + skill_prompt
  inspect(
    messages[0].content(),
    content="original system\n\n<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
  // 第二个 message 不变
  inspect(messages[1].content(), content="user msg")
}

///|
/// SkillComponent::apply async 函数值调用：未找到 System message 路径
/// apply 返回 async 函数值，调用需在 async 上下文，故使用 async test
async test "skill_component_apply_without_system_message" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let apply_fn = @component.SkillComponent::apply(skill)
  let messages : Array[@ai.Message] = [
    @ai.user_message(content="user msg1"),
    @ai.user_message(content="user msg2"),
  ]
  apply_fn(messages)
  // insert(0) 新建 System message，原 messages 顺移
  inspect(
    messages[0].content(),
    content="<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
  inspect(messages[1].content(), content="user msg1")
  inspect(messages[2].content(), content="user msg2")
}

///|
/// SkillComponent::apply async 函数值调用：空 messages 边界
/// apply 返回 async 函数值，调用需在 async 上下文，故使用 async test
async test "skill_component_apply_empty_messages" {
  let skill = @skills.Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let apply_fn = @component.SkillComponent::apply(skill)
  let messages : Array[@ai.Message] = []
  apply_fn(messages)
  // insert(0) 新建 System message
  inspect(messages.length(), content="1")
  inspect(
    messages[0].content(),
    content="<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
}

///|
/// 边界条件：name 包含 Unicode 字符（中文）
test "skill_component_name_unicode" {
  let skill = @skills.Skill::new(
    name="技能",
    description="中文描述",
    location="/路径",
  )
  inspect(@component.Component::name(skill), content="技能")
}

///|
/// 边界条件：name 为空字符串（Skill::new 不验证字段约束，空 name 构造允许，name() 返回空字符串）
/// 参照 prompt/prompt_test.mbt:138-142 的 prompt_template_empty_name 模式
test "skill_component_empty_name" {
  let skill = @skills.Skill::new(name="", description="desc", location="/loc")
  inspect(@component.Component::name(skill), content="")
}

///|
/// 状态交互：Component trait 各方法返回值组合一致
test "skill_component_methods_consistent" {
  let skill = @skills.Skill::new(
    name="consistency-skill",
    description="desc",
    location="/loc",
  )
  inspect(@component.Component::name(skill), content="consistency-skill")
  inspect(@component.Component::version(skill), content="0.1.0")
  json_inspect(@component.Component::enabled(skill), content=true)
  json_inspect(
    @component.Component::component_type(skill) ==
    @component.ComponentType::Skill,
    content=true,
  )
  json_inspect(
    @component.Component::input_schema(skill) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
  json_inspect(
    @component.Component::output_schema(skill) ==
    @tool.JsonSchema(Json::empty_object()),
    content=true,
  )
}
