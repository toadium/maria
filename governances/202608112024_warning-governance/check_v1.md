# Warning 检查报告（v1）

## 检查结果

ISSUES_FOUND

## 执行信息

- 命令：`cjpm build && cjpm test --no-run`
- 实际执行：`moon check`（本项目为 MoonBit 项目，`cjpm` 不可用；`moon check` 已覆盖源码与测试代码的编译检查，等价于 build + test 编译阶段。`moon test --no-run` 参数不被 moon 工具支持）
- 退出码：1（存在 warning，moon check 以非零码退出）
- Warning总数：34

## Warning统计

| Warning类别 | 问题数 |
|------------|-------|
| unused_field | 11 |
| unused_value | 10 |
| unused_package | 4 |
| reserved_keyword | 4 |
| unused_variable | 2 |
| unused_constructor | 2 |
| deprecated | 1 |

## Warning清单

### unused_field

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| agent/agent.mbt | 65 | Field 'registry' is never read |
| mcp/http_sse_transport.mbt | 24 | Field 'host' is never read |
| mcp/http_sse_transport.mbt | 25 | Field 'port' is never read |
| mcp/http_sse_transport.mbt | 26 | Field 'endpoint' is never read |
| mcp/http_sse_transport.mbt | 27 | Field 'closed' is never read |
| mcp/server.mbt | 34 | Field 'registry' is never read |
| mcp/server.mbt | 36 | Field 'next_id' is never read |
| mcp/server_boundary_test.mbt | 14 | Field 'listened' is never read |
| mcp/server_test.mbt | 9 | Field 'listened' is never read |
| service/idle_reaper.mbt | 49 | Field 'manager' is never read |
| service/idle_reaper.mbt | 50 | Field 'config' is never read |

### unused_value

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| mcp/client_test.mbt | 12 | Unused function 'new' |
| mcp/client_test.mbt | 17 | Unused trait implementation |
| mcp/server_boundary_test.mbt | 18 | Unused function 'new' |
| mcp/server_boundary_test.mbt | 23 | Unused trait implementation |
| mcp/server_test.mbt | 13 | Unused function 'new' |
| mcp/server_test.mbt | 18 | Unused trait implementation |
| mcp/tool_cache_extra_test.mbt | 16 | Unused function 'new' |
| mcp/tool_cache_extra_test.mbt | 21 | Unused trait implementation |
| mcp/tool_cache_test.mbt | 8 | Unused function 'new' |
| mcp/tool_cache_test.mbt | 13 | Unused trait implementation |

### unused_package

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| _trait_probe/moon.pkg | 3 | Unused package 'moonbitlang/maria/sandbox' |
| agent/moon.pkg | 16 | Unused package 'moonbitlang/maria/internal/perm' |
| mcp/moon.pkg | 10 | Unused package 'moonbitlang/async' |
| mcp/moon.pkg | 12 | Unused package 'moonbitlang/maria/internal/mock' |

### reserved_keyword

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| mcp/tool_cache.mbt | 36 | The word `method` is reserved for possible future use. Please consider using another name. |
| mcp/tool_cache.mbt | 46 | The word `method` is reserved for possible future use. Please consider using another name. |
| mcp/tool_cache_extra_test.mbt | 144 | The word `method` is reserved for possible future use. Please consider using another name. |
| mcp/tool_cache_extra_test.mbt | 176 | The word `method` is reserved for possible future use. Please consider using another name. |

### unused_variable

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| mcp/http_sse_transport.mbt | 57 | Unused variable 'self' |
| mcp/http_sse_transport.mbt | 71 | Unused variable 'self' |

### unused_constructor

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| service/command.mbt | 4 | Variant 'ConcurrentLimit' is never constructed |
| service/command.mbt | 5 | Variant 'SessionAlreadyExists' is never constructed |

### deprecated

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| service/service_test.mbt | 37 | Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md |

## 原始输出

```
Warning: Main package `moonbitlang/maria/cmd/test-to-be-killed` uses blackbox-only test inputs (`_test.mbt` files, `.mbt.md` files) in package directory "D:\CodeWorkspace\forMoonbitMaria\maria\cmd\test-to-be-killed". Main packages will stop generating blackbox tests in a future release. Move public behavior into a non-main package and keep the main package as an entrypoint.
Warning: [0029]
   --> [ D:\CodeWorkspace\forMoonbitMaria\maria\_trait_probe\moon.pkg:3:3 ]
    | 3 |  "moonbitlang/maria/sandbox",
    |   |                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |   = Warning (unused_package): Unused package 'moonbitlang/maria/sandbox'
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\agent\agent.mbt:65:8 ]
    | 65 |  priv registry : @component.ComponentRegistry
    |    |        ^^^^^^^
    |    = Warning (unused_field): Field 'registry' is never read
Warning: [0029]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\agent\moon.pkg:16:3 ]
    | 16 |  "moonbitlang/maria/internal/perm",
    |    |                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |    = Warning (unused_package): Unused package 'moonbitlang/maria/internal/perm'
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\client_test.mbt:12:19 ]
    | 12 |fn MockTransport::new(responses : Array[Json]) -> MockTransport {
    |    |                  ^^
    |    = Warning (unused_value): Unused function 'new'
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\client_test.mbt:17:45 ]
    | 17 |impl McpTransport for MockTransport with fn send(
    |    |                                             ^^
    |    = Warning (unused_value): Unused trait implementation
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\http_sse_transport.mbt:24:8 ]
    | 24 |  priv host : String
    |    |        ^^^^
    |    = Warning (unused_field): Field 'host' is never read
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\http_sse_transport.mbt:25:8 ]
    | 25 |  priv port : Int
    |    |        ^^^^
    |    = Warning (unused_field): Field 'port' is never read
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\http_sse_transport.mbt:26:8 ]
    | 26 |  priv endpoint : String
    |    |            ^^^^^^^^
    |    = Warning (unused_field): Field 'endpoint' is never read
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\http_sse_transport.mbt:27:12 ]
    | 27 |  priv mut closed : Bool
    |    |            ^^^^^^
    |    = Warning (unused_field): Field 'closed' is never read
Warning: [0002]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\http_sse_transport.mbt:57:3 ]
    | 57 |  self : HttpSseTransport,
    |    |  ^^^^
    |    = Warning (unused_value): Unused variable 'self'
Warning: [0002]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\http_sse_transport.mbt:71:3 ]
    | 71 |  self : HttpSseTransport,
    |    |  ^^^^
    |    = Warning (unused_value): Unused variable 'self'
Warning: [0029]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\moon.pkg:10:3 ]
    | 10 |  "moonbitlang/async",
    |    |           ^^^^^^^^^^^^
    |    = Warning (unused_package): Unused package 'moonbitlang/async'
Warning: [0029]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\moon.pkg:12:3 ]
    | 12 |  "moonbitlang/maria/internal/mock",
    |    |                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |    = Warning (unused_package): Unused package 'moonbitlang/maria/internal/mock'
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server.mbt:34:8 ]
    | 34 |  priv registry : @component.ComponentRegistry
    |    |        ^^^^^^^
    |    = Warning (unused_field): Field 'registry' is never read
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server.mbt:36:12 ]
    | 36 |  priv mut next_id : Int
    |    |            ^^^^^^^
    |    = Warning (unused_field): Field 'next_id' is never read
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server_boundary_test.mbt:14:7 ]
    | 14 |  mut listened : Bool
    |    |      ^^^^^^^^
    |    = Warning (unused_field): Field 'listened' is never read
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server_boundary_test.mbt:18:27 ]
    | 18 |fn BoundaryMockTransport::new(responses : Array[Json]) -> BoundaryMockTransport {
    |    |                           ^^
    |    = Warning (unused_value): Unused function 'new'
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server_boundary_test.mbt:23:59 ]
    | 23 |impl McpServerTransport for BoundaryMockTransport with fn listen(
    |    |                                                           ^^^
    |    = Warning (unused_value): Unused trait implementation
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server_test.mbt:9:7 ]
    | 9 |  mut listened : Bool
    |   |      ^^^^^^^^
    |   = Warning (unused_field): Field 'listened' is never read
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server_test.mbt:13:25 ]
    | 13 |fn MockServerTransport::new(responses : Array[Json]) -> MockServerTransport {
    |    |                         ^^
    |    = Warning (unused_value): Unused function 'new'
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\server_test.mbt:18:57 ]
    | 18 |impl McpServerTransport for MockServerTransport with fn listen(
    |    |                                                         ^^^
    |    = Warning (unused_value): Unused trait implementation
Warning: [0035]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache.mbt:36:3 ]
    | 36 |  method : String
    |    |  ^^^^^^
    |    = Warning (reserved_keyword): The word `method` is reserved for possible future use. Please consider using another name.
Warning: [0035]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache.mbt:46:5 ]
    | 46 |    method: "notifications/tools/list_changed",
    |    |    ^^^^^^
    |    = Warning (reserved_keyword): The word `method` is reserved for possible future use. Please consider using another name.
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache_extra_test.mbt:16:21 ]
    | 16 |fn CountingWatcher::new() -> CountingWatcher {
    |    |                     ^^
    |    = Warning (unused_value): Unused function 'new'
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache_extra_test.mbt:21:51 ]
    | 21 |impl ToolCacheWatcher for CountingWatcher with fn on_change(
    |    |                                                   ^^^
    |    = Warning (unused_value): Unused trait implementation
Warning: [0035]
     --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache_extra_test.mbt:144:7 ]
     | 144 |      method: "notifications/resources/updated",
     |     |      ^^^^^^
     |     = Warning (reserved_keyword): The word `method` is reserved for possible future use. Please consider using another name.
Warning: [0035]
     --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache_extra_test.mbt:176:7 ]
     | 176 |      method: "notifications/custom",
     |     |      ^^^^^^
     |     = Warning (reserved_keyword): The word `method` is reserved for possible future use. Please consider using another name.
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache_test.mbt:8:17 ]
    | 8 |fn MockWatcher::new() -> MockWatcher {
    |   |                ^^
    |   = Warning (unused_value): Unused function 'new'
Warning: [0001]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\mcp\tool_cache_test.mbt:13:47 ]
    | 13 |impl ToolCacheWatcher for MockWatcher with fn on_change(
    |    |                                       ^^^
    |    = Warning (unused_value): Unused trait implementation
Warning: [0006]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\service\command.mbt:4:3 ]
    | 4 |  ConcurrentLimit
    |   |  ^^^^^^^^^^^^^^^
    |   = Warning (unused_constructor): Variant 'ConcurrentLimit' is never constructed
Warning: [0006]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\service\command.mbt:5:3 ]
    | 5 |  SessionAlreadyExists(SessionId)
    |   |  ^^^^^^^^^^^^^^^^^^^
    |   = Warning (unused_constructor): Variant 'SessionAlreadyExists' is never constructed
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\service\idle_reaper.mbt:49:8 ]
    | 49 |  priv manager : SessionManager
    |    |        ^^^^^^^
    |    = Warning (unused_field): Field 'manager' is never read
Warning: [0007]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\service\idle_reaper.mbt:50:8 ]
    | 50 |  priv config : IdleReaperConfig
    |    |        ^^^^^^
    |    = Warning (unused_field): Field 'config' is never read
Warning: [0020]
    --> [ D:\CodeWorkspace\forMoonbitMaria\maria\service\service_test.mbt:37:11 ]
    | 37 |  inspect(fixed.to_json(), content="72212911-64d1-c441-e87d-de89b955ea34")
    |    |          ^^^^^^^^
    |    = Warning (deprecated): Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md

Failed with 34 warnings, 0 errors.
```

## 判定

- **ISSUES_FOUND**：编译输出中存在 34 个 warning