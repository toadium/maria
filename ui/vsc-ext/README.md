# MoonBit Agent — VS Code Extension

VS Code 扩展，为 MoonBit Agent (maria) 提供编辑器内交互体验。

## Features

- 在 VS Code 内直接与 Maria AI Agent 对话
- 工具调用结果内联展示
- 会话历史管理

## Development

```bash
pnpm i
pnpm watch    # 监听编译
```

按 `F5` 启动扩展开发宿主。

## Build

```bash
pnpm package
```

输出 `.vsix` 文件，可通过 `code --install-extension <file>.vsix` 安装。

## See Also

- [vsc-extension-quickstart.md](vsc-extension-quickstart.md) — 快速入门指南
- [CHANGELOG.md](CHANGELOG.md) — 扩展版本变更
