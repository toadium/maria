///|
test "parse_skill_from_content" {
  let content =
    #|---
    #|name: pdf-processing
    #|description: Extract text and tables from PDF files.
    #|license: Apache-2.0
    #|compatibility: Requires `moon`
    #|allowed-tools:
    #|  - execute_command
    #|metadata:
    #|  author: example-org
    #|  version: "1.0"
    #|---
    #|
    #|Use this skill to handle PDFs.
  let skill = parse_skill_from_content(
    content,
    directory="pdf-processing",
    location="/tmp/skill/SKILL.md",
  )
  json_inspect(skill, content={
    "name": "pdf-processing",
    "description": "Extract text and tables from PDF files.",
    "license": "Apache-2.0",
    "compatibility": "Requires `moon`",
    "allowed_tools": ["execute_command"],
    "metadata": { "author": "example-org", "version": "1.0" },
    "location": "/tmp/skill/SKILL.md",
  })
}

///|
test "parse_skill_from_content/space-delimited-allowed-tools" {
  let content =
    #|---
    #|name: sample-skill
    #|description: A sample skill.
    #|allowed-tools: tool1 tool2 tool3
    #|---
    #|
    #|This is a sample skill.
  let skill = parse_skill_from_content(
    content,
    directory="sample-skill",
    location="/tmp/skill/SKILL.md",
  )
  json_inspect(skill, content={
    "name": "sample-skill",
    "description": "A sample skill.",
    "allowed_tools": ["tool1", "tool2", "tool3"],
    "location": "/tmp/skill/SKILL.md",
  })
}

///|
test "parse_skill_from_content/invalid-allowed-tools" {
  let content =
    #|---
    #|name: sample-skill
    #|description: A sample skill.
    #|allowed-tools:
    #|  tool1: true
    #|  tool2: false
    #|---
    #|
    #|This is a sample skill.
  let result = try
    parse_skill_from_content(
      content,
      directory="sample-skill",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": [
      "SkillFormatError", "Field 'allowed-tools' must be a space-delimited string or array of strings, got {\"tool1\":true,\"tool2\":false}",
    ],
  })
}

///|
test "parse_skill_from_content/empty-description" {
  let content =
    #|---
    #|name: invalid-skill
    #|description: ""
    #|---
    #|
    #|This skill has an invalid description.
  let result = try
    parse_skill_from_content(
      content,
      directory="invalid-skill",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": [
      "SkillFormatError", "Field 'description' must be a non-empty string",
    ],
  })
}

///|
test "parse_skill_from_content/invalid-name" {
  let content =
    #|---
    #|name: invalid--name
    #|description: A skill with invalid name.
    #|---
    #|
    #|This skill has an invalid name.
  let result = try
    parse_skill_from_content(
      content,
      directory="invalid--name",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Skill name cannot contain consecutive hyphens"],
  })
}

///|
test "parse_skill_from_content/name-mismatches-directory" {
  let content =
    #|---
    #|name: mismatch-directory
    #|description: A skill with mismatched directory name.
    #|---
    #|
    #|This skill has a mismatched directory name.
  let result = try
    parse_skill_from_content(
      content,
      directory="different-directory",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Directory name must match skill name"],
  })
}

///|
test "parse_skill_from_content/long-name" {
  let long_skill_name = "skill-name-is-way-too-long-because-it-exceeds-the-sixty-four-character-limit-imposed"
  let content =
    $|---
    $|name: \{long_skill_name}
    $|description: A skill with a name that is too long.
    $|---
    $|
    $|This skill has a name that is too long.
  let result = try
    parse_skill_from_content(
      content,
      directory=long_skill_name,
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Skill name exceeds 64 character limit"],
  })
}

///|
test "parse_skill_from_content/long-description" {
  let long_description = "A".repeat(1025)
  let content =
    $|---
    $|name: long-description-skill
    $|description: \{long_description}
    $|---
    $|
    $|This skill has a description that is too long.
  let result = try
    parse_skill_from_content(
      content,
      directory="long-description-skill",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Description exceeds 1024 character limit"],
  })
}

///|
test "parse_skill_from_content/empty-name" {
  let content =
    #|---
    #|name: ""
    #|description: A skill with an empty name.
    #|---
    #|
    #|This skill has an empty name.
  let result = try
    parse_skill_from_content(
      content,
      directory="",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Field 'name' must be a non-empty string"],
  })
}

///|
test "parse_skill_from_content/name-starts-with-hyphen" {
  let content =
    #|---
    #|name: -invalidname
    #|description: A skill with a name that starts with a hyphen.
    #|---
    #|
    #|This skill has a name that starts with a hyphen.
  let result = try
    parse_skill_from_content(
      content,
      directory="-invalidname",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Skill name cannot start or end with a hyphen"],
  })
}

///|
test "parse_skill_from_content/name-ends-with-hyphen" {
  let content =
    #|---
    #|name: invalidname-
    #|description: A skill with a name that ends with a hyphen.
    #|---
    #|
    #|This skill has a name that ends with a hyphen.
  let result = try
    parse_skill_from_content(
      content,
      directory="invalidname-",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Skill name cannot start or end with a hyphen"],
  })
}

///|
test "parse_skill_from_content/missing-name" {
  let content =
    #|---
    #|description: A skill missing the name field.
    #|---
    #|
    #|This skill is missing the name field.
  let result = try
    parse_skill_from_content(
      content,
      directory="missing-name",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Missing field 'name'"],
  })
}

///|
test "parse_skill_from_content/missing-description" {
  let content =
    #|---
    #|name: missing-description
    #|---
    #|
    #|This skill is missing the description field.
  let result = try
    parse_skill_from_content(
      content,
      directory="missing-description",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Missing field 'description'"],
  })
}

///|
test "parse_skill_from_content/missing-frontmatter" {
  let content =
    #|This skill file is missing frontmatter.
  let result = try
    parse_skill_from_content(
      content,
      directory="missing-frontmatter",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Missing field 'name'"],
  })
}

///|
test "parse_skill_from_content/non-string-name" {
  let content =
    #|---
    #|name: 12345
    #|description: A skill with a non-string name.
    #|---
    #|
    #|This skill has a non-string name.
  let result = try
    parse_skill_from_content(
      content,
      directory="12345",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": ["SkillFormatError", "Field 'name' must be a string, got 12345"],
  })
}

///|
test "parse_skill_from_content/non-string-description" {
  let content =
    #|---
    #|name: non-string-description
    #|description: 67890
    #|---
    #|
    #|This skill has a non-string description.
  let result = try
    parse_skill_from_content(
      content,
      directory="non-string-description",
      location="/tmp/skill/SKILL.md",
    )
  catch {
    e => Err(e)
  } noraise {
    x => Ok(x)
  }
  json_inspect(result, content={
    "Err": [
      "SkillFormatError", "Field 'description' must be a string, got 67890",
    ],
  })
}

///|
/// format_prompt 生成单 skill XML（不含 SKILLS 说明 preamble）
test "skill_format_prompt_single_skill_xml" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  inspect(
    skill.format_prompt(),
    content="<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
}

///|
/// format_prompt 不含 SKILLS 说明 preamble（验证格式差异设计决策）
test "skill_format_prompt_no_preamble" {
  let skill = Skill::new(name="test-skill", description="desc", location="/loc")
  let prompt = skill.format_prompt()
  // 不含 "SKILLS" 说明文本
  json_inspect(prompt.contains("SKILLS"), content=false)
  // 不含 "You are equipped with" 引导文本
  json_inspect(prompt.contains("You are equipped with"), content=false)
  // 以 <available_skills> 开头
  json_inspect(prompt.has_prefix("<available_skills>"), content=true)
}

///|
/// format_prompt 包含特殊字符的 name/description/location
test "skill_format_prompt_special_chars" {
  let skill = Skill::new(
    name="skill-with-unicode",
    description="中文描述 🌍",
    location="/path/with spaces",
  )
  inspect(
    skill.format_prompt(),
    content="<available_skills>\n  <skill>\n    <name>skill-with-unicode</name>\n    <description>中文描述 🌍</description>\n    <location>/path/with spaces</location>\n  </skill>\n</available_skills>",
  )
}

///|
/// apply_to_messages 找到 System message 路径：追加 skill_prompt
test "skill_apply_to_messages_with_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = [
    @ai.system_message(content="original system"),
    @ai.user_message(content="user msg"),
  ]
  skill.apply_to_messages(messages)
  inspect(
    messages[0].content(),
    content="original system\n\n<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
  inspect(messages[1].content(), content="user msg")
}

///|
/// apply_to_messages 未找到 System message 路径：insert(0) 新建 System message
test "skill_apply_to_messages_without_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = [
    @ai.user_message(content="user msg1"),
    @ai.user_message(content="user msg2"),
  ]
  skill.apply_to_messages(messages)
  inspect(
    messages[0].content(),
    content="<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
  inspect(messages[1].content(), content="user msg1")
  inspect(messages[2].content(), content="user msg2")
}

///|
/// apply_to_messages 多个 System message 时仅处理第一个
test "skill_apply_to_messages_multiple_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = [
    @ai.system_message(content="first system"),
    @ai.system_message(content="second system"),
  ]
  skill.apply_to_messages(messages)
  // 仅第一个 System message 被追加 skill_prompt
  inspect(
    messages[0].content(),
    content="first system\n\n<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
  // 第二个 System message 不变
  inspect(messages[1].content(), content="second system")
}

///|
/// apply_to_messages 空 messages 边界：insert(0) 创建新 System message
test "skill_apply_to_messages_empty_messages" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = []
  skill.apply_to_messages(messages)
  inspect(messages.length(), content="1")
  inspect(
    messages[0].content(),
    content="<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>",
  )
}

///|
/// apply_to_messages 幂等性：连续调用两次，skill_prompt 追加两次（不幂等）
/// 与 Loader::apply 行为一致（Loader::apply 也不幂等，每次调用都追加）
test "skill_apply_to_messages_not_idempotent" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = [@ai.system_message(content="original")]
  skill.apply_to_messages(messages)
  skill.apply_to_messages(messages)
  // 两次追加后，system message 含两个 skill_prompt
  let expected = "original\n\n<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>\n\n<available_skills>\n  <skill>\n    <name>test-skill</name>\n    <description>A test skill</description>\n    <location>/tmp/skill</location>\n  </skill>\n</available_skills>"
  inspect(messages[0].content(), content=expected)
}

///|
/// Component trait 6 方法 whitebox 覆盖
test "skill_component_trait_whitebox" {
  let skill = Skill::new(
    name="wb-skill",
    description="whitebox desc",
    location="/wb/loc",
  )
  json_inspect(
    @component.Component::component_type(skill) ==
    @component.ComponentType::Skill,
    content=true,
  )
  inspect(@component.Component::name(skill), content="wb-skill")
  inspect(@component.Component::version(skill), content="0.2.0")
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
  json_inspect(@component.Component::enabled(skill), content=true)
}

///|
/// SkillComponent::apply async 函数值调用 whitebox 覆盖
/// apply 返回 async 函数值，调用需在 async 上下文，故使用 async test
async test "skill_component_apply_whitebox" {
  let skill = Skill::new(
    name="wb-skill",
    description="whitebox desc",
    location="/wb/loc",
  )
  let apply_fn = @component.SkillComponent::apply(skill)
  let messages : Array[@ai.Message] = [@ai.system_message(content="sys")]
  apply_fn(messages)
  inspect(
    messages[0].content(),
    content="sys\n\n<available_skills>\n  <skill>\n    <name>wb-skill</name>\n    <description>whitebox desc</description>\n    <location>/wb/loc</location>\n  </skill>\n</available_skills>",
  )
}

///|
/// Skill::new 可选字段存储验证：whitebox 直接访问包私有字段验证构造契约
/// 比 to_json() 更精确地验证每个字段正确存储
test "skill_new_optional_fields_storage" {
  let skill = Skill::new(
    name="full-skill",
    description="Full skill",
    location="/tmp/full",
    license="Apache-2.0",
    compatibility="Requires moon",
    allowed_tools=["tool1", "tool2"],
    metadata={ "author": "test".to_json() },
  )
  // 必填字段存储
  inspect(skill.name, content="full-skill")
  inspect(skill.description, content="Full skill")
  inspect(skill.location, content="/tmp/full")
  // 可选字段 license 存储
  match skill.license {
    Some(l) => inspect(l, content="Apache-2.0")
    None => inspect("none", content="some")
  }
  // 可选字段 compatibility 存储
  match skill.compatibility {
    Some(c) => inspect(c, content="Requires moon")
    None => inspect("none", content="some")
  }
  // allowed_tools 数组存储
  json_inspect(skill.allowed_tools.length() == 2, content=true)
  inspect(skill.allowed_tools[0], content="tool1")
  inspect(skill.allowed_tools[1], content="tool2")
  // metadata 非空存储
  match skill.metadata {
    Some(_) => json_inspect(true, content=true)
    None => inspect("none", content="some")
  }
}

///|
/// apply_to_messages 找到 System message 后 messages 长度不变（显式验证行为契约）
test "skill_apply_to_messages_length_unchanged_with_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = [
    @ai.system_message(content="original system"),
    @ai.user_message(content="user msg"),
  ]
  let original_length = messages.length()
  skill.apply_to_messages(messages)
  json_inspect(messages.length() == original_length, content=true)
}

///|
/// apply_to_messages 未找到 System message 后 messages 长度 +1（显式验证行为契约）
test "skill_apply_to_messages_length_increased_without_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  let messages : Array[@ai.Message] = [
    @ai.user_message(content="user msg1"),
    @ai.user_message(content="user msg2"),
  ]
  let original_length = messages.length()
  skill.apply_to_messages(messages)
  json_inspect(messages.length() == original_length + 1, content=true)
}

///|
/// SkillComponent::apply 与 apply_to_messages 等价性：找到 System message 路径
/// 设计契约：apply(skill)(messages) 等价于 skill.apply_to_messages(messages)
async test "skill_apply_equivalence_with_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  // 通过 apply 调用
  let messages_apply : Array[@ai.Message] = [
    @ai.system_message(content="original system"),
    @ai.user_message(content="user msg"),
  ]
  let apply_fn = @component.SkillComponent::apply(skill)
  apply_fn(messages_apply)
  // 通过 apply_to_messages 调用
  let messages_direct : Array[@ai.Message] = [
    @ai.system_message(content="original system"),
    @ai.user_message(content="user msg"),
  ]
  skill.apply_to_messages(messages_direct)
  // 两者结果一致
  inspect(messages_apply[0].content(), content=messages_direct[0].content())
  inspect(messages_apply[1].content(), content=messages_direct[1].content())
  json_inspect(
    messages_apply.length() == messages_direct.length(),
    content=true,
  )
}

///|
/// SkillComponent::apply 与 apply_to_messages 等价性：未找到 System message 路径
/// 设计契约：apply(skill)(messages) 等价于 skill.apply_to_messages(messages)
async test "skill_apply_equivalence_without_system" {
  let skill = Skill::new(
    name="test-skill",
    description="A test skill",
    location="/tmp/skill",
  )
  // 通过 apply 调用
  let messages_apply : Array[@ai.Message] = [
    @ai.user_message(content="user msg1"),
    @ai.user_message(content="user msg2"),
  ]
  let apply_fn = @component.SkillComponent::apply(skill)
  apply_fn(messages_apply)
  // 通过 apply_to_messages 调用
  let messages_direct : Array[@ai.Message] = [
    @ai.user_message(content="user msg1"),
    @ai.user_message(content="user msg2"),
  ]
  skill.apply_to_messages(messages_direct)
  // 两者结果一致
  inspect(messages_apply[0].content(), content=messages_direct[0].content())
  inspect(messages_apply[1].content(), content=messages_direct[1].content())
  inspect(messages_apply[2].content(), content=messages_direct[2].content())
  json_inspect(
    messages_apply.length() == messages_direct.length(),
    content=true,
  )
}
