///|
pub struct Session {
  session_id : SessionId
  agent : @agent.Agent
  broadcast : @broadcast.Broadcast[@event.Event]
  mut task : @async.Task[Unit]?
  created_at : @clock.Timestamp
  mut last_active : @clock.Timestamp
}

///|
fn Session::new(
  session_id~ : SessionId,
  agent~ : @agent.Agent,
  broadcast~ : @broadcast.Broadcast[@event.Event],
  created_at~ : @clock.Timestamp,
) -> Session {
  Session::{
    session_id,
    agent,
    broadcast,
    task: None,
    created_at,
    last_active: created_at,
  }
}

///|
pub fn Session::id(self : Session) -> SessionId {
  self.session_id
}

///|
pub fn Session::agent_id(self : Session) -> @agentid.AgentId {
  self.agent.agent_id()
}

///|
pub fn Session::is_busy(self : Session) -> Bool {
  self.task is Some(_)
}

///|
pub fn Session::close(self : Session) -> Unit {
  self.agent.close()
}
