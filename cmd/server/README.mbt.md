# cmd/server

Maria HTTP 服务器 — 承载 Maria 会话的 HTTP 服务，支持守护进程注册与 SSE 消息流。

## Overview

- `Server`：服务器实例，管理会话与 HTTP 路由
- `RegisterInfo` / `RegisterRequest` / `RegisterResponse`：守护进程注册协议
- `CreateMessageRequest` / `CreateMessageResponse`：消息创建 API
- `ServerStreamEvent`：SSE 流事件（MariaQueuedMessagesSynchronized / Maria）
- `start(args)`：CLI 入口（`maria server`）

## Usage

```mbt nocheck
///|
// CLI: maria server --model gpt-4o --port 8080
@server.start(["--model", "gpt-4o", "--port", "8080"])

// 编程式启动
let server = @server.Server::new(
  serve~="0.0.0.0",
  port~=8080,
  model?="gpt-4o",
)
server.start()
```

## API Reference

```mbt nocheck
///|
pub fn Server::new(
  name? : String,
  model? : String,
  register? : RegisterInfo,
  serve~ : String,
  port~ : Int,
  home? : String,
  cwd? : String,
  web_search? : Bool,
  resume_id? : @uuid.Uuid,
  max_sessions? : Int,
) -> Server raise

///|
pub fn Server::port(self : Server) -> Int
pub fn Server::shutdown(self : Server) -> Unit
pub async fn Server::start(self : Server) -> Unit

///|
pub(all) enum ServerStreamEvent {
  MariaQueuedMessagesSynchronized(Array[@agent.QueuedMessage])
  Maria(@event.Event)
}

///|
pub async fn start(args : ArrayView[String]) -> Unit
```

## Integration

- 被 `@cmd/main` 作为 `server` 子命令
- 被 `@cmd/daemon` 复用 HTTP 服务能力
- 依赖 `@service`、`@agent`、`@event` 提供会话管理
- SSE 流通过 `@httpx.FromEvent` / `@httpx.ToEvent` 序列化