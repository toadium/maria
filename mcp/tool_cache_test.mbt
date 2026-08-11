///|
/// MockWatcher：测试辅助类型，记录 on_change 调用的变更列表。
struct MockWatcher {
  changes : Array[ToolCacheChange]
}

///|
#warnings("-unused_value")
fn MockWatcher::new() -> MockWatcher {
  MockWatcher::{ changes: [] }
}

///|
#warnings("-unused_value")
impl ToolCacheWatcher for MockWatcher with fn on_change(
  self : MockWatcher,
  change : ToolCacheChange,
) -> async (Unit) -> Unit {
  _ => self.changes.push(change)
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_change_serialize" (t : @test.Test) {
  @mock.run(t, _ => {
    let change = ToolCacheChange::ToolsListChanged
    let json = change.to_json()
    let roundtripped : ToolCacheChange = @json.from_json(json)
    inspect(roundtripped == change, content="true")
    inspect(json, content="\"ToolsListChanged\"")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_watcher_trait_object_storable" (t : @test.Test) {
  @mock.run(t, _ => {
    let watcher = MockWatcher::new()
    let cache_watcher : &ToolCacheWatcher = watcher
    let change = ToolCacheChange::ToolsListChanged
    let f = ToolCacheWatcher::on_change(cache_watcher, change)
    f(())
    inspect(watcher.changes.length(), content="1")
    inspect(watcher.changes[0] == change, content="true")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/mcp_notification_construct" (t : @test.Test) {
  @mock.run(t, _ => {
    let notification = McpNotification::tools_list_changed()
    inspect(
      notification.method_,
      content="\"notifications/tools/list_changed\"",
    )
    json_inspect(notification.params, content=Json::empty_object())
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "mcp/mcp_notification_serialize" (t : @test.Test) {
  @mock.run(t, _ => {
    let notification = McpNotification::tools_list_changed()
    let json = notification.to_json()
    let roundtripped : McpNotification = @json.from_json(json)
    inspect(
      roundtripped.method_,
      content="\"notifications/tools/list_changed\"",
    )
    json_inspect(roundtripped.params, content=Json::empty_object())
    json_inspect(json, content={
      "method": "notifications/tools/list_changed",
      "params": Json::empty_object(),
    })
  })
}
