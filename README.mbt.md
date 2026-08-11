# moonbitlang/maria

**maria** is an initialism for **m**oon **a**gent **r**ewritten **i**n **a**sync, which utilizes [moonbitlang/async](https://github.com/moonbitlang/async).

maria v0.2.0 is upgraded with reference to [AgentScope 2.0](https://github.com/alibaba/agentscope) framework patterns.

## Features

- **Tool Sandboxing**: Permission-based tool execution via `Sandbox` trait (`LocalSandbox` / `RestrictedSandbox`)
- **Agent-as-a-Service**: Multi-session management via `SessionManager` with concurrent session limits
- **Full-stack Observability**: Distributed tracing via `Tracer` trait with `Span`/`TraceId`/`SpanId`
- **Modular Component Architecture**: Unified `Component` trait for tools, prompts, and skills via `ComponentRegistry`
- **MCP Support**: Model Context Protocol client (`McpClient` + `StdioTransport`) and server skeleton (`McpServer` + `HttpSseTransport`)
- **Framework Integration**: Python / Node.js / Java SDK
- **A2A Protocol**: `AgentRouter` trait extension point
- **AgentTeams**: `AgentTeam` trait extension point
- **ReMe Memory**: `ReMeIndex` trait extension point

## Usage

```bash
$ export OPENROUTER_API_KEY=<your_api_key>  # or OPENAI_API_KEY
$ moon update
$ moon run cmd/main
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
