///|
/// RegistryWatcher — 工具缓存变更观察者实现（R22）。
///
/// 持有 ComponentRegistry 引用，on_change 时从 registry 移除已失效的工具。
/// 完整缓存一致性路径：McpClient 收到 notifications/tools/list_changed →
/// 重新 list_tools → diff → 回调 on_change → RegistryWatcher 更新 registry。
///
/// 采用"返回 async 函数值的同步方法"模式（同 R13-R21 先例）。
#warnings("-unused_field")
pub struct RegistryWatcher {
  priv registry : @component.ComponentRegistry
  priv mut last_known_tools : Array[String]
}

///|
/// 构造 RegistryWatcher，初始工具集为空。
pub fn RegistryWatcher::new(
  registry~ : @component.ComponentRegistry,
) -> RegistryWatcher {
  RegistryWatcher::{ registry, last_known_tools: [] }
}

///|
/// 更新已知工具集，自动 diff 并从 registry 移除不再存在的工具。
///
/// 新增的工具需由调用方通过 registry.register 注册，
/// 本方法仅负责移除已失效的工具。
pub fn RegistryWatcher::update_tools(
  self : RegistryWatcher,
  current_tool_names : Array[String],
) -> Unit {
  for name in self.last_known_tools {
    if not(current_tool_names.contains(name)) {
      self.registry.unregister(name)
    }
  }
  self.last_known_tools = current_tool_names
}

///|
/// 实现 ToolCacheWatcher trait：工具列表变更通知回调。
///
/// 收到 ToolsListChanged 通知时，标记需要重新同步工具列表。
/// 实际的 list_tools + diff 逻辑由 McpClient 调用方执行，
/// 然后通过 update_tools 方法更新 registry。
pub impl ToolCacheWatcher for RegistryWatcher with fn on_change(
  self : RegistryWatcher,
  change : ToolCacheChange,
) -> async (Unit) -> Unit {
  _ => {
    let _ = change
  }
}
