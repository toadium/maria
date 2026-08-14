# Changelog

## [Unreleased]

## [0.3.0] - 2026-08-14

### P2 扩展点实现

- **R17 LocalRouter** (`agent/local_router.mbt`): `AgentRouter` 具体实现，持有 `AgentId → Agent` 路由表，`route` 查找目标 Agent 调用 `queue_message`
- **R18 SimpleTeam** (`agent/simple_team.mbt`): `AgentTeam` 具体实现，持有成员列表 + `&AgentRouter`，`broadcast` 遍历成员通过 `router.route` 投递消息
- **R19 LruIndex** (`internal/conversation/lru_index.mbt`): `ReMeIndex` 具体实现，LRU 淘汰策略 + 容量上限，`add`/`lookup`/`invalidate`/`rebuild`
- **R20 McpServer handle_request** (`mcp/server.mbt`): JSON-RPC 2.0 请求处理（`initialize`/`tools/list`/`tools/call`），从 `ComponentRegistry` 获取工具列表
- **R21 HttpSseTransport** (`mcp/http_sse_transport.mbt`): `McpServerTransport` 具体实现，`@httpx.Server` 创建/关闭 + SSE 流写入（`EventStreamWriter`）+ POST 请求处理 + `start_serving` 启动 HTTP 服务
- **R22 RegistryWatcher** (`mcp/registry_watcher.mbt`): `ToolCacheWatcher` 具体实现，`update_tools` 自动 diff 移除失效工具
- **R23 IdleReaper** (`service/idle_reaper.mbt`): 周期性空闲会话回收，基于 `@clock.Clock` 扫描 `list_sessions` → 过滤空闲 → `close_session`

### McpServer::serve 完整循环

- 从单次请求处理改为完整 loop 结构（`listen → loop(receive → handle_request → send)`）
- 当 `receive` 返回无 `method` 的空对象时退出循环（EOF 信号）
- 支持连续处理多个请求，直到 transport 返回空对象

### 质量改进

- R19 LruIndex: `capacity=0` 边界条件修复（拒绝所有添加）
- R18 SimpleTeam: `members()` 返回数组副本（防止外部修改内部状态）
- R21 HttpSseTransport: `listen` 幂等（先关闭旧 server 再创建新 server，防止资源泄漏）
- R21 HttpSseTransport: `close` 清空 `sse_writer` + 关闭 server（完整资源清理）

### 集成测试

- R17 LocalRouter: 5 个测试（构造 / contains / route unknown / unregister / trait object）
- R18 SimpleTeam: 8 个测试（构造 / add dedup / remove / broadcast / members copy / trait object）
- R19 LruIndex: 10 个测试（add / lookup / overwrite / capacity eviction / capacity=0 / invalidate / rebuild / trait object）
- R22 RegistryWatcher: 6 个测试（construct / update_tools / on_change / trait object）

### 文档优化

- 修复 README.md 中 Agent-as-a-Service 描述重复文本 bug
- 扩充 README.md 为大型项目模板（Quick Start、Project Structure、SDK、Development、Documentation、License）
- 同步 README.mbt.md 与 README.md 内容
- 优化 ui/vsc-ext 和 ui/native README 文档

## [0.2.0] - 2026-08-11

升级为参考 [AgentScope 2.0](https://github.com/alibaba/agentscope) 框架的 MoonBit Agent 框架。

### P0 核心改造

- **Agent Identity** (`agentid/`): 新增 `AgentId` newtype 值对象，包装 `@uuid.Uuid`，提供 `new`/`to_uuid`/`from_uuid`/`to_string`/`nil`/`is_nil` 方法
- **Modular Component Architecture** (`component/`): 新增 `Component` trait + `ComponentRegistry`，统一工具/提示词/技能组件抽象
- **Tool Sandboxing** (`sandbox/`): 新增 `Sandbox` trait + `LocalSandbox` + `RestrictedSandbox` + `Permission` 权限模型
- **Tool 改造** (`tool/`): `ToolDesc` 新增 `permissions` 字段，`Tool` 实现 `Component` trait
- **Full-stack Observability** (`trace/`): 新增 `TraceId`/`SpanId`/`Span`/`Tracer` + `NoopTracer`，全链路追踪
- **Event 改造** (`event/`): 新增 `span_context` 字段 + `EventDesc` 新变体
- **Agent 改造** (`agent/`): `Agent` 新增 `agent_id`/`tracer`/`registry`/`sandbox` 字段，会话循环接入 trace + 工具经 Sandbox 路由
- **Tools 适配** (`tools/`): 权限声明 + `ToolComponent` 适配
- **Prompt 适配** (`prompt/`): `PromptComponent` 适配
- **Skills 适配** (`internal/skills/`): `SkillComponent` 适配

### P1 能力扩展

- **MCP Support** (`mcp/`): `McpTransport` trait + `StdioTransport` + `McpClient` + `McpTool`，支持 MCP 协议客户端
- **Interactive Process** (`internal/spawn/`): `InteractiveProcess` + `spawn_interactive`，支持子进程交互
- **Agent-as-a-Service** (`service/`): `SessionManager` + `Session` + `SessionCommand`，多会话管理 + 并发上限配置
- **Server 改造** (`cmd/server/`): 多会话端点 + 会话生命周期管理
- **Framework Integration** (`sdk/`): Python/Node.js/Java SDK 同步更新

### P2 扩展点预留

- **A2A Protocol** (`agent/a2a.mbt`): `AgentRouter` trait 预留
- **AgentTeams** (`agent/team.mbt`): `AgentTeam` trait 预留
- **ReMe 记忆系统** (`internal/conversation/reme.mbt`): `ReMeIndex` trait + 注释约定
- **MCP 服务端** (`mcp/server.mbt`): `McpServerTransport` trait + `McpServer` struct 骨架
- **MCP HTTP/SSE 传输** (`mcp/http_sse_transport.mbt`): `HttpSseTransport` 骨架
- **MCP 工具缓存动态变更** (`mcp/tool_cache.mbt`): `ToolCacheWatcher` trait + `McpNotification` 骨架
- **多会话空闲超时与自动回收** (`service/idle_reaper.mbt`): `IdleReaper` struct 骨架

### Warning 治理

- 全仓库 `moon check` 通过：0 errors, 0 warnings
- `McpNotification.method` 字段重命名为 `method_`，通过 `derive(ToJson(fields(method_(rename = "method"))))` 保持 JSON-RPC 协议兼容
- Main 包 README.mbt.md 重命名为 README.md，消除 blackbox-test-in-main-package 警告

### 文档治理

- 全仓库 84 个 MoonBit 包均配备 README 文档（README.mbt.md 或 README.md）
- 每个包含：Overview、Usage 示例、API Reference（含签名）、Integration 说明
- 修复 6 个存根 README.md → 复制完整内容
- `moon fmt` 格式化全部文档代码块

### SDK 更新

- Python / Node.js / Java SDK 版本号同步至 0.2.0
- 补全 4 种缺失事件类型（ToolAdded, UserMessage, ConversationStart, ConversationEnd）
- Java Maria.java switch 语句覆盖全部 6 种事件

### FIXME 缺陷修复

- **ContextPruned 事件**: 仅在实际发生修剪时触发（之前即使未修剪也会触发）
- **TokenCounted 文档**: 澄清多次触发是预期行为
- **daemon TaskLock**: 记录单线程异步运行时下 semaphore 足够
- **daemon lock_daemon_file**: 记录 public 可见性为测试需要
- **daemon spawn_task**: 澄清 cleanup 在取消时运行、no_wait 用于并发监听
- **agent web search**: FIXME→TODO（功能增强）
- **agent uuid**: 记录上游限制的 workaround

### 性能优化

- **context_pruner O(n²) → O(n)**: 用增量跟踪替代全量重算 — 预计算占位符 token 数，每条消息仅计算 `original - placeholder` 增量
- **json2xml**: 更新数组处理注释为设计决策说明

### 测试覆盖率提升

- **internal/token_counter**: 10 个白盒测试（count_string, count_message, calibrate EMA/钳位, apply_calibration）
- **internal/readline/csi**: 2 个黑盒测试（csi 函数 + 常量验证）
- **tools/apply_patch**: 14 个黑盒测试（parse_patch 全路径 + 错误用例 + ApplyResult::summary）
- **internal/openai/responses**: 17 个黑盒测试（ContentType/ContentPart/ResponseInputItem/ResponseItem ToJson/FromJson + message_input + function_call_output + ResponsesRequest）

## [0.1.0] - Initial Release

maria（**m**oon **a**gent **r**ewritten **i**n **a**sync）初始版本，基于 [moonbitlang/async](https://github.com/moonbitlang/async) 的 MoonBit Agent 框架。
