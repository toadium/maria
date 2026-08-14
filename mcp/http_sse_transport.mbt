///|
/// MCP HTTP/SSE 服务端传输（AgentScope 2.0 MCP Support HTTP/SSE 传输层实现）。
///
/// R21 实现：持有 @httpx.Server 实例 + EventStreamWriter，
/// listen 创建 HTTP 服务并绑定端口，close 关闭服务。
/// receive 从 pending_requests 队列读取请求（由 start_serving 的 POST handler 填充），
/// send 通过 EventStreamWriter 写入 SSE 事件流（由 start_serving 的 GET handler 设置）。
///
/// 参照 R20 McpServerTransport trait（服务端传输层抽象），HttpSseTransport 是其第一个具体传输实现。
/// HTTP/SSE 模式：MCP 服务端通过 HTTP POST 接收请求，通过 SSE（Server-Sent Events）流式发送响应/通知。
///
/// async trait 方法采用"返回 async 函数值的同步方法"模式（同 R13 McpTransport / R17 AgentRouter / R18 AgentTeam / R19 ReMeIndex / R20 McpServer 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。

///|
/// HTTP/SSE 服务端传输，持有 HTTP 服务 + SSE 写入器 + 请求队列 + 幂等关闭守卫。
///
/// R21 实现：
/// - listen: 创建 @httpx.Server 绑定 host:port，存入 server 字段
/// - receive: 从 pending_requests 队列弹出请求，队列空时返回 Json::empty_object()
/// - send: 通过 sse_writer 写入 SSE 事件流（若 active），否则 stringify 占位
/// - close: 关闭 server（若存在），设 closed = true
/// - start_serving: 启动 HTTP 服务，POST endpoint 读取 JSON-RPC 请求并入队，GET endpoint 设置 SSE 流
#warnings("-unused_field")
pub struct HttpSseTransport {
  priv host : String
  priv port : Int
  priv endpoint : String
  priv mut closed : Bool
  priv mut server : @httpx.Server?
  priv mut sse_writer : @httpx.EventStreamWriter?
  priv mut pending_requests : Array[Json]
}

///|
/// 构造 HttpSseTransport，默认 host="127.0.0.1", port=8080, endpoint="/mcp"，closed 初始为 false。
pub fn HttpSseTransport::new(
  host? : String = "127.0.0.1",
  port? : Int = 8080,
  endpoint? : String = "/mcp",
) -> HttpSseTransport {
  HttpSseTransport::{
    host,
    port,
    endpoint,
    closed: false,
    server: None,
    sse_writer: None,
    pending_requests: [],
  }
}

///|
/// 监听客户端连接。
///
/// R21 实现：创建 @httpx.Server 绑定 host:port，存入 server 字段，设 closed = false。
/// 若已有 server，先关闭旧 server 再创建新 server（防止资源泄漏）。
/// 不调用 Server::serve（会阻塞），使用 start_serving 启动请求处理。
pub impl McpServerTransport for HttpSseTransport with fn listen(
  self : HttpSseTransport,
) -> async (Unit) -> Unit raise McpError {
  _ => {
    let existing = self.server
    self.server = None
    match existing {
      Some(s) => s.close()
      None => ()
    }
    let server = @httpx::Server::new(self.host, self.port) catch {
      _ => raise ConnectionFailed("failed to bind \{self.host}:\{self.port}")
    }
    self.server = Some(server)
    self.closed = false
  }
}

///|
/// 向客户端发送响应。
///
/// R21 实现：若 sse_writer active，通过 write_event 写入 SSE 事件流（data 为 JSON stringify）。
/// 否则将 response stringify 占位（无 active SSE 连接）。
pub impl McpServerTransport for HttpSseTransport with fn send(
  self : HttpSseTransport,
  response : Json,
) -> async (Unit) -> Unit raise McpError {
  _ => {
    match self.sse_writer {
      Some(writer) => {
        let data = response.stringify()
        writer.write_event(event="message", data~)
      }
      None => {
        let _ = response.stringify()
      }
    }
  }
}

///|
/// 接收客户端请求。
///
/// R21 实现：从 pending_requests 队列弹出请求，队列空时返回 Json::empty_object()。
/// pending_requests 由 start_serving 的 POST handler 填充。
pub impl McpServerTransport for HttpSseTransport with fn receive(
  self : HttpSseTransport,
) -> async (Unit) -> Json raise McpError {
  _ => {
    match self.pending_requests.pop() {
      Some(request) => request
      None => Json::empty_object()
    }
  }
}

///|
/// 关闭连接（幂等守卫）。
///
/// R21 实现：关闭 server（若存在），清空 sse_writer，设 closed = true。
pub impl McpServerTransport for HttpSseTransport with fn close(
  self : HttpSseTransport,
) -> Unit {
  let server = self.server
  self.server = None
  self.sse_writer = None
  match server {
    Some(s) => s.close()
    None => ()
  }
  self.closed = true
}

///|
/// 启动 HTTP 服务，开始处理 POST 请求和 SSE 连接。
///
/// 调用前需先调用 listen 创建 server。此方法阻塞（调用 Server::serve）。
/// - POST endpoint: 读取 JSON-RPC 请求体，推入 pending_requests 队列供 receive 消费
/// - GET endpoint + "/sse": 设置 SSE 流写入器，保持连接直到 closed
pub async fn HttpSseTransport::start_serving(self : HttpSseTransport) -> Unit raise McpError {
  let server = self.server
  self.server = None
  match server {
    Some(s) => {
      let router = @httpx::Router::new()
      let post_handler : @httpx::Handler = @httpx::Handler((r, w) => {
        let json_reader = @httpx::JsonRequestReader::new(r)
        let request = json_reader.read_json()
        self.pending_requests.push(request)
        w.write_header(200)
      })
      router.add_handler(@httpx::Method::Post, self.endpoint, post_handler)
      let sse_endpoint = self.endpoint + "/sse"
      let sse_handler : @httpx::Handler = @httpx::Handler((_, w) => {
        let sse_writer = @httpx::EventStreamWriter::new(w)
        sse_writer.write_header(200)
        self.sse_writer = Some(sse_writer)
        for ;; {
          if self.closed {
            break
          }
          @async.sleep(100)
        }
      })
      router.add_handler(@httpx::Method::Get, sse_endpoint, sse_handler)
      s.serve(router.handler())
    }
    None => raise ConnectionFailed("server not started, call listen first")
  }
}
