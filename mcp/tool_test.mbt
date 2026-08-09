///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_input_output_schema" (t : @test.Test) {
  @mock.run(t, _ => {
    let call_fn : async (Json) -> @tool.ToolResult noraise = args => {
      @tool.ToolResult::success(args)
    }
    let schema = @tool.JsonSchema::from_json({ "type": "object" })
    let tool = McpTool::new(
      name="t",
      description="d",
      input_schema=schema,
      call_fn~,
    )
    assert_eq(@component.Component::input_schema(tool), schema)
    assert_eq(
      @component.Component::output_schema(tool),
      @tool.JsonSchema(Json::empty_object()),
    )
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_execute_multiple_calls" (t : @test.Test) {
  @mock.run(t, _ => {
    let call_fn : async (Json) -> @tool.ToolResult noraise = args => {
      @tool.ToolResult::success(args)
    }
    let tool = McpTool::new(
      name="t",
      description="d",
      input_schema=@tool.JsonSchema::from_json({ "type": "object" }),
      call_fn~,
    )
    let f1 = @component.ToolComponent::execute(tool)
    let r1 = f1(({ "x": 1 } : Json))
    guard r1 is @tool.ToolResult::Success(out1) else {
      fail("expected Success on first call")
    }
    assert_eq(out1.to_message().content(), ({ "x": 1 } : Json).stringify())
    let f2 = @component.ToolComponent::execute(tool)
    let r2 = f2(({ "x": 2 } : Json))
    guard r2 is @tool.ToolResult::Success(out2) else {
      fail("expected Success on second call")
    }
    assert_eq(out2.to_message().content(), ({ "x": 2 } : Json).stringify())
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_description_field" (t : @test.Test) {
  @mock.run(t, _ => {
    let call_fn : async (Json) -> @tool.ToolResult noraise = args => {
      @tool.ToolResult::success(args)
    }
    let tool = McpTool::new(
      name="my_tool",
      description="my description",
      input_schema=@tool.JsonSchema::from_json({ "type": "object" }),
      call_fn~,
    )
    assert_eq(tool.name, "my_tool")
    assert_eq(tool.description, "my description")
  })
}
