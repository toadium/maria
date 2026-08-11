///|
/// R20 McpServer 边界条件验证测试（Verifier 编写）。
/// 补充 server_test.mbt 未覆盖的 handle_request id 回填逻辑边界条件。
/// 基于 detail_v20.md 行为契约：
/// - request 非 Object 或 id 缺失/非 Number → id 回填 0
/// - JSON-RPC 2.0 协议一致性：响应包含 jsonrpc/id/result 或 jsonrpc/id/error 字段

///|
/// 边界测试用 MockServerTransport，仅用于构造 McpServer，不参与测试逻辑。
struct BoundaryMockTransport {
  responses : Array[Json]
  mut idx : Int
  sent : Array[Json]
  mut listened : Bool
}

///|
fn BoundaryMockTransport::new(responses : Array[Json]) -> BoundaryMockTransport {
  BoundaryMockTransport::{ responses, idx: 0, sent: [], listened: false }
}

///|
impl McpServerTransport for BoundaryMockTransport with fn listen(
  self : BoundaryMockTransport,
) -> async (Unit) -> Unit raise McpError {
  _ => self.listened = true
}

///|
impl McpServerTransport for BoundaryMockTransport with fn send(
  self : BoundaryMockTransport,
  request : Json,
) -> async (Unit) -> Unit raise McpError {
  _ => self.sent.push(request)
}

///|
impl McpServerTransport for BoundaryMockTransport with fn receive(
  self : BoundaryMockTransport,
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
impl McpServerTransport for BoundaryMockTransport with fn close(
  self : BoundaryMockTransport,
) -> Unit {
  ignore(self)
}

///|
/// 行为契约：id 缺失 → id 回填 0，method 为具名方法 → 返回 result 占位响应。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_missing_id_defaults_to_zero" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = BoundaryMockTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = {
      "jsonrpc": "2.0",
      "method": "initialize",
      "params": Json::empty_object(),
    }
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 0,
      "result": Json::empty_object(),
    })
  })
}

///|
/// 行为契约：id 为非 Number（String）→ id 回填 0，method 为具名方法 → 返回 result 占位响应。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_string_id_defaults_to_zero" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = BoundaryMockTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = {
      "jsonrpc": "2.0",
      "id": "abc",
      "method": "tools/list",
      "params": Json::empty_object(),
    }
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 0,
      "result": Json::empty_object(),
    })
  })
}

///|
/// 行为契约：id 为 Null → id 回填 0，method 为具名方法 → 返回 result 占位响应。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_null_id_defaults_to_zero" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = BoundaryMockTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = {
      "jsonrpc": "2.0",
      "id": null,
      "method": "tools/call",
      "params": Json::empty_object(),
    }
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 0,
      "result": Json::empty_object(),
    })
  })
}

///|
/// 行为契约：request 非 Object（Array）→ id 回填 0，走默认分支 → 返回 error 占位响应。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_non_object_returns_error" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = BoundaryMockTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = [1, 2, 3]
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 0,
      "error": { "code": -32601, "message": "method not found" },
    })
  })
}

///|
/// 行为契约：空 Object（无 id 无 method）→ id 回填 0，method 缺失走默认分支 → 返回 error 占位响应。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_empty_object_returns_error" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = BoundaryMockTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = Json::empty_object()
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 0,
      "error": { "code": -32601, "message": "method not found" },
    })
  })
}

///|
/// 行为契约：Object 有 id 无 method → id 保留，method 缺失走默认分支 → 返回 error 占位响应。
/// 验证 id 回填与 method 解析的独立性（有 id 时不回填）。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_handle_request_id_preserved_when_method_missing" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = BoundaryMockTransport::new([])
    let server = McpServer::new(registry~, transport~)
    let request : Json = { "jsonrpc": "2.0", "id": 42 }
    let response = server.handle_request(request)
    json_inspect(response, content={
      "jsonrpc": "2.0",
      "id": 42,
      "error": { "code": -32601, "message": "method not found" },
    })
  })
}

///|
/// 行为契约：serve 单次循环后 listened=true 且 sent 记录恰好一个响应。
/// 验证 serve 的状态交互（listen 标志设置 + send 记录响应）。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_serve_single_cycle_sets_listened_and_records_sent" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let request : Json = {
      "jsonrpc": "2.0",
      "id": 7,
      "method": "tools/list",
      "params": Json::empty_object(),
    }
    let transport = BoundaryMockTransport::new([request])
    let server = McpServer::new(registry~, transport~)
    let f = McpServer::serve(server)
    f(())
    assert_eq(transport.listened, true)
    assert_eq(transport.sent.length(), 1)
    json_inspect(transport.sent[0], content={
      "jsonrpc": "2.0",
      "id": 7,
      "result": Json::empty_object(),
    })
  })
}

///|
/// 行为契约：serve 对未知方法请求的单次循环 → sent 记录 error 占位响应。
/// 验证 serve 与 handle_request 默认分支的集成。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/server_serve_unknown_method_records_error_response" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let request : Json = {
      "jsonrpc": "2.0",
      "id": 9,
      "method": "notifications/initialized",
      "params": Json::empty_object(),
    }
    let transport = BoundaryMockTransport::new([request])
    let server = McpServer::new(registry~, transport~)
    let f = McpServer::serve(server)
    f(())
    assert_eq(transport.sent.length(), 1)
    json_inspect(transport.sent[0], content={
      "jsonrpc": "2.0",
      "id": 9,
      "error": { "code": -32601, "message": "method not found" },
    })
  })
}
