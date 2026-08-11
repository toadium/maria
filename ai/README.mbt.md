# ai

AI message types — abstraction over LLM message formats.

## Overview

- `Message`: unified message type (role + content + tool calls)
- `Role`: `User` / `Assistant` / `Tool` / `System`
- `ToolCall`: function call request from LLM
- `Usage`: token usage tracking (prompt / completion / total)

## API

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

///|
pub(all) struct Usage {
  prompt_tokens : Int
  completion_tokens : Int
  total_tokens : Int
}
```