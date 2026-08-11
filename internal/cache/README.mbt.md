# internal/cache

OpenAI 消息参数缓存处理 — 对消息数组进行去重/转换。

## Overview

- `cache_messages(messages)`：处理消息数组，返回缓存优化后的版本

## Usage

```mbt nocheck
///|
let messages : ArrayView[@openai.ChatCompletionMessageParam] = [
  @openai.user_message(content="Hello"),
  @openai.assistant_message(content="Hi there"),
]
let cached = @cache.cache_messages(messages)
```

## API Reference

```mbt nocheck
///|
pub fn cache_messages(
  messages : ArrayView[@openai.ChatCompletionMessageParam],
) -> Array[@openai.ChatCompletionMessageParam]
```

## Integration

- 被 `@agent` 用于在发送请求前优化消息缓存
- 配合 OpenAI 的 prompt caching 功能减少重复 token 计费