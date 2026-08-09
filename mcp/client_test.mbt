///|
/// MockTransport：内存 transport，用于测试 McpClient 协议逻辑，不依赖外部进程。
/// 按 FIFO 顺序返回预设响应，记录发送的请求用于验证协议格式。
/// EOF 时返回 Json::empty_object()（不抛 McpError，因 suberror 变体在 blackbox test 中不可构造）。
struct MockTransport {
  responses : Array[Json]
  mut idx : Int
  sent : Array[Json]
}

///|
fn MockTransport::new(responses : Array[Json]) -> MockTransport {
  MockTransport::{ responses, idx: 0, sent: [] }
}

///|
impl McpTransport for MockTransport with fn send(
  self : MockTransport,
  request : Json,
) -> async (Unit) -> Unit raise McpError {
  _ => self.sent.push(request)
}

///|
impl McpTransport for MockTransport with fn receive(self : MockTransport) -> async (
  Unit,
) -> Json raise McpError {
  _ => {
    if self.idx < self.responses.length() {
      let resp = self.responses[self.idx]
      self.idx = self.idx + 1
      resp
    } else {
      Json::empty_object()
    }
  }
}

///|
impl McpTransport for MockTransport with fn close(self : MockTransport) -> Unit {
  ignore(self)
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_initialize_success" (t : @test.Test) {
  @mock.run(t, _ => {
    let response : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let transport = MockTransport::new([response])
    let client = McpClient::new(transport)
    client.initialize()
    assert_eq(transport.sent.length(), 1)
    guard transport.sent[0] is Json::Object(obj) else {
      fail("expected object")
    }
    match obj.get("method") {
      Some(String(m)) => assert_eq(m, "initialize")
      _ => fail("expected method string")
    }
    match obj.get("params") {
      Some(Json::Object(params)) =>
        match params.get("protocolVersion") {
          Some(String(v)) => assert_eq(v, "2024-11-05")
          _ => fail("expected protocolVersion string")
        }
      _ => fail("expected params object")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_initialize_missing_jsonrpc" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = MockTransport::new([Json::empty_object()])
    let client = McpClient::new(transport)
    try {
      client.initialize()
      fail("expected HandshakeFailed")
    } catch {
      HandshakeFailed(msg) => assert_eq(msg, "initialize failed")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_initialize_error_response" (t : @test.Test) {
  @mock.run(t, _ => {
    let response : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "error": { "code": -1, "message": "init failed" },
    }
    let transport = MockTransport::new([response])
    let client = McpClient::new(transport)
    try {
      client.initialize()
      fail("expected HandshakeFailed")
    } catch {
      HandshakeFailed(msg) => assert_eq(msg, "initialize failed")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_list_tools_empty" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": { "tools": [] },
    }
    let transport = MockTransport::new([init_resp, list_resp])
    let client = McpClient::new(transport)
    client.initialize()
    let tools = client.list_tools()
    assert_eq(tools.length(), 0)
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_list_tools_missing_tools_field" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": Json::empty_object(),
    }
    let transport = MockTransport::new([init_resp, list_resp])
    let client = McpClient::new(transport)
    client.initialize()
    try {
      let _ = client.list_tools()
      fail("expected ProtocolError")
    } catch {
      ProtocolError(msg) => assert_eq(msg, "tools/list failed")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_list_tools_tool_missing_name" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": {
        "tools": [
          { "description": "no name", "inputSchema": { "type": "object" } },
        ],
      },
    }
    let transport = MockTransport::new([init_resp, list_resp])
    let client = McpClient::new(transport)
    client.initialize()
    try {
      let _ = client.list_tools()
      fail("expected ProtocolError")
    } catch {
      ProtocolError(msg) => assert_eq(msg, "tools/list failed")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_list_tools_tool_missing_input_schema" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": { "tools": [{ "name": "t", "description": "no schema" }] },
    }
    let transport = MockTransport::new([init_resp, list_resp])
    let client = McpClient::new(transport)
    client.initialize()
    try {
      let _ = client.list_tools()
      fail("expected ProtocolError")
    } catch {
      ProtocolError(msg) => assert_eq(msg, "tools/list failed")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_list_tools_description_optional" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": {
        "tools": [{ "name": "t", "inputSchema": { "type": "object" } }],
      },
    }
    let transport = MockTransport::new([init_resp, list_resp])
    let client = McpClient::new(transport)
    client.initialize()
    let tools = client.list_tools()
    assert_eq(tools.length(), 1)
    assert_eq(tools[0].description, "")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_list_tools_description_null" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": {
        "tools": [
          {
            "name": "t",
            "description": null,
            "inputSchema": { "type": "object" },
          },
        ],
      },
    }
    let transport = MockTransport::new([init_resp, list_resp])
    let client = McpClient::new(transport)
    client.initialize()
    let tools = client.list_tools()
    assert_eq(tools.length(), 1)
    assert_eq(tools[0].description, "")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_call_tool_malformed_response" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let transport = MockTransport::new([init_resp, Json::empty_object()])
    let client = McpClient::new(transport)
    client.initialize()
    let result = client.call_tool("any", Json::empty_object())
    guard result is @tool.ToolResult::Failed(_) else {
      fail("expected Failed for malformed response")
    }
    assert_eq(result.to_string(), "mcp call failed")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/client_request_id_increments" (t : @test.Test) {
  @mock.run(t, _ => {
    let init_resp : Json = {
      "jsonrpc": "2.0",
      "id": 0,
      "result": {
        "protocolVersion": "2024-11-05",
        "serverInfo": { "name": "test", "version": "0.1.0" },
      },
    }
    let list_resp : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": { "tools": [] },
    }
    let call_resp : Json = {
      "jsonrpc": "2.0",
      "id": 2,
      "result": { "content": [] },
    }
    let transport = MockTransport::new([init_resp, list_resp, call_resp])
    let client = McpClient::new(transport)
    client.initialize()
    let _ = client.list_tools()
    let _ = client.call_tool("any", Json::empty_object())
    assert_eq(transport.sent.length(), 3)
    guard transport.sent[0] is Json::Object(o0) else { fail("expected object") }
    match o0.get("id") {
      Some(Number(n, ..)) => assert_eq(n.to_int(), 0)
      _ => fail("expected number id")
    }
    match o0.get("method") {
      Some(String(m)) => assert_eq(m, "initialize")
      _ => fail("expected method string")
    }
    guard transport.sent[1] is Json::Object(o1) else { fail("expected object") }
    match o1.get("id") {
      Some(Number(n, ..)) => assert_eq(n.to_int(), 1)
      _ => fail("expected number id")
    }
    match o1.get("method") {
      Some(String(m)) => assert_eq(m, "tools/list")
      _ => fail("expected method string")
    }
    guard transport.sent[2] is Json::Object(o2) else { fail("expected object") }
    match o2.get("id") {
      Some(Number(n, ..)) => assert_eq(n.to_int(), 2)
      _ => fail("expected number id")
    }
    match o2.get("method") {
      Some(String(m)) => assert_eq(m, "tools/call")
      _ => fail("expected method string")
    }
  })
}
