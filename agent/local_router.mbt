///|
/// 本地 A2A 路由实现（AgentScope 2.0 A2A Protocol 具体路由策略）。
///
/// R17 实现：LocalRouter 持有 AgentId → Agent 的本地路由表，
/// route 方法查找目标 Agent 并调用 queue_message 投递消息。
/// 适用于单进程多 Agent 通信场景。
#warnings("-unused_field")
pub struct LocalRouter {
  priv mut routes : Map[@agentid.AgentId, Agent]
}

///|
pub fn LocalRouter::new() -> LocalRouter {
  LocalRouter::{ routes: {} }
}

///|
/// 注册 Agent 到路由表，后续可通过 route(agent_id, message) 投递消息。
pub fn LocalRouter::register(
  self : LocalRouter,
  agent_id : @agentid.AgentId,
  agent : Agent,
) -> Unit {
  self.routes[agent_id] = agent
}

///|
/// 从路由表移除 Agent。
pub fn LocalRouter::unregister(
  self : LocalRouter,
  agent_id : @agentid.AgentId,
) -> Unit {
  self.routes.remove(agent_id)
}

///|
/// 查询路由表中是否存在指定 Agent。
pub fn LocalRouter::contains(
  self : LocalRouter,
  agent_id : @agentid.AgentId,
) -> Bool {
  self.routes.contains(agent_id)
}

///|
/// 实现 AgentRouter trait：查找目标 Agent 并投递消息。
///
/// 若目标 Agent 不存在于路由表，静默忽略（不报错）。
/// queue_message 为同步方法，route 返回的 async 函数仅包装同步调用。
pub impl AgentRouter for LocalRouter with fn route(
  self : LocalRouter,
  target : @agentid.AgentId,
  message : @ai.Message,
) -> async (Unit) -> Unit {
  _ => {
    match self.routes.get(target) {
      Some(agent) => ignore(agent.queue_message(message))
      None => ()
    }
  }
}
