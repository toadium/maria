///|
/// VerifierMockTeam：验证用 mock，独立于 team_test.mbt 的 MockTeam。
/// 用于基于行为契约验证 AgentTeam trait 的语义。
/// 记录成员列表与已广播消息，不执行实际团队协作逻辑。
struct VerifierMockTeam {
  mut members : Array[@agentid.AgentId]
  broadcasted : Array[@ai.Message]
}

///|
fn VerifierMockTeam::new() -> VerifierMockTeam {
  VerifierMockTeam::{ members: [], broadcasted: [] }
}

///|
impl AgentTeam for VerifierMockTeam with fn members(self : VerifierMockTeam) -> Array[
  @agentid.AgentId,
] {
  let result : Array[@agentid.AgentId] = []
  for m in self.members {
    result.push(m)
  }
  result
}

///|
impl AgentTeam for VerifierMockTeam with fn add_member(
  self : VerifierMockTeam,
  m : @agentid.AgentId,
) -> Unit {
  self.members.push(m)
}

///|
impl AgentTeam for VerifierMockTeam with fn remove_member(
  self : VerifierMockTeam,
  m : @agentid.AgentId,
) -> Unit {
  let result : Array[@agentid.AgentId] = []
  for x in self.members {
    if x != m {
      result.push(x)
    }
  }
  self.members = result
}

///|
impl AgentTeam for VerifierMockTeam with fn broadcast(
  self : VerifierMockTeam,
  message : @ai.Message,
) -> async (Unit) -> Unit {
  _ => self.broadcasted.push(message)
}

///|
/// 边界条件：新创建的团队 members() 应返回空数组。
async test "agent/team_verifier_empty_team_members" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  inspect(AgentTeam::members(team).length(), content="0")
}

///|
/// 正常路径：add_member(m) 后置条件——members() 包含 m。
async test "agent/team_verifier_add_member_postcondition" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let m = @agentid.AgentId::from_uuid(
    @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"),
  )
  AgentTeam::add_member(team, m)
  let ms = AgentTeam::members(team)
  inspect(ms.length(), content="1")
  inspect(ms[0] == m, content="true")
}

///|
/// 正常路径：remove_member(m) 后置条件——members() 不包含 m。
async test "agent/team_verifier_remove_member_postcondition" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let m = @agentid.AgentId::from_uuid(
    @uuid.parse("11111111-2222-3333-4444-555555555555"),
  )
  AgentTeam::add_member(team, m)
  AgentTeam::remove_member(team, m)
  inspect(AgentTeam::members(team).length(), content="0")
}

///|
/// 边界条件：移除不存在的成员应无副作用。
async test "agent/team_verifier_remove_nonexistent_no_side_effect" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let m1 = @agentid.AgentId::from_uuid(
    @uuid.parse("11111111-2222-3333-4444-555555555555"),
  )
  let m2 = @agentid.AgentId::from_uuid(
    @uuid.parse("99999999-8888-7777-6666-555555555555"),
  )
  AgentTeam::add_member(team, m1)
  AgentTeam::remove_member(team, m2)
  let ms = AgentTeam::members(team)
  inspect(ms.length(), content="1")
  inspect(ms[0] == m1, content="true")
}

///|
/// 状态交互：members() 返回副本，修改返回值不影响团队内部状态。
async test "agent/team_verifier_members_returns_copy" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let m = @agentid.AgentId::from_uuid(
    @uuid.parse("33333333-3333-3333-3333-333333333333"),
  )
  AgentTeam::add_member(team, m)
  let snapshot = AgentTeam::members(team)
  snapshot.clear()
  inspect(AgentTeam::members(team).length(), content="1")
}

///|
/// 边界条件：@agentid.nil 可作为团队成员增删。
async test "agent/team_verifier_nil_agent_id_as_member" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let nil_id = @agentid.nil
  AgentTeam::add_member(team, nil_id)
  let ms = AgentTeam::members(team)
  inspect(ms.length(), content="1")
  inspect(ms[0].is_nil(), content="true")
  AgentTeam::remove_member(team, nil_id)
  inspect(AgentTeam::members(team).length(), content="0")
}

///|
/// 边界条件：add_member 同一成员多次（允许重复，由 mock 语义决定）。
async test "agent/team_verifier_add_same_member_twice" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let m = @agentid.AgentId::from_uuid(
    @uuid.parse("44444444-4444-4444-4444-444444444444"),
  )
  AgentTeam::add_member(team, m)
  AgentTeam::add_member(team, m)
  inspect(AgentTeam::members(team).length(), content="2")
  AgentTeam::remove_member(team, m)
  inspect(AgentTeam::members(team).length(), content="0")
}

///|
/// 正常路径：broadcast(msg) 后消息被记录。
async test "agent/team_verifier_broadcast_records_message" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let message = @ai.user_message(content="broadcast hello")
  let f = AgentTeam::broadcast(team, message)
  f(())
  inspect(mock.broadcasted.length(), content="1")
  inspect(mock.broadcasted[0] == message, content="true")
}

///|
/// 边界条件：broadcast 在空团队上调用仍记录消息（无成员但广播语义成立）。
async test "agent/team_verifier_broadcast_on_empty_team" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let message = @ai.system_message(content="empty broadcast")
  let f = AgentTeam::broadcast(team, message)
  f(())
  inspect(mock.broadcasted.length(), content="1")
  inspect(AgentTeam::members(team).length(), content="0")
}

///|
/// 边界条件：broadcast 可处理 @ai.Message 的所有变体
/// （User/System/Assistant/Tool），不限于单一变体。
async test "agent/team_verifier_broadcast_all_message_variants" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let user_msg = @ai.user_message(content="user input")
  let f1 = AgentTeam::broadcast(team, user_msg)
  f1(())
  let sys_msg = @ai.system_message(content="system prompt")
  let f2 = AgentTeam::broadcast(team, sys_msg)
  f2(())
  let assistant_msg = @ai.assistant_message(content="assistant reply")
  let f3 = AgentTeam::broadcast(team, assistant_msg)
  f3(())
  let tool_msg = @ai.tool_message(content="tool result", tool_call_id="call_1")
  let f4 = AgentTeam::broadcast(team, tool_msg)
  f4(())
  inspect(mock.broadcasted.length(), content="4")
  inspect(mock.broadcasted[0] == user_msg, content="true")
  inspect(mock.broadcasted[1] == sys_msg, content="true")
  inspect(mock.broadcasted[2] == assistant_msg, content="true")
  inspect(mock.broadcasted[3] == tool_msg, content="true")
}

///|
/// 状态交互：多次 broadcast 保持消息记录的插入顺序。
async test "agent/team_verifier_multiple_broadcasts_preserve_order" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let msgs = [
    @ai.user_message(content="first"),
    @ai.system_message(content="second"),
    @ai.user_message(content="third"),
  ]
  for msg in msgs {
    let f = AgentTeam::broadcast(team, msg)
    f(())
  }
  inspect(mock.broadcasted.length(), content="3")
  inspect(mock.broadcasted[0] == msgs[0], content="true")
  inspect(mock.broadcasted[1] == msgs[1], content="true")
  inspect(mock.broadcasted[2] == msgs[2], content="true")
}

///|
/// 正常路径：VerifierMockTeam 可作为 &AgentTeam trait object 存储，
/// 且通过 trait object 调用所有 4 个方法行为正确。
async test "agent/team_verifier_trait_object_all_methods" {
  let mock = VerifierMockTeam::new()
  let team : &AgentTeam = mock
  let m1 = @agentid.AgentId::from_uuid(
    @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"),
  )
  let m2 = @agentid.AgentId::from_uuid(
    @uuid.parse("11111111-2222-3333-4444-555555555555"),
  )
  AgentTeam::add_member(team, m1)
  AgentTeam::add_member(team, m2)
  inspect(AgentTeam::members(team).length(), content="2")
  let message = @ai.assistant_message(content="team announcement")
  let f = AgentTeam::broadcast(team, message)
  f(())
  AgentTeam::remove_member(team, m1)
  let ms = AgentTeam::members(team)
  inspect(ms.length(), content="1")
  inspect(ms[0] == m2, content="true")
  inspect(mock.broadcasted.length(), content="1")
  inspect(mock.broadcasted[0] == message, content="true")
}
