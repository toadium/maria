///|
/// MockServerTransport：内存 transport，用于测试 McpServer 服务端逻辑，不依赖外部进程。
/// 按 FIFO 顺序返回预设响应，记录发送的响应用于验证协议格式。
/// 记录是否调用 listen，EOF 时返回 Json::empty_object()（不抛 McpError，因 suberror 变体在 blackbox test 中不可构造）。
#warnings("-unused_field")
struct MockServerTransport {
  responses : Array[Json]
  mut idx : Int
  sent : Array[Json]
  mut listened : Bool
}

///|
#warnings("-unused_value")
fn MockServerTransport::new(responses : Array[Json]) -> MockServerTransport {
  MockServerTransport::{ responses, idx: 0, sent: [], listened: false }
}

///|
#warnings("-unused_value")
impl McpServerTransport for MockServerTransport with fn listen(
  self : MockServerTransport,
) -> async (Unit) -> Unit raise McpError {
  _ => self.listened = true
}

///|
impl McpServerTransport for MockServerTransport with fn send(
  self : MockServerTransport,
  request : Json,
) -> async (Unit) -> Unit raise McpError {
  _ => self.sent.push(request)
}

///|
impl McpServerTransport for MockServerTransport with fn receive(
  self : MockServerTransport,
) -> async (Unit) -> Json raise McpError {
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
impl McpServerTransport for MockServerTransport with fn close(
  self : MockServerTransport,
) -> Unit {
  ignore(self)
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_transport_trait_object_storable" (t : @test.Test) {
  @mock.run(t, _ => {
    let request : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "method": "initialize",
      "params": Json::empty_object(),
    }
    let transport = MockServerTransport::new([request])
    let server_transport : &McpServerTransport = transport
    let listen_fn = McpServerTransport::listen(server_transport)
    listen_fn(())
    assert_eq(transport.listened, true)
    let receive_fn = McpServerTransport::receive(server_transport)
    let received = receive_fn(())
    json_inspect(received, content={
      "jsonrpc": "2.0",
      "id": 1,
      "method": "initialize",
      "params": Json::empty_object(),
    })
    let response : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": Json::empty_object(),
    }
    let send_fn = McpServerTransport::send(server_transport, response)
    send_fn(())
    assert_eq(transport.sent.length(), 1)
    McpServerTransport::close(server_transport)
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_construct_with_registry_and_transport" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = MockServerTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let _ = server
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_known_methods_return_result" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = MockServerTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let init_req : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "method": "initialize",
      "params": Json::empty_object(),
    }
    let init_resp = server.handle_request(init_req)
    json_inspect(init_resp, content={
      "jsonrpc": "2.0",
      "id": 1,
      "result": Json::empty_object(),
    })
    let list_req : Json = {
      "jsonrpc": "2.0",
      "id": 2,
      "method": "tools/list",
      "params": Json::empty_object(),
    }
    let list_resp = server.handle_request(list_req)
    json_inspect(list_resp, content={
      "jsonrpc": "2.0",
      "id": 2,
      "result": Json::empty_object(),
    })
    let call_req : Json = {
      "jsonrpc": "2.0",
      "id": 3,
      "method": "tools/call",
      "params": Json::empty_object(),
    }
    let call_resp = server.handle_request(call_req)
    json_inspect(call_resp, content={
      "jsonrpc": "2.0",
      "id": 3,
      "result": Json::empty_object(),
    })
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_unknown_method_returns_error" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = MockServerTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = {
      "jsonrpc": "2.0",
      "id": 2,
      "method": "unknown",
      "params": Json::empty_object(),
    }
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 2,
      "error": { "code": -32601, "message": "method not found" },
    })
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_serve_returns_async_function_value" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let request : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "method": "initialize",
      "params": Json::empty_object(),
    }
    let transport = MockServerTransport::new([request])
    let server = McpServer::new(registry~, transport~)
    let f = McpServer::serve(server)
    f(())
    assert_eq(transport.listened, true)
    assert_eq(transport.sent.length(), 1)
    json_inspect(transport.sent[0], content={
      "jsonrpc": "2.0",
      "id": 1,
      "result": Json::empty_object(),
    })
  })
}
