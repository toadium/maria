# Task Events

> 任务事件系统 — Agent 生命周期中通过 SSE 推送到 UI 的事件类型定义。

📚 **导航**：[docs/](.) · [HTTP 端点](http.md) · [核心类型](types.md) · [模型选择](model-selection.md)

---

## 概述

任务事件（Task Event）是 Agent 在会话生命周期中通过 SSE（Server-Sent Events）推送到 UI 的事件。每个事件携带一个 `msg` 鉴别字段和可选的负载数据，UI 根据事件类型渲染对话时间线。

## 类型定义

### TypeScript（UI 端）

[`ui/core/src/lib/types.ts`](../ui/core/src/lib/types.ts#L27)

```ts
type TaskEventBase = { id: number };

export type TaskEvent = TaskEventBase &
  | RequestCompletedEvent
  | PreToolCallEvent
  | PostToolCallEvent
  | MessageAddedEvent
  | PostConversationEvent
  | MessageUnqueuedEvent
  | TodoUpdatedEvent;
```

### MoonBit（Daemon 端）

[`event/event.mbt`](../event/event.mbt#L36)

```mbt
pub(all) enum OutgoingEvent {
  ModelLoaded(name~ : String, model~ : @model.Model)
  PreConversation
  PostConversation
  MessageAdded(@ai.Message)
  MessageUnqueued(id~ : @uuid.Uuid)
  MessageQueued(id~ : @uuid.Uuid, @ai.Message)
  ToolAdded(@tool.ToolDesc)
  PreToolCall(@ai.ToolCall)
  PostToolCall(@ai.ToolCall, result~ : Result[Json, Json], rendered~ : String)
  TokenCounted(Int)
  ContextPruned(origin_token_count~ : Int, pruned_token_count~ : Int)
  RequestCompleted(usage~ : @ai.Usage?, message~ : @ai.Message)
  ExternalEventReceived(ExternalEvent)
  Cancelled
  TodoUpdated(Json)
}
```

## JSON 编码

```jsonc
// All task events share a common "msg" discriminator and optional payload
// fields. The exact payload depends on the variant.
{
  "id": "550e8400-e29b-41d4-a716-446655440000", // randomly generated UUIDv4 per task
  "msg": "MessageAdded" | "RequestCompleted" | "PreToolCall" |
         "PostToolCall" | "PostConversation" | "MessageUnqueued" |
         "TodoUpdated",
  // ...variant-specific fields...
}
```

`id` 为随机生成的 UUIDv4，仅用于避免 UI 重复渲染同一事件。  
来源：[`cmd/server/server.mbt`](../cmd/server/server.mbt#L61)

## 事件变体一览

| 事件 | 说明 | 文档 |
|------|------|------|
| `MessageAdded` | 新消息追加到会话历史 | [→](events/MessageAdded.md) |
| `RequestCompleted` | LLM 补全完成，携带 assistant 回复 | [→](events/RequestCompleted.md) |
| `PostConversation` | 会话处理结束 | [→](events/PostConversation.md) |
| `PostToolCall` | 工具执行完成，携带结果 | [→](events/PostToolCall.md) |
| `PreToolCall` | 工具即将执行 | [→](events/PreToolCall.md) |
| `MessageUnqueued` | 排队消息被消费 | [→](events/MessageUnqueued.md) |
| `TodoUpdated` | TODO 列表更新 | [→](events/TodoUpdated.md) |
