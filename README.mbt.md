# moonbitlang/maria

> **m**oon **a**gent **r**ewritten **i**n **a**sync

maria 是一个基于 [MoonBit](https://www.moonbitlang.com) 语言和 [moonbitlang/async](https://github.com/moonbitlang/async) 异步运行时构建的 AI Agent 框架。v0.2.0 参照 [AgentScope 2.0](https://github.com/alibaba/agentscope) 框架模式升级，提供工具沙箱、全链路追踪、多会话管理、MCP 协议支持等企业级能力。

## Features

- **Tool Sandboxing** — 基于 `Sandbox` trait 的权限化工具执行（`LocalSandbox` / `RestrictedSandbox`）
- **Agent-as-a-Service** — 通过 `SessionManager` 进行多会话管理，支持并发会话上限配置
- **Full-stack Observability** — 通过 `Tracer` trait 实现分布式追踪，含 `Span`/`TraceId`/`SpanId`
- **Modular Component Architecture** — 统一 `Component` trait 抽象工具/提示词/技能，通过 `ComponentRegistry` 管理
- **MCP Support** — Model Context Protocol 客户端（`McpClient` + `StdioTransport`）与服务端骨架（`McpServer` + `HttpSseTransport`）
- **Framework Integration** — Python / Node.js / Java SDK 多语言集成
- **A2A Protocol** — `AgentRouter` trait 扩展点
- **AgentTeams** — `AgentTeam` trait 扩展点
- **ReMe Memory** — `ReMeIndex` trait 扩展点

## Quick Start

```bash
# 安装 MoonBit 工具链
# 参考 https://www.moonbitlang.com

# 克隆仓库
git clone https://github.com/moonbitlang/maria.git
cd maria
git submodule update --init --recursive

# 配置 API Key
export OPENROUTER_API_KEY=<your_api_key>  # 或 OPENAI_API_KEY

# 更新依赖并运行
moon update
moon run cmd/main
```

## Project Structure

```
maria/
├── agent/            # Agent 核心循环
├── agentid/          # AgentId 值对象
├── ai/               # AI 消息抽象层
├── clock/            # 时钟抽象
├── cmd/              # 可执行入口（main/server/daemon/jsonl2md/...）
├── component/        # 组件注册中心
├── event/            # 事件系统
├── file/             # 文件操作
├── internal/         # 内部工具包（os/fsx/pathx/openai/readline/...）
├── job/              # 后台任务
├── mcp/              # MCP 协议客户端/服务端
├── model/            # LLM 模型配置
├── oauth/            # OAuth 认证（codex/copilot）
├── prompt/           # 提示词管理
├── sandbox/          # 工具沙箱
├── sdk/              # 多语言 SDK（python/nodejs/java）
├── service/          # 会话管理服务
├── tool/             # 工具抽象
├── tools/            # 内置工具集
├── trace/            # 分布式追踪
└── ui/               # 用户界面（web/native/vsc-ext）
```

## SDK

| 语言 | 路径 | 安装 |
|------|------|------|
| Python | `sdk/python` | `pip install maria-python` |
| Node.js | `sdk/nodejs` | `npm install maria` |
| Java | `sdk/java` | `mvn clean install` |

详见各 SDK 目录下的 README。

## Development

```bash
moon check          # 类型检查 + lint
moon fmt            # 格式化代码
moon test           # 运行测试
moon info           # 更新 .mbti 接口文件
```

详见 [DEVELOPER.md](DEVELOPER.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。

## Documentation

- [CHANGELOG.md](CHANGELOG.md) — 版本变更记录
- [CONTRIBUTING.md](CONTRIBUTING.md) — 贡献指南
- [DEVELOPER.md](DEVELOPER.md) — 开发者笔记
- [AGENTS.md](AGENTS.md) — AI Agent 协作指南
- 每个包目录下均有 `README.mbt.md` 或 `README.md` 提供包级文档

## License

[Apache License 2.0](LICENSE)
