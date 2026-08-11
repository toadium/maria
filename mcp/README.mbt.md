# mcp

MCP (Model Context Protocol) support — client, server, and transport layers.

## Overview

- `McpClient`: JSON-RPC 2.0 client, connects to MCP servers via `McpTransport`
- `McpTransport` trait: `send` / `receive` / `close` (async methods)
- `StdioTransport`: stdio-based transport for subprocess MCP servers
- `McpTool`: wraps remote MCP tools as `@component.ToolComponent`
- `McpServer` + `McpServerTransport`: server-side skeleton (P2 预留)
- `HttpSseTransport`: HTTP/SSE transport skeleton (P2 预留)
- `ToolCacheWatcher` + `McpNotification`: tool cache dynamic change extension (P2 预留)

## Usage

```mbt nocheck
///|
let process = @spawn.spawn_interactive("mcp-server", [])
let transport = @mcp.StdioTransport::new(process)
let client = @mcp.McpClient::new(transport)
client.initialize()
let tools = client.list_tools()
for tool in tools {
  registry.register(tool)
}
```

## McpTransport Trait

```mbt nocheck
///|
pub(open) trait McpTransport {
  fn send(self : Self, request : Json) -> async (Unit) -> Unit raise McpError
  fn receive(self : Self) -> async (Unit) -> Json raise McpError
  fn close(self : Self) -> Unit
}
```

## McpError

```mbt nocheck
///|
pub suberror McpError {
  ConnectionFailed(String)
  HandshakeFailed(String)
  RequestTimeout(String)
  ProtocolError(String)
}
```

## P2 Extension Points

- `McpServerTransport` trait: `listen` / `send` / `receive` / `close` (server-side)
- `HttpSseTransport`: HTTP/SSE transport implementing `McpServerTransport`
- `ToolCacheWatcher` trait: `on_change(change : ToolCacheChange)` for cache invalidation
- `McpNotification`: JSON-RPC 2.0 notification skeleton (`method_` + `params`)