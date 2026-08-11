# Changelog

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

## [0.1.0] - Initial Release

maria（**m**oon **a**gent **r**ewritten **i**n **a**sync）初始版本，基于 [moonbitlang/async](https://github.com/moonbitlang/async) 的 MoonBit Agent 框架。