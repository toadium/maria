///|
/// R21 HttpSseTransport 边界条件验证测试（Verifier 编写）。
/// 补充 http_sse_transport_test.mbt 未覆盖的边界条件：
/// - 构造函数部分参数自定义（默认与自定义混合）
/// - send 不同类型 JSON 响应（非空对象/数组/字符串/数字/空对象）
/// - listen → close → listen 循环（closed 守卫重置）
/// - close 后所有 trait 方法仍可调用（占位实现不检查守卫）
/// - receive 返回值类型为 Json Object（stringify 为 "{}"）
/// - HttpSseTransport 与 McpServer 协作（serve 调用不抛异常）
/// 基于 detail_v21.md 行为契约：

///|
/// 行为契约：部分参数自定义，其余使用默认值（host="127.0.0.1", port=8080, endpoint="/mcp"）。
/// 验证 labeled argument with default 可省略任意参数。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_construct_partial_custom_args" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    // 只自定义 host
    let transport_host = HttpSseTransport::new(host="0.0.0.0")
    let _ = transport_host
    // 只自定义 port
    let transport_port = HttpSseTransport::new(port=9000)
    let _ = transport_port
    // 只自定义 endpoint
    let transport_endpoint = HttpSseTransport::new(endpoint="/api/mcp")
    let _ = transport_endpoint
    // 自定义 host + port，endpoint 默认
    let transport_hp = HttpSseTransport::new(host="localhost", port=3000)
    let _ = transport_hp
    // 自定义 port + endpoint，host 默认
    let transport_pe = HttpSseTransport::new(port=443, endpoint="/v1/mcp")
    let _ = transport_pe
    ()
  })
}

///|
/// 行为契约：send 接受任意 Json 响应，占位实现仅 stringify，不抛异常。
/// 验证 send 对各种 JSON 类型的健壮性（JSON-RPC 2.0 响应/数组/字符串/数字/空对象）。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_send_various_json_responses" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new()
    let server_transport : &McpServerTransport = transport
    // 非空对象（JSON-RPC 2.0 响应）
    let obj_response : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": { "tools": [] },
    }
    let send_fn1 = McpServerTransport::send(server_transport, obj_response)
    send_fn1(())
    // 数组
    let arr_response : Json = [1, 2, 3]
    let send_fn2 = McpServerTransport::send(server_transport, arr_response)
    send_fn2(())
    // 字符串
    let str_response = Json::string("hello")
    let send_fn3 = McpServerTransport::send(server_transport, str_response)
    send_fn3(())
    // 数字
    let num_response = Json::number(42)
    let send_fn4 = McpServerTransport::send(server_transport, num_response)
    send_fn4(())
    // 空对象
    let empty_response = Json::empty_object()
    let send_fn5 = McpServerTransport::send(server_transport, empty_response)
    send_fn5(())
    ()
  })
}

///|
/// 行为契约：listen → close → listen 循环，listen 重置 closed = false。
/// 验证 closed 守卫可被 listen 重置，支持反复监听-关闭循环。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_listen_close_listen_cycle" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new(port=0)
    // 初始 listen（设 closed = false）
    let listen_fn1 = McpServerTransport::listen(transport)
    listen_fn1(())
    // close 设 closed = true
    McpServerTransport::close(transport)
    // 再次 listen，重置 closed = false
    let listen_fn2 = McpServerTransport::listen(transport)
    listen_fn2(())
    // 再次 close
    McpServerTransport::close(transport)
    // 第三次 listen + close，验证循环不抛异常
    let listen_fn3 = McpServerTransport::listen(transport)
    listen_fn3(())
    McpServerTransport::close(transport)
    ()
  })
}

///|
/// 行为契约：close 后所有 trait 方法仍可调用（占位实现不检查 closed 守卫）。
/// 验证 close 不锁定传输对象，listen/send/receive 在 close 后仍可执行。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_close_then_all_methods_callable" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new(port=0)
    McpServerTransport::close(transport)
    // close 后 listen（重置 closed = false）
    let listen_fn = McpServerTransport::listen(transport)
    listen_fn(())
    // close 后 send
    let response : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": Json::empty_object(),
    }
    let send_fn = McpServerTransport::send(transport, response)
    send_fn(())
    // close 后 receive
    let receive_fn = McpServerTransport::receive(transport)
    let received = receive_fn(())
    json_inspect(received, content=Json::empty_object())
    ()
  })
}

///|
/// 行为契约：receive 返回 Json Object 类型，stringify 为 "{}"。
/// 验证 receive 占位实现返回空对象（非数组/字符串/数字/null）。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_receive_returns_object_type" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new()
    let receive_fn = McpServerTransport::receive(transport)
    let received = receive_fn(())
    // 验证 stringify 为 "{}"（空对象，非数组 "[]" 或其他类型）
    assert_eq(received.stringify(), "{}")
    // 多次调用一致性
    let receive_fn2 = McpServerTransport::receive(transport)
    let received2 = receive_fn2(())
    assert_eq(received2.stringify(), "{}")
    assert_eq(received.stringify(), received2.stringify())
    ()
  })
}

///|
/// 行为契约：HttpSseTransport 与 McpServer 协作，serve 调用不抛异常。
/// 验证 HttpSseTransport 可作为 McpServer::new 的 transport~ 参数，
/// serve 内部 listen → receive → handle_request → send 链路完整执行。
/// receive 返回空对象 → handle_request 走默认分支（method 缺失）→ 返回 error 占位响应 → send stringify 占位。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_with_mcp_server_serve" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let transport = HttpSseTransport::new(port=0)
    let server = McpServer::new(registry~, transport~)
    // serve 调用：listen → receive → handle_request → send
    let serve_fn = McpServer::serve(server)
    serve_fn(())
    // 验证 serve 不抛异常（占位实现整体不产生实际 IO）
    ()
  })
}
