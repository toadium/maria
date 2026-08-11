# internal/openrouter

OpenRouter 模型目录 API — 查询可用模型列表与定价信息。

## Overview

- `Model`：完整模型描述（id、上下文长度、架构、定价、支持的参数）
- `Architecture`：输入/输出模态、tokenizer、instruct 类型
- `Pricing`：prompt/completion/request/image/web_search 等多维度定价
- `TopProvider`：顶层 provider 的上下文长度与审核状态
- `get_models(api_key~)`：异步获取全部模型列表
- `get_models_count(api_key~)`：异步获取模型总数

## Usage

```mbt nocheck
///|
let models = @openrouter.get_models(api_key="sk-or-...")
for model in models {
  println("\{model.id}: context=\{model.context_length}")
}
let count = @openrouter.get_models_count(api_key="sk-or-...")
inspect(count)
```

## API Reference

```mbt nocheck
///|
pub struct Model {
  id : String
  canonical_slug : String
  name : String
  created : Int64
  description : String
  context_length : Int
  architecture : Architecture
  pricing : Pricing
  top_provider : TopProvider
  per_request_limits : Json?
  supported_parameters : Array[String]
} derive(ToJson)

///|
pub struct Architecture {
  input_modalities : Array[String]
  output_modalities : Array[String]
  tokenizer : String
  instruct_type : String?
} derive(ToJson)

///|
pub struct Pricing {
  prompt : String
  completion : String
  request : String?
  image : String?
  web_search : String?
  internal_reasoning : String?
  input_cache_read : String?
  input_cache_write : String?
} derive(ToJson)

///|
pub async fn get_models(api_key~ : StringView) -> Array[Model]

///|
pub async fn get_models_count(api_key~ : StringView) -> Int
```

## Integration

- 从 `https://openrouter.ai/api/v1/models` 端点获取数据
- `Model` 实现 `ToJson` + `FromJson`，可序列化缓存到本地
- 用于模型选择与定价比较场景