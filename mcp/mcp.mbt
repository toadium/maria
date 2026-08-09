///|
/// MCP 通信错误类型，统一 transport 层错误。
pub suberror McpError {
  ConnectionFailed(String)
  HandshakeFailed(String)
  RequestTimeout(String)
  ProtocolError(String)
} derive(ToJson, Debug)

///|
pub impl Show for McpError with fn output(self : McpError, logger : &Logger) -> Unit {
  match self {
    ConnectionFailed(msg) => {
      logger.write_string("ConnectionFailed: ")
      logger.write_string(msg)
    }
    HandshakeFailed(msg) => {
      logger.write_string("HandshakeFailed: ")
      logger.write_string(msg)
    }
    RequestTimeout(msg) => {
      logger.write_string("RequestTimeout: ")
      logger.write_string(msg)
    }
    ProtocolError(msg) => {
      logger.write_string("ProtocolError: ")
      logger.write_string(msg)
    }
  }
}

///|
/// MCP 传输层抽象，定义 send/receive/close 契约。
pub(open) trait McpTransport {
  fn send(Self, Json) -> async (Unit) -> Unit raise McpError
  fn receive(Self) -> async (Unit) -> Json raise McpError
  fn close(Self) -> Unit
}

///|
/// 基于 stdio 的 MCP 传输实现，持有 InteractiveProcess 句柄通过 stdin/stdout 通信。
pub struct StdioTransport {
  priv process : @spawn.InteractiveProcess
}

///|
pub fn StdioTransport::new(
  process : @spawn.InteractiveProcess,
) -> StdioTransport {
  StdioTransport::{ process, }
}

///|
pub impl McpTransport for StdioTransport with fn send(
  self : StdioTransport,
  request : Json,
) -> async (Unit) -> Unit raise McpError {
  _ => {
    let line = request.stringify() + "\n"
    self.process.write(line) catch {
      _ => raise ConnectionFailed("write failed")
    }
  }
}

///|
pub impl McpTransport for StdioTransport with fn receive(self : StdioTransport) -> async (
  Unit,
) -> Json raise McpError {
  _ => {
    let line = self.process.read_line() catch {
      _ => raise ConnectionFailed("read failed")
    }
    match line {
      None => raise ConnectionFailed("EOF")
      Some(s) =>
        @json.parse(s) catch {
          _ => raise ProtocolError("json parse failed")
        }
    }
  }
}

///|
pub impl McpTransport for StdioTransport with fn close(self : StdioTransport) -> Unit {
  self.process.close()
}
