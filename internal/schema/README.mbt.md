# internal/schema

JSON Schema 构建与验证 — 支持 object/array/string/integer/enum 类型。

## Overview

- `Schema`：不透明类型，支持 `ToJson` 序列化
- `object(...)` / `array(...)` / `string()` / `integer()` / `enums(...)`：Schema 构造器
- `Schema::verify(json)`：验证 JSON 值是否符合 schema

## Usage

```mbt nocheck
///|
let person_schema = @schema.object({
  "name": @schema.string(),
  "age": @schema.integer(),
}, required=["name", "age"])
let valid = person_schema.verify(Json::object({
  "name": "Alice".to_json(),
  "age": 30.to_json(),
}))
assert_true(valid)
```

## API Reference

```mbt nocheck
///|
pub fn object(
  properties : Map[String, Schema],
  additional_properties? : Bool,
  required? : Array[String],
) -> Schema

///|
pub fn array(items : Schema) -> Schema

///|
pub fn string() -> Schema

///|
pub fn integer() -> Schema

///|
pub fn enums(values : Array[Json]) -> Schema

///|
pub fn Schema::to_json(self : Schema) -> Map[String, Json]

///|
pub fn Schema::verify(self : Schema, value : Json) -> Bool
```

## Integration

- 被 `@openai` 用于结构化输出的 schema 构建
- 配合 `@openai.Structural` trait 实现类型安全 JSON 提取
- `json_schema(name~, schema~)` 将 Schema 转为 ResponseFormat