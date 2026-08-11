# internal/rules

AI 规则加载与管理 — 支持全局/本地来源，将规则内容应用到 AI 消息数组。

## Overview

- `Rule`：单条规则（description、globs、always_apply、content、source）
- `Source`：规则来源（Global 全局 / Local 本地）
- `Loader`：规则加载器，扫描指定路径并加载规则文件

## Usage

```mbt nocheck
///|
let loader = @rules.Loader::new("/path/to/rules", logger~=log)
loader.load()
let messages : Array[@ai.Message] = [@ai.user_message("Hello")]
loader.apply(messages)
```

## API Reference

```mbt nocheck
///|
pub struct Rule {
  description : String?
  globs : Array[String]
  always_apply : Bool
  content : String
  source : Source
} derive(ToJson, Debug)

///|
pub enum Source {
  Global
  Local
} derive(ToJson, Debug)

///|
pub fn Loader::new(path : String, logger~ : @pino.Logger) -> Loader

///|
pub async fn Loader::load(self : Loader) -> Unit

///|
pub fn Loader::apply(self : Loader, messages : Array[@ai.Message]) -> Unit
```

## Integration

- 被 `@agent` 用于在对话前注入系统规则
- 规则文件使用 YAML frontmatter 格式（通过 `@yamd` 解析）
- `always_apply=true` 的规则始终注入；其余按 glob 匹配文件路径