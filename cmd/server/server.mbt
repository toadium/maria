///|
/// Multi-session HTTP runtime container that binds a SessionManager with an HTTP
/// server and the broadcast machinery needed to expose the API surface
/// described in `README.md`.
struct Server {
  session_manager : @service.SessionManager
  config : @service.SessionManagerConfig
  mut default_session_id : @service.SessionId?
  resume_id : @uuid.Uuid?
  name : String?
  register : RegisterInfo?
  serve : String
  port : Int
  http_server : @httpx.Server
}

///|
pub fn Server::port(self : Server) -> Int {
  self.port
}

///|
/// Constructs a Server with a SessionManager. The default session is not
/// pre-created here because `SessionManager::run` has not started yet; it is
/// created in `Server::start` after the run loop is spawned.
pub fn Server::new(
  name? : String,
  model? : String,
  register? : RegisterInfo,
  serve~ : String,
  port~ : Int,
  home? : String,
  cwd? : String,
  web_search? : Bool = false,
  resume_id? : @uuid.Uuid,
  max_sessions? : Int,
) -> Server raise {
  let home = match home {
    Some(h) => h
    None => @os.home()
  }
  let cwd = cwd.unwrap_or(@os.cwd())
  let model = model.unwrap_or("")
  let config = @service.SessionManagerConfig::new(
    cwd~,
    home~,
    model~,
    max_sessions?,
    default_web_search=web_search,
  )
  let session_manager = @service.SessionManager::new(config~)
  let http_server = @httpx.Server::new("[::]", port, reuse_addr=true)
  let port = http_server.port()
  Server::{
    session_manager,
    config,
    default_session_id: None,
    resume_id,
    name,
    register,
    serve,
    port,
    http_server,
  }
}

///|
/// Central HTTP router that handles static files, REST endpoints, and SSE
/// streams behind the necessary CORS wrapper.
async fn Server::serve_http(self : Server) -> Unit {
  let router = @httpx.Router::new()
  // Multi-session endpoints
  router.add_handler(Post, "/v1/sessions", (r, w) => {
    self.create_session_handler(r, w)
  })
  router.add_handler(Get, "/v1/sessions", (_, w) => {
    self.list_sessions_handler(w)
  })
  router.add_handler(Get, "/v1/sessions/{id}", (r, w) => {
    self.get_session_handler(r, w)
  })
  router.add_handler(Delete, "/v1/sessions/{id}", (r, w) => {
    self.close_session_handler(r, w)
  })
  router.add_handler(Get, "/v1/sessions/{id}/events", (r, w) => {
    self.get_session_events(r, w)
  })
  router.add_handler(Post, "/v1/sessions/{id}/message", (r, w) => {
    self.send_session_message(r, w)
  })
  // Legacy endpoints (default session aliases, except GET /v1/status which is
  // now a global multi-session status)
  router.add_handler(Get, "/v1/status", (_, w) => self.get_status(w))
  router.add_handler(Post, "/v1/cancel", (_, w) => self.cancel_maria(w))
  router.add_handler(Get, "/v1/queued-messages", (_, w) => {
    self.get_queued_messages(w)
  })
  router.add_handler(Get, "/v1/events", (_, w) => self.get_events(w))
  router.add_handler(Post, "/v1/external-event/cancel", (_, w) => {
    self.send_cancellation_event(w)
  })
  router.add_handler(Get, "/v1/tools", (_, w) => self.get_tools(w))
  router.add_handler(Get, "/v1/system-prompt", (_, w) => {
    self.get_system_prompt(w)
  })
  router.add_handler(Post, "/v1/message", (r, w) => self.create_message(r, w))
  router.add_handler(Post, "/v1/external-event", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.send_external_event(r.read_json(), w)
  })
  router.add_handler(Post, "/v1/external-event/user-message", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.send_user_message_event(r.read_json(), w)
  })
  router.add_handler(Post, "/v1/enabled-tools", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.set_enabled_tools(r.read_json(), w)
  })
  router.add_handler(Post, "/v1/system-prompt", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.set_system_prompt(r.read_json(), w)
  })
  // Graceful shutdown endpoint (registered last to avoid path match conflicts)
  router.add_handler(Post, "/v1/shutdown", (_req, w) => {
    w.send_json(code=200, { "success": true })
    self.shutdown()
  })
  let file_server = @httpx.FileServer::new(self.serve)
  router.set_not_found_handler((r, w) => file_server.handle(r, w))
  self.http_server.serve(@httpx.cors(router.handler()))
}

///|
async fn @httpx.ResponseWriter::send_json(
  self : Self,
  code~ : Int,
  json : Json,
) -> Unit {
  self.header().set("Content-Type", "application/json")
  self.write_header(code)
  self.write(json.stringify())
}

///|
/// Cancels the running agent (if any) and returns the pending queue back to
/// the client so UIs can decide what to do next.
async fn Server::cancel_maria(self : Server, w : @httpx.ResponseWriter) -> Unit {
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      let pms = a.clear_inputs()
      let _ = self.session_manager.cancel_session(session_id)
      let pms_json : Array[Json] = pms.map(m => {
        "id": m.id,
        "message": m.message.to_openai(),
      })
      w.send_json(code=200, {
        "success": true,
        "pending_messages": pms_json.to_json(),
      })
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Runs the HTTP server alongside the background SessionManager worker until
/// the process is cancelled.
pub async fn Server::start(self : Server) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.session_manager.run(), allow_failure=true)
    defer self.session_manager.shutdown()
    let req : @service.CreateRequest = @service.CreateRequest::{
      resume_id: self.resume_id,
      name: self.name,
      system_message: None,
      web_search: None,
      cwd: None,
      home: None,
      model: None,
    }
    match self.session_manager.create_session(req) {
      Success(session_id, agent_id) => {
        self.default_session_id = Some(session_id)
        if self.register is Some(register) {
          let agent = self.session_manager.get_session_agent(session_id)
          match agent {
            Some(a) =>
              register.register(
                port=self.port,
                new_id=agent_id.to_uuid(),
                web_search=a.web_search,
                cwd=a.cwd,
                model=a.model.name,
              )
              |> ignore()
            None => ()
          }
        } else {
          logger.warn(
            "No register information provided; skipping registration.",
          )
          let pid = @spawn.getpid()
          logger.info("Listening on port \{self.port}", data={ "pid": pid })
          logger.info(
            "Visit http://localhost:\{self.port}/ to access the server.",
            data={ "pid": pid },
          )
        }
      }
      LimitExceeded =>
        fail("Failed to create default session: concurrent limit exceeded")
      Failed(msg) => fail("Failed to create default session: \{msg}")
    }
    self.serve_http()
  })
}

///|
pub fn Server::shutdown(self : Server) -> Unit {
  self.session_manager.shutdown()
  self.http_server.close()
}

///|
pub(all) enum ServerStreamEvent {
  MariaQueuedMessagesSynchronized(Array[@agent.QueuedMessage])
  Maria(@event.Event)
}

///|
pub impl @httpx.FromEvent for ServerStreamEvent with fn from_event(
  event : @httpx.Event,
) -> ServerStreamEvent raise {
  let { event, data } = event
  let data = @json.parse(data)
  match event {
    Some("maria.queued_messages.synchronized") =>
      ServerStreamEvent::MariaQueuedMessagesSynchronized(@json.from_json(data))
    Some("maria") => ServerStreamEvent::Maria(@json.from_json(data))
    _ => fail("unrecognized event type: " + @debug.to_string(event))
  }
}

///|
pub impl @httpx.ToEvent for ServerStreamEvent with fn to_event(
  self : ServerStreamEvent,
) -> @httpx.Event {
  match self {
    ServerStreamEvent::MariaQueuedMessagesSynchronized(queued_messages) =>
      @httpx.Event::new(
        event="maria.queued_messages.synchronized",
        data=queued_messages.to_json().stringify(),
      )
    ServerStreamEvent::Maria(event) =>
      @httpx.Event::new(event="maria", data=event.to_json().stringify())
  }
}

///|
/// Streams Maria lifecycle events plus queue synchronization messages over
/// Server-Sent Events for the default session.
async fn Server::get_events(self : Server, w : @httpx.ResponseWriter) -> Unit {
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let broadcast = self.session_manager.get_session_broadcast(session_id)
  match broadcast {
    Some(b) => {
      let agent = self.session_manager.get_session_agent(session_id)
      match agent {
        Some(a) => {
          let w = @httpx.EventStreamWriter::new(w)
          w.write_header(200)
          w.write(MariaQueuedMessagesSynchronized(a.queued_messages()))
          b.listen_forever(event => {
            if event.desc is (TokenCounted(_) | ContextPruned(_)) {
              return
            }
            w.write(Maria(event))
            if event.desc is (MessageQueued(_) | MessageUnqueued(_)) {
              w.write(MariaQueuedMessagesSynchronized(a.queued_messages()))
            }
          })
        }
        None => w.send_json(code=404, { "error": "Session not found" })
      }
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Returns the queued messages as JSON without keeping the connection open.
async fn Server::get_queued_messages(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      let queued_messages : Array[Json] = a
        .queued_messages()
        .map(m => { "id": m.id, "message": m.message.to_openai() })
      w.send_json(code=200, queued_messages.to_json())
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Lists the registered tools and whether each one is currently enabled.
async fn Server::get_tools(self : Server, w : @httpx.ResponseWriter) -> Unit {
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      let tools = a.tools()
      let tools_json : Map[String, Json] = Map([])
      for name, tool in tools {
        tools_json[name] = { "enabled": tool.enabled() }
      }
      w.send_json(code=200, Json::object(tools_json))
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Returns the current system prompt (or `null` when none is configured).
async fn Server::get_system_prompt(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      let res : Json = match a.system_prompt() {
        Some(sys) => sys.to_json()
        None => Json::null()
      }
      w.send_json(code=200, res)
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Sends a generic external event to the agent.
///
/// Request body:
/// ```json
/// {
///   "type": "UserMessage" | "Cancelled" | "Diagnostics",
///   "message": "...",  // for UserMessage
///   "diagnostics": "..."  // JSONL string for Diagnostics
/// }
/// ```
async fn Server::send_external_event(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard json is { "type": String(event_type), .. } else {
    raise @httpx.JsonError::new(
      @status.BadRequest,
      "Missing 'type' field in request body",
    )
  }
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      let queue = a.external_events()
      match event_type {
        "Cancelled" => queue.send(@event.Cancelled)
        "UserMessage" => {
          guard json is { "message": String(message), .. } else {
            raise @httpx.JsonError::new(
              @status.BadRequest,
              "Missing 'message' field for UserMessage event",
            )
          }
          queue.send(UserMessage(message))
        }
        _ =>
          raise @httpx.JsonError::new(
            @status.BadRequest,
            "Unknown event type: \{event_type}. Expected 'UserMessage' or 'Cancelled'",
          )
      }
      w.send_json(code=200, { "success": true })
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Sends an immediate user message to the agent.
///
/// Request body:
/// ```json
/// {
///   "message": "Please stop and focus on this instead..."
/// }
/// ```
async fn Server::send_user_message_event(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard json is { "message": String(message), .. } else {
    raise @httpx.JsonError::new(
      @status.BadRequest,
      "Missing 'message' field in request body",
    )
  }
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      a.external_events().send(UserMessage(message))
      w.send_json(code=200, { "success": true })
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Sends a Cancelled event to the agent.
/// This will cause the agent to stop at the next poll point.
async fn Server::send_cancellation_event(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard self.default_session_id is Some(session_id) else {
    w.send_json(code=404, { "error": "Session not found" })
  }
  let agent = self.session_manager.get_session_agent(session_id)
  match agent {
    Some(a) => {
      a.external_events().send(Cancelled)
      w.send_json(code=200, { "success": true })
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// Multi-session global status endpoint.
async fn Server::get_status(self : Server, w : @httpx.ResponseWriter) -> Unit {
  let sessions = self.session_manager.list_sessions()
  let count = sessions.length()
  let max_sessions = self.config.max_sessions()
  let active = sessions.filter(s => s.busy).length()
  w.send_json(code=200, {
    "sessions": count,
    "max_sessions": max_sessions,
    "active": active,
  })
}

///|
/// POST /v1/sessions — creates a new session.
async fn Server::create_session_handler(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let r = @httpx.JsonRequestReader::new(r)
  let req : @service.CreateRequest = r.read()
  match self.session_manager.create_session(req) {
    Success(session_id, agent_id) =>
      w.send_json(code=200, {
        "session_id": session_id.to_string(),
        "agent_id": agent_id.to_string(),
      })
    LimitExceeded =>
      w.send_json(code=429, { "error": "Concurrent limit exceeded" })
    Failed(msg) => w.send_json(code=500, { "error": msg })
  }
}

///|
/// GET /v1/sessions — lists all sessions.
async fn Server::list_sessions_handler(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let sessions = self.session_manager.list_sessions()
  w.send_json(code=200, sessions.to_json())
}

///|
/// GET /v1/sessions/{id} — gets a single session's status.
async fn Server::get_session_handler(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let id_str = r.vars["id"]
  let session_id : @service.SessionId = @service.SessionId::from_uuid(
    @uuid.parse(id_str),
  ) catch {
    _ => {
      w.send_json(code=400, { "error": "Invalid session ID format" })
      return
    }
  }
  match self.session_manager.get_session(session_id) {
    Some(info) => w.send_json(code=200, info.to_json())
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// DELETE /v1/sessions/{id} — closes a session.
async fn Server::close_session_handler(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let id_str = r.vars["id"]
  let session_id : @service.SessionId = @service.SessionId::from_uuid(
    @uuid.parse(id_str),
  ) catch {
    _ => {
      w.send_json(code=400, { "error": "Invalid session ID format" })
      return
    }
  }
  try {
    let _ = self.session_manager.close_session(session_id)
    w.send_json(code=200, { "success": true })
  } catch {
    @service.SessionError::SessionNotFound(_) =>
      w.send_json(code=404, { "error": "Session not found" })
    error => raise error
  }
}

///|
/// GET /v1/sessions/{id}/events — SSE event stream for a session.
async fn Server::get_session_events(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let id_str = r.vars["id"]
  let session_id : @service.SessionId = @service.SessionId::from_uuid(
    @uuid.parse(id_str),
  ) catch {
    _ => {
      w.send_json(code=400, { "error": "Invalid session ID format" })
      return
    }
  }
  let broadcast = self.session_manager.get_session_broadcast(session_id)
  match broadcast {
    Some(b) => {
      let agent = self.session_manager.get_session_agent(session_id)
      match agent {
        Some(a) => {
          let w = @httpx.EventStreamWriter::new(w)
          w.write_header(200)
          w.write(MariaQueuedMessagesSynchronized(a.queued_messages()))
          b.listen_forever(event => {
            if event.desc is (TokenCounted(_) | ContextPruned(_)) {
              return
            }
            w.write(Maria(event))
            if event.desc is (MessageQueued(_) | MessageUnqueued(_)) {
              w.write(MariaQueuedMessagesSynchronized(a.queued_messages()))
            }
          })
        }
        None => w.send_json(code=404, { "error": "Session not found" })
      }
    }
    None => w.send_json(code=404, { "error": "Session not found" })
  }
}

///|
/// POST /v1/sessions/{id}/message — sends a message to a session.
async fn Server::send_session_message(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let id_str = r.vars["id"]
  let session_id : @service.SessionId = @service.SessionId::from_uuid(
    @uuid.parse(id_str),
  ) catch {
    _ => {
      w.send_json(code=400, { "error": "Invalid session ID format" })
      return
    }
  }
  let r = @httpx.JsonRequestReader::new(r)
  let request : CreateMessageRequest = r.read()
  try {
    let _ = self.session_manager.send_message(
      session_id,
      request.message,
      request.web_search.unwrap_or(self.config.default_web_search()),
    )
    w.send_json(code=200, { "success": true })
  } catch {
    @service.SessionError::SessionNotFound(_) =>
      w.send_json(code=404, { "error": "Session not found" })
    error => raise error
  }
}
