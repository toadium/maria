# internal/abort

立即中止程序执行 — 以错误消息终止并返回任意类型。

## Overview

- `abort(message)`：打印错误消息并立即退出程序，返回任意类型 `T`（永不正常返回）

## Usage

```mbt nocheck
///|
let config = match load_config() {
  Some(c) => c
  None => @abort.abort("Failed to load configuration")
}
```

## API Reference

```mbt nocheck
///|
pub fn[T] abort(message : String) -> T
```

## Integration

- 被 `@cmd/main`、`@cmd/test`、`@cmd/jsonl2md` 用于致命错误退出
- 被 `@sdk` 用于不可恢复错误
- 泛型返回类型 `T` 使其可在任何期望值的上下文中使用