///|
pub struct SessionManagerConfig {
  max_sessions : Int
  cwd : String
  home : String
  model : String
  default_web_search : Bool
} derive(ToJson, FromJson)

///|
pub fn SessionManagerConfig::new(
  cwd~ : String,
  home~ : String,
  model~ : String,
  max_sessions? : Int = 16,
  default_web_search? : Bool = false,
) -> SessionManagerConfig {
  SessionManagerConfig::{ max_sessions, cwd, home, model, default_web_search }
}

///|
pub fn SessionManagerConfig::max_sessions(self : SessionManagerConfig) -> Int {
  self.max_sessions
}

///|
pub fn SessionManagerConfig::cwd(self : SessionManagerConfig) -> String {
  self.cwd
}

///|
pub fn SessionManagerConfig::home(self : SessionManagerConfig) -> String {
  self.home
}

///|
pub fn SessionManagerConfig::model(self : SessionManagerConfig) -> String {
  self.model
}

///|
pub fn SessionManagerConfig::default_web_search(
  self : SessionManagerConfig,
) -> Bool {
  self.default_web_search
}

///|
pub struct SessionManager {
  config : SessionManagerConfig
  sessions : Map[SessionId, Session]
  session_queue : @aqueue.Queue[SessionCommand]
  uuid : @uuid.Generator
  logger : @pino.Logger
  clock : &@clock.Clock
  mut shutdown : Bool
}

///|
pub fn SessionManager::new(
  config~ : SessionManagerConfig,
  uuid? : @uuid.Generator,
  logger? : @pino.Logger,
  clock? : &@clock.Clock,
) -> SessionManager raise {
  let uuid = match uuid {
    Some(u) => u
    None => @uuid.generator(@rand.chacha8())
  }
  let logger = match logger {
    Some(l) => l
    None => @pino.logger("maria", @pino.Transport::console())
  }
  let clock = match clock {
    Some(c) => c
    None => @clock.epoch
  }
  SessionManager::{
    config,
    sessions: Map([]),
    session_queue: @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded),
    uuid,
    logger,
    clock,
    shutdown: false,
  }
}

///|
pub async fn SessionManager::run(self : SessionManager) -> Unit {
  @async.with_task_group(group => {
    while !self.shutdown {
      let cmd = self.session_queue.get()
      match cmd {
        Create(req, reply_queue) => {
          if self.sessions.length() >= self.config.max_sessions {
            reply_queue.put(CreateResult::LimitExceeded)
            continue
          }
          let cwd = req.cwd.unwrap_or(self.config.cwd)
          let home = req.home.unwrap_or(self.config.home)
          let model_name = req.model.unwrap_or(self.config.model)
          let web_search = req.web_search.unwrap_or(
            self.config.default_web_search,
          )
          let model_opt : String? = if model_name.is_empty() {
            None
          } else {
            Some(model_name)
          }
          match @model.load(home~, cwd~, name?=model_opt) {
            None => {
              reply_queue.put(
                CreateResult::Failed("model not found: " + model_name),
              )
              continue
            }
            Some(model) => {
              let session_id = SessionId::from_uuid(self.uuid.v4())
              let agent_id = @agentid.AgentId::from_uuid(self.uuid.v4())
              let agent_result : @agent.Agent? = if req.resume_id
                is Some(resume_id) {
                let conv_manager = @conversation.Manager::new(
                  uuid=self.uuid,
                  home~,
                )
                match conv_manager.load(resume_id) {
                  Some(conv) =>
                    Some(
                      @agent.load(
                        model,
                        conv,
                        logger=self.logger,
                        home~,
                        web_search~,
                        agent_id~,
                      ),
                    )
                  None => {
                    reply_queue.put(
                      CreateResult::Failed(
                        "conversation not found: " + resume_id.to_string(),
                      ),
                    )
                    None
                  }
                }
              } else {
                Some(
                  match (req.name, req.system_message) {
                    (Some(n), Some(sm)) =>
                      @agent.new(
                        name=n,
                        model,
                        logger=self.logger,
                        cwd~,
                        home~,
                        web_search~,
                        agent_id~,
                        system_message=sm,
                      )
                    (Some(n), None) =>
                      @agent.new(
                        name=n,
                        model,
                        logger=self.logger,
                        cwd~,
                        home~,
                        web_search~,
                        agent_id~,
                      )
                    (None, Some(sm)) =>
                      @agent.new(
                        model,
                        logger=self.logger,
                        cwd~,
                        home~,
                        web_search~,
                        agent_id~,
                        system_message=sm,
                      )
                    (None, None) =>
                      @agent.new(
                        model,
                        logger=self.logger,
                        cwd~,
                        home~,
                        web_search~,
                        agent_id~,
                      )
                  },
                )
              }
              match agent_result {
                Some(agent) => {
                  let broadcast = @broadcast.Broadcast::new()
                  agent.add_listener((event : @event.Event) => {
                    broadcast.put(event)
                  })
                  let session = Session::new(
                    session_id~,
                    agent~,
                    broadcast~,
                    created_at=self.clock.now(),
                  )
                  self.sessions[session_id] = session
                  reply_queue.put(CreateResult::Success(session_id, agent_id))
                }
                None => continue
              }
            }
          }
        }
        Send(id, msg, web_search, reply_queue) =>
          match self.sessions.get(id) {
            Some(session) => {
              let msg_id = session.agent.queue_message(msg, web_search~)
              if session.task is None {
                let task = group.spawn(
                  () => {
                    session.agent.start() catch {
                      error =>
                        self.logger.error(
                          "session task failed: " + @debug.to_string(error),
                        )
                    }
                    defer (match self.sessions.get(id) {
                      Some(s) => {
                        s.task = None
                        self.sessions[id] = s
                      }
                      None => ()
                    })
                  },
                  allow_failure=true,
                )
                session.task = Some(task)
              }
              session.last_active = self.clock.now()
              self.sessions[id] = session
              reply_queue.put(Some(msg_id))
            }
            None => reply_queue.put(None)
          }
        Close(id, reply_queue) =>
          match self.sessions.get(id) {
            Some(session) => {
              session.close()
              if session.task is Some(task) {
                task.cancel()
              }
              self.sessions.remove(id)
              reply_queue.put(true)
            }
            None => reply_queue.put(false)
          }
        Cancel(id, reply_queue) =>
          match self.sessions.get(id) {
            Some(session) => {
              if session.task is Some(task) {
                task.cancel()
              }
              reply_queue.put(true)
            }
            None => reply_queue.put(false)
          }
        List(reply_queue) => {
          let infos = []
          for _, session in self.sessions {
            infos.push(SessionInfo::{
              id: session.id(),
              agent_id: session.agent_id(),
              busy: session.is_busy(),
              created_at: session.created_at,
              last_active: session.last_active,
            })
          }
          reply_queue.put(infos)
        }
        Get(id, reply_queue) =>
          match self.sessions.get(id) {
            Some(session) => {
              let info = SessionInfo::{
                id: session.id(),
                agent_id: session.agent_id(),
                busy: session.is_busy(),
                created_at: session.created_at,
                last_active: session.last_active,
              }
              reply_queue.put(Some(info))
            }
            None => reply_queue.put(None)
          }
        GetBroadcast(id, reply_queue) =>
          match self.sessions.get(id) {
            Some(session) => reply_queue.put(Some(session.broadcast))
            None => reply_queue.put(None)
          }
        Shutdown => self.shutdown = true
      }
    }
  })
}

///|
pub async fn SessionManager::create_session(
  self : SessionManager,
  req : CreateRequest,
) -> CreateResult {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(Create(req, reply_queue))
  reply_queue.get()
}

///|
pub async fn SessionManager::send_message(
  self : SessionManager,
  id : SessionId,
  msg : @ai.Message,
  web_search : Bool,
) -> @uuid.Uuid {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(Send(id, msg, web_search, reply_queue))
  match reply_queue.get() {
    Some(msg_id) => msg_id
    None => raise SessionError::SessionNotFound(id)
  }
}

///|
pub async fn SessionManager::close_session(
  self : SessionManager,
  id : SessionId,
) -> Bool {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(Close(id, reply_queue))
  let result = reply_queue.get()
  if result {
    true
  } else {
    raise SessionError::SessionNotFound(id)
  }
}

///|
pub async fn SessionManager::cancel_session(
  self : SessionManager,
  id : SessionId,
) -> Bool {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(Cancel(id, reply_queue))
  reply_queue.get()
}

///|
pub async fn SessionManager::list_sessions(
  self : SessionManager,
) -> Array[SessionInfo] {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(List(reply_queue))
  reply_queue.get()
}

///|
pub async fn SessionManager::get_session(
  self : SessionManager,
  id : SessionId,
) -> SessionInfo? {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(Get(id, reply_queue))
  reply_queue.get()
}

///|
pub async fn SessionManager::get_session_broadcast(
  self : SessionManager,
  id : SessionId,
) -> @broadcast.Broadcast[@event.Event]? {
  let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
  self.session_queue.put(GetBroadcast(id, reply_queue))
  reply_queue.get()
}

///|
pub fn SessionManager::shutdown(self : SessionManager) -> Unit {
  try self.session_queue.try_put(Shutdown) |> ignore catch {
    _ => ()
  }
}

///|
pub fn SessionManager::get_session_agent(
  self : SessionManager,
  id : SessionId,
) -> @agent.Agent? {
  match self.sessions.get(id) {
    Some(session) => Some(session.agent)
    None => None
  }
}

///|
pub fn SessionManager::command_queue(
  self : SessionManager,
) -> @aqueue.Queue[SessionCommand] {
  self.session_queue
}
