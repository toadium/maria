///|
/// MockRouter：内存路由 mock，用于验证 AgentRouter trait object 可存储。
/// 记录已路由的 (target, message) 对，不执行实际路由逻辑。
struct MockRouter {
  routed : Array[(@agentid.AgentId, @ai.Message)]
}

///|
fn MockRouter::new() -> MockRouter {
  MockRouter::{ routed: [] }
}

///|
impl AgentRouter for MockRouter with fn route(
  self : MockRouter,
  target : @agentid.AgentId,
  message : @ai.Message,
) -> async (Unit) -> Unit {
  _ => self.routed.push((target, message))
}

///|
async test "agent/a2a_router_trait_object_storable" {
  let mock = MockRouter::new()
  let router : &AgentRouter = mock
  let target = @agentid.nil
  let message = @ai.user_message(content="hello")
  let f = AgentRouter::route(router, target, message)
  f(())
  inspect(mock.routed.length(), content="1")
  inspect(mock.routed[0].0.is_nil(), content="true")
  inspect(mock.routed[0].1 == message, content="true")
}

///|
async test "agent/a2a_router_multiple_routes" {
  let mock = MockRouter::new()
  let router : &AgentRouter = mock
  let target1 = @agentid.nil
  let message1 = @ai.user_message(content="first")
  let f1 = AgentRouter::route(router, target1, message1)
  f1(())
  let target2 = @agentid.nil
  let message2 = @ai.user_message(content="second")
  let f2 = AgentRouter::route(router, target2, message2)
  f2(())
  inspect(mock.routed.length(), content="2")
  inspect(mock.routed[0].0.is_nil(), content="true")
  inspect(mock.routed[0].1 == message1, content="true")
  inspect(mock.routed[1].0.is_nil(), content="true")
  inspect(mock.routed[1].1 == message2, content="true")
}

///|
/// 验证 AgentRouter::route 可处理 @ai.Message 的所有变体
/// （System/Assistant/Tool），不限于 User。
/// 覆盖边界条件：消息类型变体。
async test "agent/a2a_router_with_different_message_types" {
  let mock = MockRouter::new()
  let router : &AgentRouter = mock
  let target = @agentid.nil
  let sys_msg = @ai.system_message(content="system prompt")
  let f1 = AgentRouter::route(router, target, sys_msg)
  f1(())
  let assistant_msg = @ai.assistant_message(content="assistant reply")
  let f2 = AgentRouter::route(router, target, assistant_msg)
  f2(())
  let tool_msg = @ai.tool_message(content="tool result", tool_call_id="call_1")
  let f3 = AgentRouter::route(router, target, tool_msg)
  f3(())
  inspect(mock.routed.length(), content="3")
  inspect(mock.routed[0].1 == sys_msg, content="true")
  inspect(mock.routed[1].1 == assistant_msg, content="true")
  inspect(mock.routed[2].1 == tool_msg, content="true")
}
