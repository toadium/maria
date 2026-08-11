# internal/rand

密码学随机数生成 — 基于系统熵源，提供随机字节与 ChaCha8 生成器。

## Overview

- `bytes(n)`：生成 n 个密码学安全随机字节
- `chacha8()`：创建 ChaCha8 随机数生成器（`@random.Rand`）

## Usage

```mbt nocheck
///|
let random_bytes = @rand.bytes(32)
let rng = @rand.chacha8()
let n = rng.uint64()
```

## API Reference

```mbt nocheck
///|
pub fn bytes(n : Int) -> Bytes raise @errno.Errno

///|
pub fn chacha8() -> @random.Rand raise @errno.Errno
```

## Integration

- 被全仓库 11+ 个包使用
- 被 `@internal/uuid` 用于 UUID v4 生成
- 被 `@agentid`、`@trace`、`@event` 用于生成唯一标识
- 被 `@service`、`@oauth` 用于生成安全 token
- 依赖系统熵源（/dev/urandom 或等效），失败时抛出 `@errno.Errno`