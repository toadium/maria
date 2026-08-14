///|
/// R17 LocalRouter 集成测试。
/// 验证 LocalRouter 的 register/unregister/contains/route 边界条件。
/// route 对未注册 Agent 为 no-op（不抛异常）。

///|
async test "agent/local_router_construct_empty" {
  let router = LocalRouter::new()
  let _ = router
  ()
}

///|
async test "agent/local_router_contains_unknown_returns_false" {
  let router = LocalRouter::new()
  let id = @agentid.nil
  inspect(router.contains(id), content="false")
}

///|
async test "agent/local_router_route_unknown_agent_noop" {
  let router = LocalRouter::new()
  let id = @agentid.nil
  let message = @ai.user_message(content="hello")
  let f = AgentRouter::route(router, id, message)
  f(())
  ()
}

///|
async test "agent/local_router_unregister_unknown_noop" {
  let router = LocalRouter::new()
  let id = @agentid.nil
  router.unregister(id)
  inspect(router.contains(id), content="false")
}

///|
async test "agent/local_router_trait_object_storable" {
  let router = LocalRouter::new()
  let router_trait : &AgentRouter = router
  let id = @agentid.nil
  let message = @ai.user_message(content="test")
  let f = AgentRouter::route(router_trait, id, message)
  f(())
  ()
}
