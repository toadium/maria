///|
pub suberror SessionError {
  SessionNotFound(SessionId)
  ConcurrentLimit
  SessionAlreadyExists(SessionId)
} derive(ToJson, Debug)

///|
pub impl Show for SessionError with fn output(
  self : SessionError,
  logger : &Logger,
) -> Unit {
  match self {
    SessionNotFound(id) => {
      logger.write_string("SessionNotFound: ")
      logger.write_string(id.to_string())
    }
    ConcurrentLimit => logger.write_string("ConcurrentLimit")
    SessionAlreadyExists(id) => {
      logger.write_string("SessionAlreadyExists: ")
      logger.write_string(id.to_string())
    }
  }
}

///|
pub(all) struct CreateRequest {
  name : String?
  system_message : String?
  web_search : Bool?
  resume_id : @uuid.Uuid?
  cwd : String?
  home : String?
  model : String?
} derive(ToJson, FromJson)

///|
pub(all) enum CreateResult {
  Success(SessionId, @agentid.AgentId)
  LimitExceeded
  Failed(String)
} derive(ToJson, FromJson)

///|
pub(all) struct SessionInfo {
  id : SessionId
  agent_id : @agentid.AgentId
  busy : Bool
  created_at : @clock.Timestamp
  last_active : @clock.Timestamp
} derive(ToJson, FromJson)

///|
pub(all) enum SessionCommand {
  Create(CreateRequest, @aqueue.Queue[CreateResult])
  Send(SessionId, @ai.Message, Bool, @aqueue.Queue[@uuid.Uuid?])
  Close(SessionId, @aqueue.Queue[Bool])
  Cancel(SessionId, @aqueue.Queue[Bool])
  List(@aqueue.Queue[Array[SessionInfo]])
  Get(SessionId, @aqueue.Queue[SessionInfo?])
  GetBroadcast(SessionId, @aqueue.Queue[@broadcast.Broadcast[@event.Event]?])
  Shutdown
}
