///|
/// MCP 工具缓存动态变更（AgentScope 2.0 MCP Support 客户端侧缓存一致性扩展点预留）。
///
/// P2 预留：仅 trait/struct/enum 定义 + 骨架方法 + 构造函数 + 注释 + mock 测试，
/// 不实现具体 diff/回调逻辑（后续实现时添加）。
///
/// 参考 AgentScope 2.0 MCP Support `notifications/tools/list_changed` 通知，
/// 缓存失效路径骨架：McpClient 收到通知 → 重新 list_tools → diff → 回调 ToolCacheWatcher::on_change → ComponentRegistry 更新。
/// 本步仅定义抽象类型不实现具体 diff/回调逻辑。
///
/// async trait 方法采用"返回 async 函数值的同步方法"模式（同 R13 McpTransport / R17 AgentRouter / R18 AgentTeam / R19 ReMeIndex / R20 McpServerTransport / R21 HttpSseTransport 先例），
/// 因含 `pub async fn` 方法的 trait 不允许作为 trait object 存储。

///|
/// 工具缓存变更通知类型（单变体，表示 MCP 服务端工具列表变更）。
pub(all) enum ToolCacheChange {
  ToolsListChanged
} derive(ToJson, FromJson, Debug, Eq)

///|
/// 工具缓存变更观察者扩展点（MCP 客户端侧缓存一致性回调契约）。
///
/// P2 预留：仅定义 trait 契约，不实现具体回调逻辑。
/// 后续可实现具体观察者（如 RegistryWatcher 持有 &ComponentRegistry，on_change 内部 unregister 旧工具 + register 新工具）。
/// McpClient 收到 notifications/tools/list_changed 通知后，重新 list_tools → diff → 回调 on_change 通知观察者更新缓存。
pub(open) trait ToolCacheWatcher {
  fn on_change(Self, change : ToolCacheChange) -> async (Unit) -> Unit
}

///|
/// MCP 通知消息骨架（JSON-RPC 2.0 通知，无 id 字段）。
///
/// 持有 method + params 字段，用于表示 MCP 服务端发送的通知消息。
/// tools_list_changed 构造方法返回 notifications/tools/list_changed 通知。
/// 字段 method_ 在 JSON 中映射为 "method"（JSON-RPC 2.0 协议标准字段名）。
pub(all) struct McpNotification {
  method_ : String
  params : Json
} derive (
  ToJson(fields(method_(rename="method"))),
  FromJson(fields(method_(rename="method"))),
  Debug,
)

///|
/// 构造 notifications/tools/list_changed 通知（工具列表变更通知）。
///
/// 返回 McpNotification，method 硬编码 "notifications/tools/list_changed"，params 为空对象（无参数）。
pub fn McpNotification::tools_list_changed() -> McpNotification {
  McpNotification::{
    method_: "notifications/tools/list_changed",
    params: Json::empty_object(),
  }
}
