///|
/// MCP 协议客户端，持有传输层引用，实现 JSON-RPC 2.0 握手/枚举工具/调用工具。
pub struct McpClient {
  priv transport : &McpTransport
  priv mut next_id : Int
}

///|
pub fn McpClient::new(transport : &McpTransport) -> McpClient {
  McpClient::{ transport, next_id: 0 }
}

///|
pub async fn McpClient::initialize(self : McpClient) -> Unit raise McpError {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let request : Json = {
    "jsonrpc": "2.0",
    "id": id,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": Json::empty_object(),
      "clientInfo": { "name": "maria", "version": "0.1.0" },
    },
  }
  try {
    let send_fn = McpTransport::send(self.transport, request)
    send_fn(())
    let recv_fn = McpTransport::receive(self.transport)
    let response = recv_fn(())
    guard response is Json::Object(object) else {
      raise HandshakeFailed("response is not an object")
    }
    match object.get("jsonrpc") {
      Some(String(v)) =>
        if v != "2.0" {
          raise HandshakeFailed("unsupported jsonrpc version: " + v)
        }
      None => raise HandshakeFailed("missing jsonrpc field")
      Some(_) => raise HandshakeFailed("jsonrpc is not a string")
    }
    match object.get("id") {
      Some(Number(n, ..)) =>
        if n.to_int() != id {
          raise HandshakeFailed("response id mismatch")
        }
      None => raise HandshakeFailed("missing id field")
      Some(_) => raise HandshakeFailed("id is not a number")
    }
    match object.get("result") {
      Some(_) => ()
      None =>
        match object.get("error") {
          Some(err) => {
            guard err is Json::Object(err_obj) else {
              raise HandshakeFailed(
                "response has error: error is not an object",
              )
            }
            let code = match err_obj.get("code") {
              Some(Number(n, ..)) => n.to_int().to_string()
              _ => "unknown"
            }
            let message = match err_obj.get("message") {
              Some(String(m)) => m
              _ => "unknown"
            }
            raise HandshakeFailed("response has error: " + code + " " + message)
          }
          None => raise HandshakeFailed("response has neither result nor error")
        }
    }
  } catch {
    _ => raise HandshakeFailed("initialize failed")
  }
}

///|
pub async fn McpClient::list_tools(
  self : McpClient,
) -> Array[McpTool] raise McpError {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let request : Json = {
    "jsonrpc": "2.0",
    "id": id,
    "method": "tools/list",
    "params": Json::empty_object(),
  }
  try {
    let send_fn = McpTransport::send(self.transport, request)
    send_fn(())
    let recv_fn = McpTransport::receive(self.transport)
    let response = recv_fn(())
    guard response is Json::Object(object) else {
      raise ProtocolError("response is not an object")
    }
    match object.get("jsonrpc") {
      Some(String(v)) =>
        if v != "2.0" {
          raise ProtocolError("unsupported jsonrpc version: " + v)
        }
      None => raise ProtocolError("missing jsonrpc field")
      Some(_) => raise ProtocolError("jsonrpc is not a string")
    }
    match object.get("id") {
      Some(Number(n, ..)) =>
        if n.to_int() != id {
          raise ProtocolError("response id mismatch")
        }
      None => raise ProtocolError("missing id field")
      Some(_) => raise ProtocolError("id is not a number")
    }
    let result = match object.get("result") {
      Some(r) => r
      None =>
        match object.get("error") {
          Some(err) => {
            guard err is Json::Object(err_obj) else {
              raise ProtocolError("response has error: error is not an object")
            }
            let code = match err_obj.get("code") {
              Some(Number(n, ..)) => n.to_int().to_string()
              _ => "unknown"
            }
            let message = match err_obj.get("message") {
              Some(String(m)) => m
              _ => "unknown"
            }
            raise ProtocolError("response has error: " + code + " " + message)
          }
          None => raise ProtocolError("response has neither result nor error")
        }
    }
    guard result is Json::Object(result_obj) else {
      raise ProtocolError("result is not an object")
    }
    let tools_arr = match result_obj.get("tools") {
      Some(Array(arr)) => arr
      None => raise ProtocolError("missing tools field in result")
      Some(_) => raise ProtocolError("tools is not an array")
    }
    tools_arr.map(tool => {
      guard tool is Json::Object(tool_obj) else {
        raise ProtocolError("tool is not an object")
      }
      let name = match tool_obj.get("name") {
        Some(String(n)) => n
        None => raise ProtocolError("missing tool name")
        Some(_) => raise ProtocolError("missing tool name")
      }
      let description = match tool_obj.get("description") {
        Some(String(d)) => d
        Some(Null) | None => ""
        Some(_) => ""
      }
      let input_schema = match tool_obj.get("inputSchema") {
        Some(s) => @tool.JsonSchema::from_json(s)
        None => raise ProtocolError("missing tool inputSchema")
      }
      let call_fn : async (Json) -> @tool.ToolResult noraise = args => {
        self.call_tool(name, args)
      }
      McpTool::{ name, description, input_schema, call_fn }
    })
  } catch {
    _ => raise ProtocolError("tools/list failed")
  }
}

///|
pub async fn McpClient::call_tool(
  self : McpClient,
  name : String,
  args : Json,
) -> @tool.ToolResult noraise {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let request : Json = {
    "jsonrpc": "2.0",
    "id": id,
    "method": "tools/call",
    "params": { "name": name, "arguments": args },
  }
  try {
    let send_fn = McpTransport::send(self.transport, request)
    send_fn(())
    let recv_fn = McpTransport::receive(self.transport)
    let response = recv_fn(())
    guard response is Json::Object(object) else {
      raise ProtocolError("response is not an object")
    }
    match object.get("jsonrpc") {
      Some(String(v)) =>
        if v != "2.0" {
          raise ProtocolError("unsupported jsonrpc version: " + v)
        }
      None => raise ProtocolError("missing jsonrpc field")
      Some(_) => raise ProtocolError("jsonrpc is not a string")
    }
    match object.get("id") {
      Some(Number(n, ..)) =>
        if n.to_int() != id {
          raise ProtocolError("response id mismatch")
        }
      None => raise ProtocolError("missing id field")
      Some(_) => raise ProtocolError("id is not a number")
    }
    match object.get("result") {
      Some(result) => @tool.ToolResult::success(result)
      None =>
        match object.get("error") {
          Some(err) => {
            guard err is Json::Object(err_obj) else {
              raise ProtocolError("response has error: error is not an object")
            }
            let code = match err_obj.get("code") {
              Some(Number(n, ..)) => n.to_int().to_string()
              _ => "unknown"
            }
            let message = match err_obj.get("message") {
              Some(String(m)) => m
              _ => "unknown"
            }
            @tool.ToolResult::failed("mcp error: " + code + " " + message)
          }
          None => raise ProtocolError("response has neither result nor error")
        }
    }
  } catch {
    _ => @tool.ToolResult::failed("mcp call failed")
  }
}

///|
pub fn McpClient::close(self : McpClient) -> Unit {
  McpTransport::close(self.transport)
}
