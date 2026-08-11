///|
/// MCP 服务端骨架（AgentScope 2.0 MCP Support 服务端侧扩展点预留）。
///
/// P2 预留：仅 trait 定义 + struct 骨架 + 构造函数 + handle_request/serve 方法骨架 + 注释 + mock 测试，
/// 不实现具体传输逻辑（R21 HttpSseTransport 后续添加）、不实现具体请求处理逻辑（R22 工具缓存动态变更后续添加）、
/// 不定义 StdioServerTransport/HttpSseServerTransport 等具体传输实现（后续实现时再添加）。
///
/// 参考 AgentScope 2.0 MCP Support，将 maria 工具集以 MCP server 形式暴露，
/// 使外部 MCP 客户端可调用 maria 工具，扩展工具生态互操作性。
/// ComponentRegistry 作为工具集来源，maria 工具集经注册后以 MCP server 形式暴露。
///
/// async trait 方法采用"返回 async 函数值的同步方法"模式（同 R13 McpTransport / R17 AgentRouter / R18 AgentTeam / R19 ReMeIndex 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。

///|
/// MCP 服务端传输层抽象（扩展点预留）。
///
/// 服务端侧传输契约，参照 McpTransport（客户端侧）先例，
/// 增加 listen 方法（监听客户端连接），send/receive/close 语义同 McpTransport。
/// 后续可实现具体传输（R21 HttpSseTransport / StdioServerTransport）。
pub(open) trait McpServerTransport {
  fn listen(Self) -> async (Unit) -> Unit raise McpError
  fn send(Self, Json) -> async (Unit) -> Unit raise McpError
  fn receive(Self) -> async (Unit) -> Json raise McpError
  fn close(Self) -> Unit
}

///|
/// MCP 服务端骨架，持有工具集来源（ComponentRegistry）+ 传输层引用 + 自增请求 ID 计数器。
///
/// P2 预留：handle_request/serve 为骨架实现，不实际调用 registry 工具。
/// 后续可实现具体请求处理逻辑（R22 工具缓存动态变更）。
#warnings("-unused_field")
pub struct McpServer {
  priv registry : @component.ComponentRegistry
  priv transport : &McpServerTransport
  priv mut next_id : Int
}

///|
pub fn McpServer::new(
  registry~ : @component.ComponentRegistry,
  transport~ : &McpServerTransport,
) -> McpServer {
  McpServer::{ registry, transport, next_id: 0 }
}

///|
/// 处理 JSON-RPC 2.0 请求（骨架预留）。
///
/// P2 预留：match method 字段三具名分支 + 默认分支，
/// initialize/tools/list/tools/call 三分支返回 result 占位响应（Json::empty_object()），
/// 默认分支返回 error 占位响应（code: -32601, message: "method not found"，符合 JSON-RPC 2.0 协议惯例），
/// 不实际调用 registry 工具。
pub fn McpServer::handle_request(self : McpServer, request : Json) -> Json {
  let _ = self
  let request_id : Json = match request {
    Json::Object(obj) =>
      match obj.get("id") {
        Some(v) =>
          match v {
            Number(_, ..) => v
            _ => 0
          }
        _ => 0
      }
    _ => 0
  }
  match request {
    Json::Object(obj) =>
      match obj.get("method") {
        Some(String("initialize")) => {
          let response : Json = {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": Json::empty_object(),
          }
          response
        }
        Some(String("tools/list")) => {
          let response : Json = {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": Json::empty_object(),
          }
          response
        }
        Some(String("tools/call")) => {
          let response : Json = {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": Json::empty_object(),
          }
          response
        }
        _ => {
          let response : Json = {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": { "code": -32601, "message": "method not found" },
          }
          response
        }
      }
    _ => {
      let response : Json = {
        "jsonrpc": "2.0",
        "id": request_id,
        "error": { "code": -32601, "message": "method not found" },
      }
      response
    }
  }
}

///|
/// 服务端事件循环（骨架预留）。
///
/// P2 预留：返回 async 函数值，内部单次 listen → receive → handle_request → send（避免测试死锁），
/// 不实现具体事件循环逻辑（后续 R21/R22 添加完整实现，改为 loop 结构）。
pub fn McpServer::serve(
  self : McpServer,
) -> async (Unit) -> Unit raise McpError {
  _ => {
    let listen_fn = McpServerTransport::listen(self.transport)
    listen_fn(())
    let receive_fn = McpServerTransport::receive(self.transport)
    let request = receive_fn(())
    let response = self.handle_request(request)
    let send_fn = McpServerTransport::send(self.transport, response)
    send_fn(())
  }
}
