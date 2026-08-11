///|
test "service/session_id_new" {
  let id = SessionId::new(@rand.chacha8())
  inspect(id.is_nil(), content="false")
}

///|
test "service/session_id_to_uuid_from_uuid" {
  let id = SessionId::new(@rand.chacha8())
  inspect(SessionId::from_uuid(id.to_uuid()) == id, content="true")
  let u = @uuid.generator(@rand.chacha8()).v4()
  inspect(SessionId::from_uuid(u).to_uuid() == u, content="true")
  inspect(
    SessionId::from_uuid(@uuid.nil).to_uuid() == @uuid.nil,
    content="true",
  )
}

///|
test "service/session_id_to_string" {
  let id = SessionId::new(@rand.chacha8())
  inspect(id.to_string().length(), content="36")
  let fixed = SessionId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  inspect(fixed.to_string(), content="72212911-64d1-c441-e87d-de89b955ea34")
}

///|
#warnings("-deprecated")
test "service/session_id_to_json_from_json" {
  let id = SessionId::new(@rand.chacha8())
  let roundtripped : SessionId = @json.from_json(id.to_json())
  inspect(roundtripped == id, content="true")
  let fixed = SessionId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  inspect(fixed.to_json(), content="72212911-64d1-c441-e87d-de89b955ea34")
}

///|
test "service/session_id_nil" {
  inspect(@service.nil.is_nil(), content="true")
  inspect(@service.nil.to_uuid() == @uuid.nil, content="true")
  inspect(
    @service.nil.to_string(),
    content="00000000-0000-0000-0000-000000000000",
  )
}

///|
test "service/session_id_show" {
  let id = SessionId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  inspect(id, content="72212911-64d1-c441-e87d-de89b955ea34")
  let sb = StringBuilder()
  let logger : &Logger = sb
  Show::output(id, logger)
  inspect(sb.to_string(), content="72212911-64d1-c441-e87d-de89b955ea34")
}

///|
test "service/session_id_eq" {
  // 不等方向：nil 与非 nil 不等
  let id1 = SessionId::from_uuid(@uuid.nil)
  let id2 = SessionId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  inspect(id1 == id2, content="false")
  // 相等方向：同一 Uuid 构造的 SessionId 相等
  let u = @uuid.generator(@rand.chacha8()).v4()
  inspect(SessionId::from_uuid(u) == SessionId::from_uuid(u), content="true")
  inspect(
    SessionId::from_uuid(@uuid.nil) == SessionId::from_uuid(@uuid.nil),
    content="true",
  )
  // 边界条件：from_uuid(@uuid.nil) == @service.nil
  inspect(SessionId::from_uuid(@uuid.nil) == @service.nil, content="true")
}

///|
test "service/session_id_hash" {
  let u = @uuid.generator(@rand.chacha8()).v4()
  let id1 = SessionId::from_uuid(u)
  let id2 = SessionId::from_uuid(u)
  inspect(id1 == id2, content="true")
  inspect(id1.hash() == id2.hash(), content="true")
  // nil 的 hash 一致性
  inspect(
    SessionId::from_uuid(@uuid.nil).hash() == @service.nil.hash(),
    content="true",
  )
}

///|
test "service/session_id_from_json_error" {
  // 非 String 类型应 raise
  let non_string : Json = 42.0
  try {
    let _ : SessionId = @json.from_json(non_string)
    fail("expected from_json to raise on non-string")
  } catch {
    _ => ()
  }
  // 非法 UUID 字符串应 raise
  try {
    let _ : SessionId = @json.from_json("not-a-uuid")
    fail("expected from_json to raise on invalid uuid string")
  } catch {
    _ => ()
  }
}

///|
async test "service/session_error_show" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    // SessionNotFound Show 输出（通过 close_session 触发异常，suberror 变体构造器包私有）
    let nonexistent = SessionId::from_uuid(
      @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
    )
    try {
      let _ = manager.close_session(nonexistent)
      fail("expected SessionNotFound")
    } catch {
      SessionError::SessionNotFound(_) as error => {
        let sb = StringBuilder()
        let logger : &Logger = sb
        Show::output(error, logger)
        inspect(
          sb.to_string(),
          content="SessionNotFound: 72212911-64d1-c441-e87d-de89b955ea34",
        )
        // ToJson 序列化格式验证（r2 审查问题2 修订）
        json_inspect(error.to_json(), content=[
          "SessionNotFound", "72212911-64d1-c441-e87d-de89b955ea34",
        ])
      }
      _ => fail("expected SessionNotFound")
    }
    manager.shutdown()
  })
}

///|
test "service/create_request_to_json_from_json" {
  let req = CreateRequest::{
    name: Some("test-session"),
    system_message: Some("system prompt"),
    web_search: Some(true),
    resume_id: None,
    cwd: None,
    home: None,
    model: None,
  }
  let roundtripped : CreateRequest = @json.from_json(req.to_json())
  inspect(roundtripped.name == Some("test-session"), content="true")
  inspect(roundtripped.system_message == Some("system prompt"), content="true")
  inspect(roundtripped.web_search == Some(true), content="true")
  inspect(roundtripped.resume_id is None, content="true")
  inspect(roundtripped.cwd is None, content="true")
  inspect(roundtripped.home is None, content="true")
  inspect(roundtripped.model is None, content="true")
  // 全 None 默认构造往返
  let empty = CreateRequest::{
    name: None,
    system_message: None,
    web_search: None,
    resume_id: None,
    cwd: None,
    home: None,
    model: None,
  }
  let rt_empty : CreateRequest = @json.from_json(empty.to_json())
  inspect(rt_empty.name is None, content="true")
  inspect(rt_empty.web_search is None, content="true")
  // resume_id: Some(uuid) 序列化往返（r2 审查问题3 修订）
  let resume_uuid = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let req_with_resume = CreateRequest::{
    name: None,
    system_message: None,
    web_search: None,
    resume_id: Some(resume_uuid),
    cwd: None,
    home: None,
    model: None,
  }
  let rt_resume : CreateRequest = @json.from_json(req_with_resume.to_json())
  inspect(rt_resume.name is None, content="true")
  guard rt_resume.resume_id is Some(rt_uuid) else {
    fail("Expected Some(resume_uuid)")
  }
  inspect(rt_uuid == resume_uuid, content="true")
}

///|
test "service/create_result_to_json_from_json" {
  let session_id = SessionId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  let agent_id = @agentid.AgentId::from_uuid(
    @uuid.parse("12345678-1234-5678-1234-567812345678"),
  )
  // Success 往返
  let success = CreateResult::Success(session_id, agent_id)
  let rt_success : CreateResult = @json.from_json(success.to_json())
  guard rt_success is CreateResult::Success(rt_sid, rt_aid) else {
    fail("Expected Success")
  }
  inspect(rt_sid == session_id, content="true")
  inspect(rt_aid == agent_id, content="true")
  // LimitExceeded 往返
  let limit = CreateResult::LimitExceeded
  let rt_limit : CreateResult = @json.from_json(limit.to_json())
  inspect(rt_limit is CreateResult::LimitExceeded, content="true")
  // Failed 往返
  let failed = CreateResult::Failed("error message")
  let rt_failed : CreateResult = @json.from_json(failed.to_json())
  guard rt_failed is CreateResult::Failed(msg) else { fail("Expected Failed") }
  inspect(msg, content="error message")
}

///|
test "service/session_info_to_json_from_json" {
  let session_id = SessionId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  let agent_id = @agentid.AgentId::from_uuid(
    @uuid.parse("12345678-1234-5678-1234-567812345678"),
  )
  let info = SessionInfo::{
    id: session_id,
    agent_id,
    busy: true,
    created_at: @clock.Timestamp::from_ms(1000),
    last_active: @clock.Timestamp::from_ms(2000),
  }
  let roundtripped : SessionInfo = @json.from_json(info.to_json())
  inspect(roundtripped.id == session_id, content="true")
  inspect(roundtripped.agent_id == agent_id, content="true")
  inspect(roundtripped.busy, content="true")
  inspect(
    roundtripped.created_at == @clock.Timestamp::from_ms(1000),
    content="true",
  )
  inspect(
    roundtripped.last_active == @clock.Timestamp::from_ms(2000),
    content="true",
  )
}

///|
test "service/config_getters_and_defaults" {
  // 默认值：max_sessions=16, default_web_search=false
  let config = SessionManagerConfig::new(
    cwd="/tmp",
    home="/home",
    model="test-model",
  )
  inspect(config.max_sessions(), content="16")
  inspect(config.cwd(), content="/tmp")
  inspect(config.home(), content="/home")
  inspect(config.model(), content="test-model")
  inspect(config.default_web_search(), content="false")
  // 自定义值
  let config2 = SessionManagerConfig::new(
    cwd="/tmp",
    home="/home",
    model="test-model",
    max_sessions=8,
    default_web_search=true,
  )
  inspect(config2.max_sessions(), content="8")
  inspect(config2.default_web_search(), content="true")
}

///|
test "service/config_to_json_from_json" {
  let config = SessionManagerConfig::new(
    cwd="/tmp",
    home="/home",
    model="test-model",
    max_sessions=8,
    default_web_search=true,
  )
  let roundtripped : SessionManagerConfig = @json.from_json(config.to_json())
  inspect(roundtripped.max_sessions(), content="8")
  inspect(roundtripped.cwd(), content="/tmp")
  inspect(roundtripped.home(), content="/home")
  inspect(roundtripped.model(), content="test-model")
  inspect(roundtripped.default_web_search(), content="true")
}

///|
async test "service/manager_create_list_get_close" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    let infos = manager.list_sessions()
    inspect(infos.length(), content="1")
    let info_opt = manager.get_session(session_id)
    guard info_opt is Some(info) else { fail("Session not found") }
    inspect(info.id == session_id, content="true")
    let nonexistent = SessionId::from_uuid(mock.uuid.v4())
    inspect(manager.get_session(nonexistent) is None, content="true")
    let closed = manager.close_session(session_id)
    inspect(closed, content="true")
    inspect(manager.get_session(session_id) is None, content="true")
    // close_session 成功后 sessions.size() 递减 1（行为契约第 928 行，r1 审查问题5 修订）
    inspect(manager.list_sessions().length(), content="0")
    // close_session(不存在的 id) 抛 SessionError::SessionNotFound（设计第 1035 行）
    try {
      let _ = manager.close_session(nonexistent)
      fail("expected SessionNotFound")
    } catch {
      SessionError::SessionNotFound(_) => ()
      _ => fail("expected SessionNotFound")
    }
    manager.shutdown()
  })
}

///|
async test "service/manager_send_message" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    let msg = @ai.user_message(content="Hello")
    let sent = manager.send_message(session_id, msg, false)
    inspect(sent == @uuid.nil, content="false")
    let info_opt = manager.get_session(session_id)
    guard info_opt is Some(info) else { fail("Session not found") }
    // last_active 更新验证（设计第 1040 行，r2 审查问题8 修订）
    // 作为 send_message 成功的确定性验证（r1 审查问题1 修订：移除 info.busy 竞态断言）
    inspect(info.last_active.ms() > info.created_at.ms(), content="true")
    // web_search=true 参数传递验证（r1 审查问题8 修订）
    let sent2 = manager.send_message(session_id, msg, true)
    inspect(sent2 == @uuid.nil, content="false")
    // send_message(不存在的 id) 抛 SessionError::SessionNotFound（设计第 1039 行）
    let nonexistent = SessionId::from_uuid(mock.uuid.v4())
    try {
      let _ = manager.send_message(nonexistent, msg, false)
      fail("expected SessionNotFound")
    } catch {
      SessionError::SessionNotFound(_) => ()
      _ => fail("expected SessionNotFound")
    }
    manager.shutdown()
  })
}

///|
async test "service/manager_concurrent_limit" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
      max_sessions=2,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let r1 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard r1 is Success(session_id1, _) else {
      fail("Expected Success, got \{r1.to_json().stringify()}")
    }
    let r2 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r2 is Success(_, _), content="true")
    let r3 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r3 is LimitExceeded, content="true")
    // 超限后 sessions.size() 不变（行为契约第 926 行，r1 审查问题4 修订）
    inspect(manager.list_sessions().length(), content="2")
    // 关闭一个会话释放名额后恢复创建能力（行为契约第 924-928 行组合语义，r2 审查问题1 修订）
    let closed = manager.close_session(session_id1)
    inspect(closed, content="true")
    let r4 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r4 is Success(_, _), content="true")
    inspect(manager.list_sessions().length(), content="2")
    manager.shutdown()
  })
}

///|
async test "service/manager_concurrent_limit_one" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
      max_sessions=1,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    // 边界条件：max_sessions=1，创建 1 个成功
    let r1 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r1 is Success(_, _), content="true")
    // 第 2 个超限
    let r2 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r2 is LimitExceeded, content="true")
    manager.shutdown()
  })
}

///|
async test "service/manager_get_broadcast" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    let broadcast_opt = manager.get_session_broadcast(session_id)
    guard broadcast_opt is Some(broadcast) else { fail("Broadcast not found") }
    let event = @event.Event::new(id=mock.uuid.v4(), @event.PreConversation)
    broadcast.put(event)
    inspect(broadcast.values().length(), content="1")
    // 事件内容正确性验证（r2 审查问题5 修订）
    inspect(broadcast.values()[0] == event, content="true")
    let nonexistent = SessionId::from_uuid(mock.uuid.v4())
    inspect(manager.get_session_broadcast(nonexistent) is None, content="true")
    manager.shutdown()
  })
}

///|
async test "service/manager_command_queue" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let reply_queue = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
    manager.command_queue().put(List(reply_queue))
    let infos = reply_queue.get()
    inspect(infos.length(), content="0")
    // 有会话时通过 command_queue 直接提交命令验证（r2 审查问题4 修订）
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    let reply_queue2 = @aqueue.Queue::new(kind=@aqueue.Kind::Unbounded)
    manager.command_queue().put(List(reply_queue2))
    let infos2 = reply_queue2.get()
    inspect(infos2.length(), content="1")
    inspect(infos2[0].id == session_id, content="true")
    manager.shutdown()
  })
}

///|
async test "service/manager_session_info_fields" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, agent_id) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    let info_opt = manager.get_session(session_id)
    guard info_opt is Some(info) else { fail("Session not found") }
    // SessionInfo 字段正确性（行为契约第 925 行后置条件）
    inspect(info.id == session_id, content="true")
    inspect(info.agent_id == agent_id, content="true")
    inspect(info.agent_id.is_nil(), content="false")
    // 初始状态：空闲，last_active == created_at
    inspect(info.busy, content="false")
    inspect(info.created_at == info.last_active, content="true")
    manager.shutdown()
  })
}

///|
async test "service/manager_list_multiple_sessions" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let r1 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard r1 is Success(id1, aid1) else {
      fail("Expected Success, got \{r1.to_json().stringify()}")
    }
    let r2 = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard r2 is Success(id2, aid2) else {
      fail("Expected Success, got \{r2.to_json().stringify()}")
    }
    // list_sessions 返回所有会话快照（行为契约第 929 行）
    let infos = manager.list_sessions()
    inspect(infos.length(), content="2")
    // 两个 session_id 都在列表中
    inspect(infos[0].id == id1 || infos[0].id == id2, content="true")
    inspect(infos[1].id == id1 || infos[1].id == id2, content="true")
    inspect(infos[0].id != infos[1].id, content="true")
    // SessionInfo 其他字段正确性（r1 审查问题7 修订）
    let info1 = if infos[0].id == id1 { infos[0] } else { infos[1] }
    let info2 = if infos[0].id == id2 { infos[0] } else { infos[1] }
    inspect(info1.agent_id == aid1, content="true")
    inspect(info2.agent_id == aid2, content="true")
    inspect(info1.agent_id.is_nil(), content="false")
    inspect(info2.agent_id.is_nil(), content="false")
    // 初始状态：空闲，last_active == created_at
    inspect(info1.busy, content="false")
    inspect(info2.busy, content="false")
    inspect(info1.created_at == info1.last_active, content="true")
    inspect(info2.created_at == info2.last_active, content="true")
    manager.shutdown()
  })
}

///|
async test "service/manager_create_session_name_system_message_combinations" (
  t : @test.Test,
) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    // 覆盖 (Some, Some) 分支（r1 审查问题3 修订）
    let r1 = manager.create_session(CreateRequest::{
      name: Some("session-with-name-and-sm"),
      system_message: Some("custom system prompt"),
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r1 is Success(_, _), content="true")
    // 覆盖 (Some, None) 分支
    let r2 = manager.create_session(CreateRequest::{
      name: Some("session-with-name-only"),
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r2 is Success(_, _), content="true")
    // 覆盖 (None, Some) 分支
    let r3 = manager.create_session(CreateRequest::{
      name: None,
      system_message: Some("system prompt only"),
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    inspect(r3 is Success(_, _), content="true")
    inspect(manager.list_sessions().length(), content="3")
    manager.shutdown()
  })
}

///|
async test "service/manager_create_session_resume_id_not_found" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    // resume_id 分支：传入不存在的 resume_id，验证 conv_manager.load 返回 None 的错误路径
    // （r1 审查问题2 修订，设计第 538-547 行）
    let nonexistent_resume = mock.uuid.v4()
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: Some(nonexistent_resume),
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Failed(msg) else {
      fail("Expected Failed, got \{result.to_json().stringify()}")
    }
    inspect(
      msg,
      content="conversation not found: \{nonexistent_resume.to_string()}",
    )
    // 会话未创建，sessions 为空
    inspect(manager.list_sessions().length(), content="0")
    manager.shutdown()
  })
}

///|
async test "service/manager_get_session_agent" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    // 存在的会话返回 Some(agent)
    let agent_opt = manager.get_session_agent(session_id)
    inspect(agent_opt is Some(_), content="true")
    // 不存在的会话返回 None
    let nonexistent = SessionId::from_uuid(mock.uuid.v4())
    inspect(manager.get_session_agent(nonexistent) is None, content="true")
    manager.shutdown()
  })
}

///|
async test "service/manager_cancel_session" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    // 取消存在的会话返回 true
    let cancelled = manager.cancel_session(session_id)
    inspect(cancelled, content="true")
    // 会话仍存在（cancel 不移除会话）
    inspect(manager.get_session(session_id) is Some(_), content="true")
    // 取消不存在的会话返回 false
    let nonexistent = SessionId::from_uuid(mock.uuid.v4())
    let cancelled2 = manager.cancel_session(nonexistent)
    inspect(cancelled2, content="false")
    manager.shutdown()
  })
}

///|
async test "service/manager_send_message_returns_uuid" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    // send_message 返回 @uuid.Uuid 消息 ID（非 nil）
    let msg = @ai.user_message(content="Hello")
    let msg_id = manager.send_message(session_id, msg, false)
    inspect(msg_id == @uuid.nil, content="false")
    // send_message(不存在的 id) 抛 SessionError::SessionNotFound
    let nonexistent = SessionId::from_uuid(mock.uuid.v4())
    try {
      let _ = manager.send_message(nonexistent, msg, false)
      fail("expected SessionNotFound")
    } catch {
      SessionError::SessionNotFound(_) => ()
      _ => fail("expected SessionNotFound")
    }
    manager.shutdown()
  })
}

///|
async test "service/manager_create_session_empty_model_uses_default" (
  t : @test.Test,
) {
  @mock.run(t, mock => {
    let _ = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model="",
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: None,
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    // 验证使用了默认模型（anthropic/claude-sonnet-4.5）而非空字符串模型
    let agent = manager.get_session_agent(session_id)
    guard agent is Some(a) else { fail("expected agent for session") }
    guard a.model.to_json() is { "name": name_json, .. } else {
      fail("expected model with name field")
    }
    let model_name : String = @json.from_json(name_json)
    inspect(model_name, content="anthropic/claude-sonnet-4.5")
    manager.shutdown()
  })
}

///|
async test "service/manager_create_session_empty_model_in_request" (
  t : @test.Test,
) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    mock.group.spawn_bg(() => manager.run())
    let result = manager.create_session(CreateRequest::{
      name: None,
      system_message: None,
      web_search: None,
      resume_id: None,
      cwd: None,
      home: None,
      model: Some(""),
    })
    guard result is Success(session_id, _) else {
      fail("Expected Success, got \{result.to_json().stringify()}")
    }
    // 验证使用了默认模型（anthropic/claude-sonnet-4.5）而非 config.model 或空字符串
    let agent = manager.get_session_agent(session_id)
    guard agent is Some(a) else { fail("expected agent for session") }
    guard a.model.to_json() is { "name": name_json, .. } else {
      fail("expected model with name field")
    }
    let model_name : String = @json.from_json(name_json)
    inspect(model_name, content="anthropic/claude-sonnet-4.5")
    manager.shutdown()
  })
}
