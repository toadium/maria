# internal/uuid

UUID v4 生成与解析 — 基于 128 位整数表示，支持 JSON 序列化。

## Overview

- `Uuid`：128 位值类型（hi + lo 两个 UInt64），derive(Eq, Compare, Hash)
- `Generator::v4()`：生成随机 UUID v4（版本 4 + RFC 9562 变体位）
- `parse(hex)`：从 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` 格式字符串解析
- `Uuid::to_string()`：输出标准带横线格式
- `Uuid::of_bytes()` / `Uuid::to_bytes()`：16 字节大端序转换
- `Uuid::variant()` / `Uuid::version()`：检查 UUID 变体与版本

## 常量

- `nil`：全零 UUID（`00000000-0000-0000-0000-000000000000`）
- `max`：全一 UUID（`ffffffff-ffff-ffff-ffff-ffffffffffff`）

## Usage

```mbt nocheck
///|
let gen = @uuid.generator(@random.new())
let id = gen.v4()
inspect(id.to_string(), content=
  "00000000-0000-0000-0000-000000000000"  // 实际为随机值
)

let parsed = @uuid.parse("550e8400-e29b-41d4-a716-446655440000")
inspect(parsed.variant(), content="RFC9562(V4)")

let bytes = id.to_bytes()
let id2 = @uuid.Uuid::of_bytes(bytes)
assert_eq(id, id2)
```

## API Reference

```mbt nocheck
///|
#valtype
struct Uuid derive(Eq, Compare, Hash)

///|
pub fn Generator::v4(self : Generator) -> Uuid

///|
pub fn parse(hex : StringView) -> Uuid raise ParseError

///|
pub fn Uuid::to_string(self : Uuid) -> String

///|
pub fn Uuid::to_bytes(self : Uuid) -> Bytes

///|
pub fn Uuid::of_bytes(bytes : Bytes) -> Uuid

///|
pub fn Uuid::variant(self : Uuid) -> Variant

///|
pub fn Uuid::version(self : Uuid) -> Version?

///|
pub impl ToJson for Uuid
pub impl @json.FromJson for Uuid
pub impl Show for Uuid
pub impl @debug.Debug for Uuid
```

## Integration

- 被 `@trace` 用作事件 ID 类型
- 被 `@conversation` 用作消息 ID
- 被 `@context_pruner` 用作修剪事件标识
- 实现 `ToJson` / `FromJson`，可直接用于 JSON 序列化场景
- `#valtype` 属性使其在值传递时无需装箱