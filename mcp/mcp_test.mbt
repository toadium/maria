///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/stdio_send_receive" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = @spawn.spawn_interactive(mock.group, "sh", [
      "-c", "read x; echo $x",
    ])
    let transport = StdioTransport::new(ip)
    let req : Json = { "jsonrpc": "2.0", "id": 0, "method": "ping" }
    let send_fn = McpTransport::send(transport, req)
    send_fn(())
    let recv_fn = McpTransport::receive(transport)
    let resp = recv_fn(())
    guard resp is Json::Object(obj) else { fail("expected object") }
    match obj.get("jsonrpc") {
      Some(String(v)) => assert_eq(v, "2.0")
      _ => fail("expected jsonrpc string")
    }
    transport.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/stdio_eof_raises_connection_failed" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = @spawn.spawn_interactive(mock.group, "sh", ["-c", "exit 0"])
    let transport = StdioTransport::new(ip)
    let recv_fn = McpTransport::receive(transport)
    try {
      let _ = recv_fn(())
      fail("expected ConnectionFailed on EOF")
    } catch {
      ConnectionFailed(msg) => assert_eq(msg, "EOF")
    }
    transport.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_initialize_and_list_tools" (t : @test.Test) {
  @mock.run(t, mock => {
    let script =
      #|read line
      #|echo '{"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"test","version":"0.1.0"}}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"echo","description":"echo tool","inputSchema":{"type":"object"}}]}}'
    let ip = @spawn.spawn_interactive(mock.group, "sh", ["-c", script])
    let transport = StdioTransport::new(ip)
    let client = McpClient::new(transport)
    client.initialize()
    let tools = client.list_tools()
    assert_eq(tools.length(), 1)
    assert_eq(tools[0].name(), "echo")
    client.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_call_tool_success" (t : @test.Test) {
  @mock.run(t, mock => {
    let script =
      #|read line
      #|echo '{"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"test","version":"0.1.0"}}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"echo","description":"echo tool","inputSchema":{"type":"object"}}]}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"hello"}]}}'
    let ip = @spawn.spawn_interactive(mock.group, "sh", ["-c", script])
    let transport = StdioTransport::new(ip)
    let client = McpClient::new(transport)
    client.initialize()
    let tools = client.list_tools()
    let tool = tools[0]
    let execute_fn = @component.ToolComponent::execute(tool)
    let result = execute_fn(({ "message": "hello" } : Json))
    guard result is @tool.ToolResult::Success(_) else {
      fail("expected Success")
    }
    client.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_call_tool_error" (t : @test.Test) {
  @mock.run(t, mock => {
    let script =
      #|read line
      #|echo '{"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"test","version":"0.1.0"}}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"fail_tool","description":"fail tool","inputSchema":{"type":"object"}}]}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":2,"error":{"code":-1,"message":"tool failed"}}'
    let ip = @spawn.spawn_interactive(mock.group, "sh", ["-c", script])
    let transport = StdioTransport::new(ip)
    let client = McpClient::new(transport)
    client.initialize()
    let tools = client.list_tools()
    let tool = tools[0]
    let execute_fn = @component.ToolComponent::execute(tool)
    let result = execute_fn(Json::empty_object())
    guard result is @tool.ToolResult::Failed(_) else { fail("expected Failed") }
    client.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_component_traits" (t : @test.Test) {
  @mock.run(t, mock => {
    let call_fn : async (Json) -> @tool.ToolResult noraise = args => {
      @tool.ToolResult::success(args)
    }
    let tool = McpTool::new(
      name="test_tool",
      description="a test tool",
      input_schema=@tool.JsonSchema::from_json({ "type": "object" }),
      call_fn~,
    )
    assert_eq(
      @component.Component::component_type(tool),
      @component.ComponentType::Tool,
    )
    assert_eq(@component.Component::name(tool), "test_tool")
    assert_eq(@component.Component::version(tool), "0.2.0")
    assert_eq(@component.Component::enabled(tool), true)
    let execute_fn = @component.ToolComponent::execute(tool)
    let result = execute_fn(({ "x": 1 } : Json))
    guard result is @tool.ToolResult::Success(_) else {
      fail("expected Success")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/stdio_close_idempotent" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = @spawn.spawn_interactive(mock.group, "cat", [])
    let transport = StdioTransport::new(ip)
    transport.close()
    transport.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_next_id_increments" (t : @test.Test) {
  @mock.run(t, mock => {
    let script =
      #|read line
      #|echo '{"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"test","version":"0.1.0"}}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":1,"result":{"tools":[]}}'
      #|read line
      #|echo '{"jsonrpc":"2.0","id":2,"result":{"content":[]}}'
    let ip = @spawn.spawn_interactive(mock.group, "sh", ["-c", script])
    let transport = StdioTransport::new(ip)
    let client = McpClient::new(transport)
    client.initialize()
    let _ = client.list_tools()
    let result = client.call_tool("any", Json::empty_object())
    guard result is @tool.ToolResult::Success(_) else {
      fail("expected Success")
    }
    client.close()
  })
}
