# internal/context_pruner

上下文窗口修剪器 — 当 token 超出安全区预算时清除工具输出以释放空间。

## Overview

- `Pruner`：维护 logger、token_counter 和 safe_zone_tokens 预算
- `prune_messages(messages, tools)`：就地修剪消息数组，将工具响应替换为占位符
- `calculate_pruning(conversation, tools)`：计算需要修剪的事件 ID（不修改会话）
- `PruneResult`：包含 pruned_ids、origin_token_count、pruned_token_count

## 策略

仅清除工具响应消息（`Tool` 类型），因为：
1. 工具输出通常占最大 payload
2. 工具输出可按需重新生成
3. 保留原始 `tool_call_id` 以保持下游状态一致

被清除的工具消息替换为：
```
[Cleared: tool output. If you want to see the output, you can use the tool again.]
```

## Usage

```mbt nocheck
///|
let pruner = @context_pruner.Pruner::new(
  safe_zone_tokens~=8000,
  logger~=log,
)
let messages : Array[@openai.ChatCompletionMessageParam] = [
  @openai.user_message(content="List files"),
  @openai.assistant_message(content="", tool_calls=[@openai.tool_call(id="1", name="list_files")]),
  @openai.tool_message(content="file1\nfile2\nfile3\n...(very long)", tool_call_id="1"),
]
pruner.prune_messages(messages)
```

## API Reference

```mbt nocheck
///|
pub struct PruneResult {
  pruned_ids : Array[@uuid.Uuid]
  origin_token_count : Int
  pruned_token_count : Int
}

///|
pub fn Pruner::new(
  safe_zone_tokens~ : Int,
  logger~ : @pino.Logger,
) -> Pruner raise

///|
pub async fn Pruner::prune_messages(
  pruner : Pruner,
  messages : Array[@openai.ChatCompletionMessageParam],
  tools? : Array[@openai.ChatCompletionToolParam] = [],
) -> Unit

///|
pub async fn Pruner::calculate_pruning(
  pruner : Pruner,
  conversation : @conversation.Conversation,
  tools? : Array[@openai.ChatCompletionToolParam] = [],
) -> PruneResult
```

## Integration

- 依赖 `@token_counter` 进行 token 估算
- 依赖 `@conversation` 获取事件历史
- 依赖 `@openai` 消息类型
- 被 `@agent` 在每轮对话后调用以管理上下文窗口