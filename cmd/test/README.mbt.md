# cmd/test

测试用可执行程序 — 从文件读取提示词运行 Maria 会话并输出日志（测试夹具）。

## Overview

独立可执行程序（`pkgtype: executable`），无对外导出 API。

与 `cmd/main/exec` 类似，但定位为测试夹具，日志命名空间为 `maria_test`。

## CLI 参数

- `--prompt-file <path>`（必需）
- `--model <name>`（必需）
- `--log-file <path>`（默认 `logs.jsonl`）

## Integration

- 测试可执行程序，无被依赖
- 依赖 `maria` 核心包运行会话
- 依赖 `@internal/backtrace` 捕获异常堆栈