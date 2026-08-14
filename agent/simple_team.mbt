///|
/// 简单团队协作实现（AgentScope 2.0 AgentTeams 具体策略）。
///
/// R18 实现：SimpleTeam 持有成员列表 + AgentRouter 引用，
/// broadcast 遍历成员通过 router.route 投递消息。
/// 适用于顺序协作、广播通知等场景。
#warnings("-unused_field")
pub struct SimpleTeam {
  priv mut members_ : Array[@agentid.AgentId]
  priv router : &AgentRouter
}

///|
/// 构造 SimpleTeam，需提供 AgentRouter 引用用于成员间消息路由。
pub fn SimpleTeam::new(router~ : &AgentRouter) -> SimpleTeam {
  SimpleTeam::{ members_: [], router }
}

///|
/// 实现 AgentTeam trait：返回当前成员列表的副本。
pub impl AgentTeam for SimpleTeam with fn members(self : SimpleTeam) -> Array[
  @agentid.AgentId,
] {
  self.members_.copy()
}

///|
/// 实现 AgentTeam trait：添加成员（去重）。
pub impl AgentTeam for SimpleTeam with fn add_member(
  self : SimpleTeam,
  m : @agentid.AgentId,
) -> Unit {
  if not(self.members_.contains(m)) {
    self.members_.push(m)
  }
}

///|
/// 实现 AgentTeam trait：移除成员。
pub impl AgentTeam for SimpleTeam with fn remove_member(
  self : SimpleTeam,
  m : @agentid.AgentId,
) -> Unit {
  self.members_ = self.members_.filter(fn(x) { x != m })
}

///|
/// 实现 AgentTeam trait：向所有成员广播消息。
///
/// 遍历成员列表，对每个成员调用 router.route(member, message)。
/// route 返回 async 函数，立即执行（()）以完成消息投递。
pub impl AgentTeam for SimpleTeam with fn broadcast(
  self : SimpleTeam,
  message : @ai.Message,
) -> async (Unit) -> Unit {
  _ => {
    for member in self.members_ {
      let route_fn = AgentRouter::route(self.router, member, message)
      route_fn(())
    }
  }
}
