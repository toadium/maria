# cmd/main/argument

共享参数错误类型 — 为 `cmd/main` 子命令提供统一的 `InvalidArgument` 异常。

## Overview

- `InvalidArgument`：参数错误子异常，携带错误描述字符串

## API Reference

```mbt nocheck
///|
pub(all) suberror InvalidArgument {
  InvalidArgument(String)
} derive(ToJson, Debug)
```

## Integration

- 被 `@cmd/main/interactive`、`@cmd/main/exec`、`@cmd/main/conversation` 共同使用
- 无业务依赖，仅依赖 `core/debug`