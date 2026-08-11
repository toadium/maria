# cmd/main/interactive

Maria 交互式 REPL 模式 — 解析参数、加载模型、创建/恢复会话、实时打印助手消息。

## Overview

- `interactive(args)`：交互模式入口
- 支持 `--prompt`/`--model`/`--web-search`/`--log-file`/`--resume` 参数
- 使用 `@readline` 从 stdin 读取用户输入
- 实时打印助手消息与工具调用

## Usage

```mbt nocheck
///|
// CLI: maria --model gpt-4o --prompt "Hello"
@interactive.interactive(["--model", "gpt-4o", "--prompt", "Hello"])
```

## API Reference

```mbt nocheck
///|
pub async fn interactive(args : ArrayView[String]) -> Unit
```

## Integration

- 被 `@cmd/main` 作为默认子命令
- 依赖 `maria` 核心包创建 `Maria` 实例
- 依赖 `@internal/readline` 提供终端行编辑
- 依赖 `@cmd/main/argument` 抛出 `InvalidArgument`