# internal/conversation

Conversation management — history, context pruning, and ReMe memory extension.

## Overview

- `Conversation`: message history with role-tagged entries
- `Manager`: session-scoped conversation persistence
- `Pruner`: context window management with token budget enforcement
- `ReMeIndex` trait: ReMe memory system extension point (P2 预留)

## Message Types

```mbt nocheck
///|
pub(all) enum Role {
  User
  Assistant
  Tool
  System
}

///|
pub(all) struct Message {
  role : Role
  content : String
  tool_calls : Array[ToolCall]
  tool_call_id : String?
}
```

## ReMe Memory (P2 Extension)

The `ReMeIndex` trait is a P2 extension point for integrating ReMe (Retrieval-augmented Memory) with the conversation system:

```mbt nocheck
///|
pub(open) trait ReMeIndex {
  fn index(self : Self, message : Message) -> async (Unit) -> Unit
  fn retrieve(self : Self, query : String, k~ : Int = 5) -> async (Unit) -> Array[Message]
  fn clear(self : Self) -> Unit
}
```

When no `ReMeIndex` is registered, the conversation system operates in standard mode (full history + context pruning). When a `ReMeIndex` is registered, relevant messages are retrieved from the index before each LLM request.