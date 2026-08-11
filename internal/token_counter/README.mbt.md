# internal/token_counter

Token 计数器 — 基于 tiktoken cl100k_base 编码，支持消息/工具/参数级计数与校准。

## Overview

- `Counter`：封装 tiktoken encoding、logger 和校准因子表
- `count_string(text)`：单字符串 token 计数（含系统开销）
- `count_message(message)`：单条消息计数（递归处理 content parts 与 tool_calls）
- `count_param(messages, tools)`：完整请求参数计数（含 system/tools overhead）
- `calibrate(model_name, estimated, actual)`：基于实际用量 EMA 校准
- `apply_calibration(model_name, raw_count)`：应用校准因子

## 常量

- `SystemOverhead = 7`
- `ToolsOverhead = 320`
- `ToolOverhead = 20`
- `DefaultCalibrationAlpha = 0.3`

## Usage

```mbt nocheck
///|
let counter = @token_counter.Counter::new(logger~=log)
let tokens = counter.count_string("Hello, world!")
let msg_tokens = counter.count_message(
  @openai.user_message(content="What is 2+2?"),
)
let total = counter.count_param(
  messages=[@openai.user_message(content="Hi")],
  tools=[@openai.tool(name="calc", description="Calculator", parameters=Json::empty_object())],
)

// 校准：模型报告实际用了 120 tokens，我们估算 100
counter.calibrate(model_name="gpt-4o", estimated_tokens=100, actual_tokens=120)
let calibrated = counter.apply_calibration(model_name="gpt-4o", raw_count=200)
```

## API Reference

```mbt nocheck
///|
pub fn Counter::new(
  logger~ : @pino.Logger,
  calibration_alpha? : Double = 0.3,
) -> Counter raise

///|
pub fn Counter::count_string(self : Counter, text : String) -> Int

///|
pub fn Counter::count_message(
  self : Counter,
  message : @openai.ChatCompletionMessageParam,
) -> Int

///|
pub async fn Counter::count_param(
  self : Counter,
  messages~ : Array[@openai.ChatCompletionMessageParam],
  tools? : Array[@openai.ChatCompletionToolParam] = [],
) -> Int

///|
pub fn Counter::calibrate(
  self : Counter,
  model_name~ : String,
  estimated_tokens~ : Int,
  actual_tokens~ : Int,
) -> Unit

///|
pub fn Counter::apply_calibration(
  self : Counter,
  model_name~ : String,
  raw_count~ : Int,
) -> Int
```

## Integration

- 依赖 `@tiktoken` 的 `cl100k_base` 编码
- 被 `@context_pruner` 用于判断是否需要修剪
- 被 `@agent` 用于在请求前后记录 token 用量并触发校准
- 校准因子限制在 [0.5, 2.0] 范围内防止漂移