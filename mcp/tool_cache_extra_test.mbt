///|
/// R22 v22 r1 Verifier 扩展测试：补充 ToolCacheChange / ToolCacheWatcher / McpNotification
/// 行为契约的边界条件、多调用累积、惰性求值、自定义构造等用例。
///
/// 复用 tool_cache_test.mbt 中已定义的 MockWatcher（同包测试文件共享命名空间），
/// 另引入 CountingWatcher 用于验证多次 on_change 调用累积 + 多观察者独立状态。

///|
/// CountingWatcher：记录 on_change 调用次数 + 累积变更列表，用于验证多次调用累积语义。
struct CountingWatcher {
  changes : Array[ToolCacheChange]
  mut call_count : Int
}

///|
#warnings("-unused_value")
fn CountingWatcher::new() -> CountingWatcher {
  CountingWatcher::{ changes: [], call_count: 0 }
}

///|
#warnings("-unused_value")
impl ToolCacheWatcher for CountingWatcher with fn on_change(
  self : CountingWatcher,
  change : ToolCacheChange,
) -> async (Unit) -> Unit {
  _ => {
    self.call_count = self.call_count + 1
    self.changes.push(change)
  }
}

///|
/// ToolCacheChange Eq 自反性 + Debug 输出格式 + ToJson/FromJson 多次往返稳定性。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_change_eq_reflexive_and_debug_format" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let change1 = ToolCacheChange::ToolsListChanged
    let change2 = ToolCacheChange::ToolsListChanged
    // Eq 自反性
    inspect(change1 == change1, content="true")
    // Eq 对称性
    inspect(change1 == change2, content="true")
    // Debug 输出格式（derive Debug）
    inspect(change1, content="ToolsListChanged")
    // ToJson/FromJson 多次往返稳定性
    let json1 = change1.to_json()
    let rt1 : ToolCacheChange = @json.from_json(json1)
    let json2 = rt1.to_json()
    let rt2 : ToolCacheChange = @json.from_json(json2)
    inspect(rt2 == change1, content="true")
    inspect(json1 == json2, content="true")
  })
}

///|
/// ToolCacheWatcher 多次 on_change 调用累积：3 次调用后 changes 长度为 3，call_count 为 3。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_watcher_multiple_calls_accumulate" (t : @test.Test) {
  @mock.run(t, _ => {
    let watcher = CountingWatcher::new()
    let change = ToolCacheChange::ToolsListChanged
    // 调用 3 次 on_change
    let f1 = ToolCacheWatcher::on_change(watcher, change)
    f1(())
    let f2 = ToolCacheWatcher::on_change(watcher, change)
    f2(())
    let f3 = ToolCacheWatcher::on_change(watcher, change)
    f3(())
    inspect(watcher.call_count, content="3")
    inspect(watcher.changes.length(), content="3")
    inspect(watcher.changes[0] == change, content="true")
    inspect(watcher.changes[1] == change, content="true")
    inspect(watcher.changes[2] == change, content="true")
  })
}

///|
/// 多观察者独立状态：两个 CountingWatcher 各自独立累积，互不干扰。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_watcher_multiple_watchers_independent" (
  t : @test.Test,
) {
  @mock.run(t, _ => {
    let watcher_a = CountingWatcher::new()
    let watcher_b = CountingWatcher::new()
    let change = ToolCacheChange::ToolsListChanged
    // watcher_a 调用 2 次
    let fa1 = ToolCacheWatcher::on_change(watcher_a, change)
    fa1(())
    let fa2 = ToolCacheWatcher::on_change(watcher_a, change)
    fa2(())
    // watcher_b 调用 1 次
    let fb1 = ToolCacheWatcher::on_change(watcher_b, change)
    fb1(())
    inspect(watcher_a.call_count, content="2")
    inspect(watcher_b.call_count, content="1")
    inspect(watcher_a.changes.length(), content="2")
    inspect(watcher_b.changes.length(), content="1")
  })
}

///|
/// 惰性求值：on_change 返回 async 函数值，未调用 f(()) 前观察者状态不变。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_watcher_lazy_evaluation" (t : @test.Test) {
  @mock.run(t, _ => {
    let watcher = CountingWatcher::new()
    let change = ToolCacheChange::ToolsListChanged
    // 获取 async 函数值但不调用
    let _f = ToolCacheWatcher::on_change(watcher, change)
    inspect(watcher.call_count, content="0")
    inspect(watcher.changes.length(), content="0")
  })
}

///|
/// MockWatcher（原 tool_cache_test.mbt 中定义）trait object 多次调用 + 显式 trait 方法调用。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/tool_cache_watcher_mock_watcher_reused" (t : @test.Test) {
  @mock.run(t, _ => {
    let watcher = MockWatcher::new()
    let cache_watcher : &ToolCacheWatcher = watcher
    let change = ToolCacheChange::ToolsListChanged
    // 显式 trait 方法调用 2 次
    let f1 = ToolCacheWatcher::on_change(cache_watcher, change)
    f1(())
    let f2 = ToolCacheWatcher::on_change(cache_watcher, change)
    f2(())
    inspect(watcher.changes.length(), content="2")
    inspect(watcher.changes[0] == change, content="true")
    inspect(watcher.changes[1] == change, content="true")
  })
}

///|
/// McpNotification 自定义构造：手动设定 method + params 字段（pub(all) 字段外部可见）。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/mcp_notification_custom_construct" (t : @test.Test) {
  @mock.run(t, _ => {
    // 手动构造带非空 params 的通知
    let params : Json = { "updated_tools": ["tool_a", "tool_b"] }
    let notification = McpNotification::{
      method_: "notifications/resources/updated",
      params,
    }
    inspect(notification.method_, content="\"notifications/resources/updated\"")
    json_inspect(notification.params, content={
      "updated_tools": ["tool_a", "tool_b"],
    })
  })
}

///|
/// McpNotification tools_list_changed 多次构造一致性：两次构造结果 method/params 一致。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/mcp_notification_tools_list_changed_consistent" (t : @test.Test) {
  @mock.run(t, _ => {
    let n1 = McpNotification::tools_list_changed()
    let n2 = McpNotification::tools_list_changed()
    inspect(n1.method_, content="\"notifications/tools/list_changed\"")
    inspect(n2.method_, content="\"notifications/tools/list_changed\"")
    inspect(n1.method_ == n2.method_, content="true")
    json_inspect(n1.params, content=Json::empty_object())
    json_inspect(n2.params, content=Json::empty_object())
  })
}

///|
/// McpNotification ToJson/FromJson 往返：自定义 method + 非空 params 往返后字段一致。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/mcp_notification_custom_serialize_roundtrip" (t : @test.Test) {
  @mock.run(t, _ => {
    let params : Json = { "count": 3, "tools": ["a", "b", "c"] }
    let notification = McpNotification::{
      method_: "notifications/custom",
      params,
    }
    let json = notification.to_json()
    let roundtripped : McpNotification = @json.from_json(json)
    inspect(roundtripped.method_, content="\"notifications/custom\"")
    json_inspect(roundtripped.params, content={
      "count": 3,
      "tools": ["a", "b", "c"],
    })
    json_inspect(json, content={
      "method": "notifications/custom",
      "params": { "count": 3, "tools": ["a", "b", "c"] },
    })
  })
}

///|
/// McpNotification Debug 输出格式（derive Debug）。
#cfg(all(target="native", not(platform="windows")))
async test "mcp/mcp_notification_debug_format" (t : @test.Test) {
  @mock.run(t, _ => {
    let notification = McpNotification::tools_list_changed()
    // Debug 输出包含 struct 名 + 字段
    inspect(
      notification,
      content="McpNotification::{method_: \"notifications/tools/list_changed\", params: {}}",
    )
  })
}
