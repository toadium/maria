///|
test "tool_desc" {
  json_inspect(
    @tool.tool_desc(
      description="A sample tool",
      name="sample_tool",
      schema=@tool.JsonSchema::from_json({
        "type": "object",
        "properties": Json::empty_object(),
      }),
    ),
    content={
      "description": "A sample tool",
      "name": "sample_tool",
      "schema": { "type": "object", "properties": Json::empty_object() },
      "permissions": [],
    },
  )
}

///|
test "tool_desc_with_permissions" {
  let perm = @perm.Permission::PathAccess("/path", @perm.Access::Read)
  let desc = @tool.tool_desc(
    description="A tool with permissions",
    name="perm_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    permissions=[perm],
  )
  json_inspect(desc.permissions, content=[perm])
}

///|
test "tool_desc_default_permissions" {
  let desc = @tool.tool_desc(
    description="default",
    name="default_perm_tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
  )
  json_inspect(desc.permissions.length(), content=0)
}

///|
test "tool_new_with_permissions" {
  let perm = @perm.Permission::CommandExecution("ls")
  let tool = @tool.Tool::new(
    description="tool with permissions",
    name="tool_perm",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
    permissions=[perm],
    @tool.ToolFn(_ => @tool.failed("test")),
  )
  json_inspect(tool.desc.permissions, content=[perm])
}

///|
/// 契约5：ToolDesc Eq 含 permissions —— permissions 字段不同时 Eq 比较结果为 false。
test "tool_desc_eq_with_permissions" {
  let perm = @perm.Permission::PathAccess("/path", @perm.Access::Read)
  let schema = @tool.JsonSchema::from_json({ "type": "object" })
  let desc1 = @tool.tool_desc(description="tool", name="tool", schema~, permissions=[
    perm,
  ])
  let desc2 = @tool.tool_desc(description="tool", name="tool", schema~, permissions=[
    perm,
  ])
  let desc3 = @tool.tool_desc(description="tool", name="tool", schema~, permissions=[])
  // 相同 permissions 相等
  json_inspect(desc1 == desc2, content=true)
  // 不同 permissions 不等
  json_inspect(desc1 == desc3, content=false)
}
