# internal/openai

OpenAI Chat Completion API 类型定义与客户端 — 涵盖请求/响应/流式消息的完整数据模型。

## Overview

- **请求构造**：`chat_completion(...)` 构建 `Request`，`chat(model~, Request)` 发起异步调用
- **消息类型**：`ChatCompletionMessageParam`（System/User/Assistant/Tool 四种变体）
- **工具调用**：`ChatCompletionToolParam`、`ChatCompletionMessageToolCall`、`ChatCompletionToolChoice`
- **流式响应**：`ChatCompletionChunk` 系列类型支持 SSE 流式解析
- **结构化输出**：`json_schema(...)` + `ResponseFormat` + `Structural` trait 实现类型安全 JSON 提取
- **便捷函数**：`text(model~, prompt~)` / `json(model~, prompt~)` / `data(model~, prompt~)` 一行完成常见调用

## Usage

```mbt nocheck
///|
let model = @model.openai("gpt-4o", api_key="sk-...")
let messages = [
  @openai.system_message(content="You are a helpful assistant."),
  @openai.user_message(content="What is 2+2?"),
]
let request = @openai.chat_completion(
  model="gpt-4o",
  messages~,
)
let completion = @openai.chat(model~, request)
guard completion.choices[0].message.content is Some(text) else {
  fail("no content")
}
inspect(text)
```

### 结构化输出

```mbt nocheck
///|
struct Weather : @openai.Structural {
  city : String
  temperature : Double
} derive(ToJson)

///|
let result : Weather = @openai.data(model~, prompt="Get weather for Beijing")
```

## API Reference

### 核心函数

```mbt nocheck
///|
pub fn chat_completion(
  model~ : String,
  messages~ : Array[ChatCompletionMessageParam],
  tools? : Array[ChatCompletionToolParam],
  temperature? : Double,
  max_tokens? : Int,
  response_format? : ResponseFormat,
  stream? : Bool,
  tool_choice? : ChatCompletionToolChoice,
) -> Request

///|
pub async fn chat(
  model~ : @model.Model,
  request : Request,
  logger? : @pino.Logger,
) -> ChatCompletion

///|
pub async fn text(model~ : @model.Model, prompt~ : String) -> String

///|
pub async fn json(model~ : @model.Model, prompt~ : String) -> Json

///|
pub async fn[T : Structural] data(model~ : @model.Model, prompt~ : String) -> T
```

### 消息构造

```mbt nocheck
///|
pub fn system_message(content~ : String) -> ChatCompletionMessageParam
pub fn user_message(content~ : String) -> ChatCompletionMessageParam
pub fn assistant_message(content~ : String, tool_calls? : Array[ChatCompletionMessageToolCall]) -> ChatCompletionMessageParam
pub fn tool_message(content~ : String, tool_call_id~ : String) -> ChatCompletionMessageParam
```

### 工具定义

```mbt nocheck
///|
pub fn tool(
  name~ : String,
  description~ : String,
  parameters~ : Json,
  strict? : Bool,
) -> ChatCompletionToolParam

///|
pub fn tool_call(id~ : String, name~ : String, arguments? : String) -> ChatCompletionMessageToolCall
```

## Integration

- 被 `@ai` 包用作 LLM 调用的底层传输层
- 被 `@token_counter` 用于消息 token 计数
- 被 `@context_pruner` 用于上下文窗口管理
- `Structural` trait 配合 `@schema` 包实现结构化输出验证