# cmd/daemon

Maria 守护进程 — 后台常驻 HTTP 服务，管理任务生命周期与 OAuth 授权。

## Overview

- `Daemon`：守护进程实例，管理 HTTP 服务与任务
- `Task`：守护进程管理的任务（含 `is_idle` 状态查询）
- `start(args)`：CLI 入口（`maria daemon`），解析 `--port`/`--serve`/`--detach`
- `detach(...)`：分离出后台守护进程并返回 PID
- `lock_daemon_file(home~)`：锁定守护进程信息文件

## Usage

```mbt nocheck
///|
// CLI: maria daemon --port 8080 --detach
@daemon.start(["--port", "8080", "--detach"])

// 编程式启动
let daemon = @daemon.Daemon::new(
  exec_path~="/path/to/maria",
  port~=8080,
  serve~="0.0.0.0",
)
guard daemon is Some(d) else { fail("daemon already running") }
d.serve()
```

## API Reference

```mbt nocheck
///|
pub async fn Daemon::new(
  uuid? : @uuid.Generator,
  exec_path~ : String,
  port~ : Int,
  serve~ : String,
  cwd? : StringView,
  home? : StringView,
  lock? : Bool,
) -> Daemon?

///|
pub fn Daemon::port(self : Daemon) -> Int

///|
pub async fn Daemon::serve(self : Daemon) -> Unit

///|
pub fn Task::is_idle(self : Task) -> Bool

///|
pub async fn detach(exec_path? : String, port? : Int, serve? : StringView) -> Int

///|
pub async fn lock_daemon_file(home~ : StringView) -> @fs.File?

///|
pub async fn start(args : ArrayView[String]) -> Unit
```

## Integration

- 被 `@cmd/main` 作为 `daemon` 子命令分发
- 依赖 `@cmd/server` 提供 HTTP 服务能力
- 依赖 `@oauth/codex` 和 `@oauth/copilot` 处理授权
- 使用文件锁确保单实例运行