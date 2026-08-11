# service

Agent-as-a-Service — multi-session management with concurrent session limits.

## Overview

- `SessionManager`: manages agent sessions, supports concurrent session limits
- `Session`: holds agent state, lifecycle (create / run / close)
- `SessionId`: UUID-backed session identifier
- `SessionCommand`: command enum (Create / Send / Close / List)
- `SessionError`: error types (SessionNotFound / ConcurrentLimit / SessionAlreadyExists)
- `IdleReaper`: idle session timeout and automatic reaping skeleton (P2 预留)

## Usage

```mbt nocheck
///|
let manager = @service.SessionManager::new(config, logger)
let session_id = manager.create_session(agent_id)
manager.send_message(session_id, "Hello")
let sessions = manager.list_sessions()
manager.close_session(session_id)
```

## SessionManager

```mbt nocheck
///|
pub struct SessionManager {
  config : SessionManagerConfig
  sessions : Map[SessionId, Session]
  session_queue : @deque.Deque[SessionId]
  uuid : @uuid.Generator
  logger : @pino.Logger
  clock : @clock.Clock
  mut shutdown : Bool
}
```

## SessionInfo

```mbt nocheck
///|
pub(all) struct SessionInfo {
  id : SessionId
  agent_id : @agentid.AgentId
  busy : Bool
  created_at : @clock.Timestamp
  last_active : @clock.Timestamp
}
```

## P2 Extension: IdleReaper

- `IdleReaperConfig`: `idle_timeout_ms` (default 30min) + `reap_interval_ms` (default 60s)
- `IdleReaper`: periodic scan → `last_active + idle_timeout_ms < now` → `close_session(id)`