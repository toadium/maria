# cmd/main/conversation

会话管理子命令 — 列出与展示已保存的 Maria 会话。

## Overview

- `list()`：列出所有本地会话（编号 + UUID + 摘要）
- `show(args)`：展示指定会话，支持 `--output <file>.md` 导出为 Markdown

## Usage

```mbt nocheck
///|
// CLI: maria conversations
@conversation.list()

// CLI: maria conversation <uuid> --output export.md
@conversation.show(["<uuid>", "--output", "export.md"])
```

## API Reference

```mbt nocheck
///|
pub async fn list() -> Unit

///|
pub async fn show(args : ArrayView[String]) -> Unit
```

## Integration

- 被 `@cmd/main` 作为 `conversations` 与 `conversation` 子命令
- 依赖 `@internal/conversation` 加载会话数据
- 依赖 `@cmd/main/argument` 抛出 `InvalidArgument`