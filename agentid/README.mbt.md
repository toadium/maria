# agentid

Agent identity value object — a `UUID`-backed newtype for uniquely identifying agent instances across traces, sessions, and service endpoints.

## Overview

- `AgentId` wraps `@uuid.Uuid` as a newtype, providing `Eq` / `Hash` / `Debug` / `ToJson` / `FromJson` / `Show`
- Generate new IDs via `AgentId::new(source : @uuid.Source)` (e.g. `@rand.chacha8()`)
- Convert to/from raw UUID: `to_uuid()` / `from_uuid()`
- Nil sentinel: `AgentId::nil()` / `is_nil()`

## Usage

```mbt nocheck
///|
let id = @agentid.AgentId::new(@rand.chacha8())
inspect(id.is_nil(), content="false")
inspect(id.to_string().length(), content="36")
```

## API Reference

```mbt nocheck
///|
pub type AgentId @uuid.Uuid

///|
pub fn AgentId::new(source : @uuid.Source) -> AgentId

///|
pub fn AgentId::nil() -> AgentId

///|
pub fn AgentId::is_nil(self : AgentId) -> Bool

///|
pub fn AgentId::to_uuid(self : AgentId) -> @uuid.Uuid

///|
pub fn AgentId::from_uuid(uuid : @uuid.Uuid) -> AgentId

///|
pub fn AgentId::to_string(self : AgentId) -> String
```