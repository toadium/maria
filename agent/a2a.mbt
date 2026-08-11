///|
/// Agent 间消息路由契约（A2A Protocol 扩展预留点）。
///
/// P2 预留：仅定义 trait 契约，不实现具体路由逻辑。
/// 参考 AgentScope 2.0 A2A Protocol，AgentId 作为 A2A 通信寻址基础。
/// 后续可实现具体路由策略（本地路由、远程路由、广播等）。
///
/// 采用"返回 async 函数值的同步方法"模式（同 McpTransport 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。
pub(open) trait AgentRouter {
  fn route(Self, target : @agentid.AgentId, message : @ai.Message) -> async (
    Unit,
  ) -> Unit
}
