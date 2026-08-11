///|
/// 多 Agent 团队协作契约（AgentScope 2.0 AgentTeams 预留点）。
///
/// P2 预留：仅定义 trait 契约，不实现具体团队协作逻辑。
/// 参考 AgentScope 2.0 AgentTeams，多 Agent 以团队形式协作，
/// AgentId 标识团队成员，AgentRouter（R17 a2a.mbt）提供成员间消息路由，
/// AgentTeam 提供团队级成员管理与广播语义，二者互补。
/// 后续可实现具体团队策略（顺序协作、并行协作、管理者-执行者等）。
///
/// 采用"返回 async 函数值的同步方法"模式（同 AgentRouter / McpTransport 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。
pub(open) trait AgentTeam {
  fn members(Self) -> Array[@agentid.AgentId]
  fn add_member(Self, m : @agentid.AgentId) -> Unit
  fn remove_member(Self, m : @agentid.AgentId) -> Unit
  fn broadcast(Self, message : @ai.Message) -> async (Unit) -> Unit
}
