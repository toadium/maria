# internal/signal

POSIX 信号常量 — 提供 SIGKILL、SIGTERM、SIGTSTP 数值。

## Overview

- `sigkill`：SIGKILL 信号值（强制终止）
- `sigterm`：SIGTERM 信号值（优雅终止）
- `sigtstp`：SIGTSTP 信号值（终端停止，Ctrl+Z）

## API Reference

```mbt nocheck
///|
pub let sigkill : Int
pub let sigterm : Int
pub let sigtstp : Int
```

## Integration

- 被 `@cmd/daemon` 用于进程信号处理
- 被 `@internal/fsx` 用于文件操作信号
- 被 `@internal/readline` 用于处理 Ctrl+Z 挂起