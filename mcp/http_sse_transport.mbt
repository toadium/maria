///|
/// MCP HTTP/SSE 服务端传输（AgentScope 2.0 MCP Support HTTP/SSE 传输层扩展点预留）。
///
/// P2 预留：仅 struct 骨架 + trait 实现 skeleton + 构造函数 + 注释 + mock 测试，
/// 不实现具体 HTTP 服务监听/SSE 流写入/HTTP 请求解析逻辑（后续实现时添加）。
///
/// 参照 R20 McpServerTransport trait（服务端传输层抽象），HttpSseTransport 是其第一个具体传输实现（骨架）。
/// HTTP/SSE 模式：MCP 服务端通过 HTTP POST 接收请求，通过 SSE（Server-Sent Events）流式发送响应/通知。
///
/// 后续完整实现时需新增 `mcp/moon.pkg` 的 `moonbitlang/maria/internal/httpx` 依赖，
/// 复用 `internal/httpx/EventStreamWriter`（SSE 流写入）+ `internal/httpx/server`（HTTP 服务监听）等组件。
/// 本步不引入 internal/httpx 依赖以保持 P2 预留最小化（仅 String/Int/Bool/Json 基础类型）。
///
/// async trait 方法采用"返回 async 函数值的同步方法"模式（同 R13 McpTransport / R17 AgentRouter / R18 AgentTeam / R19 ReMeIndex / R20 McpServer 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。

///|
/// HTTP/SSE 服务端传输骨架，持有 HTTP 服务监听地址/端口/端点路径 + 幂等关闭守卫。
///
/// P2 预留：listen/send/receive/close 为骨架实现，不实际启动 HTTP 服务 / 写入 SSE 流 / 解析 HTTP 请求。
/// 后续完整实现时：(a) listen 内部启动 @httpx.Server 监听 host:port；(b) receive 内部从 HTTP POST 请求体解析 JSON-RPC 请求；
/// (c) send 内部通过 @httpx.EventStreamWriter 写入 SSE 事件流；(d) close 内部关闭 HTTP 服务。
pub struct HttpSseTransport {
  priv host : String
  priv port : Int
  priv endpoint : String
  priv mut closed : Bool
}

///|
/// 构造 HttpSseTransport，默认 host="127.0.0.1", port=8080, endpoint="/mcp"，closed 初始为 false。
pub fn HttpSseTransport::new(
  host? : String = "127.0.0.1",
  port? : Int = 8080,
  endpoint? : String = "/mcp",
) -> HttpSseTransport {
  HttpSseTransport::{ host, port, endpoint, closed: false }
}

///|
/// 监听客户端连接（骨架预留）。
///
/// P2 预留：返回 async 函数值，内部仅设 closed = false 占位，不实际启动 HTTP 服务。
/// 后续完整实现时启动 @httpx.Server 监听 host:port。
pub impl McpServerTransport for HttpSseTransport with fn listen(
  self : HttpSseTransport,
) -> async (Unit) -> Unit raise McpError {
  _ => self.closed = false
}

///|
/// 向客户端发送响应（骨架预留）。
///
/// P2 预留：返回 async 函数值，内部将 response.stringify() 占位，不实际写 SSE 流。
/// 后续完整实现时通过 @httpx.EventStreamWriter 写入 SSE 事件流。
pub impl McpServerTransport for HttpSseTransport with fn send(
  _ : HttpSseTransport,
  response : Json,
) -> async (Unit) -> Unit raise McpError {
  _ => {
    let _ = response.stringify()
  }
}

///|
/// 接收客户端请求（骨架预留）。
///
/// P2 预留：返回 async 函数值，内部返回 Json::empty_object() 占位，不实际读 HTTP 请求。
/// 后续完整实现时从 HTTP POST 请求体解析 JSON-RPC 2.0 请求。
pub impl McpServerTransport for HttpSseTransport with fn receive(
  _ : HttpSseTransport,
) -> async (Unit) -> Json raise McpError {
  _ => Json::empty_object()
}

///|
/// 关闭连接（幂等守卫）。
///
/// 同步方法，设 self.closed = true。
/// P2 预留：不实际关闭 HTTP 服务，仅设标志位。
/// 后续完整实现时在 if !self.closed 守卫内关闭 HTTP 服务 + 设 closed = true（参照 R12 InteractiveProcess::close 先例）。
pub impl McpServerTransport for HttpSseTransport with fn close(
  self : HttpSseTransport,
) -> Unit {
  self.closed = true
}
