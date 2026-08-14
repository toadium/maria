///|
/// R22 RegistryWatcher 集成测试。
/// 验证 RegistryWatcher 的 update_tools（自动 diff 移除失效工具）+ on_change。

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/registry_watcher_construct" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let watcher = RegistryWatcher::new(registry~)
    let _ = watcher
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/registry_watcher_update_tools_removes_obsolete" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let watcher = RegistryWatcher::new(registry~)
    watcher.update_tools(["tool_a", "tool_b"])
    watcher.update_tools(["tool_a"])
    let remaining = registry.list_by_type(ctype=@component.ComponentType::Tool)
    inspect(remaining.contains("tool_a"), content="true")
    inspect(remaining.contains("tool_b"), content="false")
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/registry_watcher_update_tools_empty_removes_all" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let watcher = RegistryWatcher::new(registry~)
    watcher.update_tools(["tool_a", "tool_b"])
    watcher.update_tools([])
    let remaining = registry.list_by_type(ctype=@component.ComponentType::Tool)
    inspect(remaining.length(), content="0")
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/registry_watcher_update_tools_same_list_noop" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let watcher = RegistryWatcher::new(registry~)
    watcher.update_tools(["tool_a", "tool_b"])
    watcher.update_tools(["tool_a", "tool_b"])
    let remaining = registry.list_by_type(ctype=@component.ComponentType::Tool)
    inspect(remaining.length(), content="0")
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/registry_watcher_on_change_noop" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let watcher = RegistryWatcher::new(registry~)
    let change : ToolCacheChange = ToolsListChanged
    let f = ToolCacheWatcher::on_change(watcher, change)
    f(())
    ()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/registry_watcher_trait_object_storable" (t : @test.Test) {
  @mock.run(t, _ => {
    let registry = @component.ComponentRegistry::new()
    let watcher = RegistryWatcher::new(registry~)
    let watcher_trait : &ToolCacheWatcher = watcher
    let change : ToolCacheChange = ToolsListChanged
    let f = ToolCacheWatcher::on_change(watcher_trait, change)
    f(())
    ()
  })
}
