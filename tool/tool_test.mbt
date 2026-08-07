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
    },
  )
}
