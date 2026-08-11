///|
/// ReMe 记忆系统索引层契约（AgentScope 2.0 ReMe 索引扩展点预留）。
///
/// P2 预留：仅定义 trait 契约，不实现具体索引逻辑。
/// 参考 AgentScope 2.0 ReMe 记忆系统，ReMeIndex 为索引层抽象，
/// 具体实现（LRU 索引/向量索引/全文索引）后续添加。
/// 遵循"记忆文件为源数据、索引为派生状态"原则（见 manager.mbt 顶部注释），
/// 所有索引可由源数据（{home}/.moonagent/conversations/{id}.json）重建。
///
/// 采用"返回 async 函数值的同步方法"模式（同 R17 AgentRouter / R18 AgentTeam / R13 McpTransport 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。
pub(open) trait ReMeIndex {
  fn rebuild(Self) -> async (Unit) -> Unit
  fn invalidate(Self, id : @uuid.Uuid) -> Unit
  fn lookup(Self, query : String) -> Array[@uuid.Uuid]
}
