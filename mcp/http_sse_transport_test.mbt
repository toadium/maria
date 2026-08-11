///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_construct" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport1 = HttpSseTransport::new()
    let _ = transport1
    let transport2 = HttpSseTransport::new(
      host="0.0.0.0",
      port=9000,
      endpoint="/api/mcp",
    )
    let _ = transport2
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_trait_object_storable" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new()
    let server_transport : &McpServerTransport = transport
    let listen_fn = McpServerTransport::listen(server_transport)
    listen_fn(())
    let receive_fn = McpServerTransport::receive(server_transport)
    let received = receive_fn(())
    json_inspect(received, content=Json::empty_object())
    let response : Json = {
      "jsonrpc": "2.0",
      "id": 1,
      "result": Json::empty_object(),
    }
    let send_fn = McpServerTransport::send(server_transport, response)
    send_fn(())
    McpServerTransport::close(server_transport)
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_listen_returns_async_fn" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new()
    let listen_fn = McpServerTransport::listen(transport)
    listen_fn(())
    let listen_fn2 = McpServerTransport::listen(transport)
    listen_fn2(())
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_receive_returns_empty_object" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new()
    let receive_fn = McpServerTransport::receive(transport)
    let received = receive_fn(())
    json_inspect(received, content=Json::empty_object())
    let receive_fn2 = McpServerTransport::receive(transport)
    let received2 = receive_fn2(())
    json_inspect(received2, content=Json::empty_object())
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/http_sse_transport_close_sets_closed_flag" (t : @test.Test) {
  @mock.run(t, _ => {
    let transport = HttpSseTransport::new()
    McpServerTransport::close(transport)
    McpServerTransport::close(transport)
    let receive_fn = McpServerTransport::receive(transport)
    let received = receive_fn(())
    json_inspect(received, content=Json::empty_object())
    ()
  })
}
