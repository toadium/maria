# cmd/main

Maria 主可执行入口 — 解析子命令并分发到对应子模块。

## Overview

独立可执行程序（`pkgtype: executable`），无对外导出 API。

子命令分发：
- `maria conversations` → `@conversation.list()`
- `maria conversation <uuid>` → `@conversation.show(rest)`
- `maria server [opts]` → `@server.start(rest)`
- `maria daemon [opts]` → `@daemon.start(rest)`
- `maria exec [opts]` → `@exec.exec(rest)`
- `maria version` → 打印 `@buildinfo.version`
- 其余 → `@interactive.interactive(rest)`（默认交互模式）

## Integration

- 顶层 CLI 入口，无被依赖
- 依赖 `@cmd/main/conversation`、`@cmd/main/interactive`、`@cmd/main/exec`
- 依赖 `@cmd/server`、`@cmd/daemon`
- 依赖 `@internal/buildinfo` 输出版本号