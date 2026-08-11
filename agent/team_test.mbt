///|
/// MockTeam：内存团队 mock，用于验证 AgentTeam trait object 可存储。
/// 记录成员列表与已广播消息，不执行实际团队协作逻辑。
struct MockTeam {
  mut members : Array[@agentid.AgentId]
  broadcasted : Array[@ai.Message]
}

///|
fn MockTeam::new() -> MockTeam {
  MockTeam::{ members: [], broadcasted: [] }
}

///|
impl AgentTeam for MockTeam with fn members(self : MockTeam) -> Array[
  @agentid.AgentId,
] {
  let result : Array[@agentid.AgentId] = []
  for m in self.members {
    result.push(m)
  }
  result
}

///|
impl AgentTeam for MockTeam with fn add_member(
  self : MockTeam,
  m : @agentid.AgentId,
) -> Unit {
  self.members.push(m)
}

///|
impl AgentTeam for MockTeam with fn remove_member(
  self : MockTeam,
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
impl AgentTeam for MockTeam with fn broadcast(
  self : MockTeam,
  message : @ai.Message,
) -> async (Unit) -> Unit {
  _ => self.broadcasted.push(message)
}

///|
async test "agent/team_trait_object_storable" {
  let mock = MockTeam::new()
  let team : &AgentTeam = mock
  let m = @agentid.nil
  AgentTeam::add_member(team, m)
  let message = @ai.user_message(content="hello")
  let f = AgentTeam::broadcast(team, message)
  f(())
  inspect(AgentTeam::members(team).length(), content="1")
  inspect(AgentTeam::members(team)[0].is_nil(), content="true")
  inspect(mock.broadcasted.length(), content="1")
  inspect(mock.broadcasted[0] == message, content="true")
}

///|
async test "agent/team_member_add_remove" {
  let mock = MockTeam::new()
  let team : &AgentTeam = mock
  let m1 = @agentid.AgentId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  let m2 = @agentid.AgentId::from_uuid(
    @uuid.parse("12345678-1234-5678-1234-567812345678"),
  )
  AgentTeam::add_member(team, m1)
  AgentTeam::add_member(team, m2)
  inspect(AgentTeam::members(team).length(), content="2")
  AgentTeam::remove_member(team, m1)
  inspect(AgentTeam::members(team).length(), content="1")
  AgentTeam::add_member(team, m2)
  AgentTeam::remove_member(team, m2)
  inspect(AgentTeam::members(team).length(), content="0")
}

///|
/// 验证 AgentTeam::broadcast 可处理 @ai.Message 的所有变体
/// （User/System/Assistant/Tool），不限于单一变体。
/// 覆盖边界条件：消息类型变体。
async test "agent/team_broadcast_with_different_message_types" {
  let mock = MockTeam::new()
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
