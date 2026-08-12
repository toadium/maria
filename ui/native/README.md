# Maria Electron

Electron 桌面客户端，为 MoonBit Agent (maria) 提供原生跨平台 GUI。

## Prerequisites

- [Node.js](https://nodejs.org/) >= 18
- [pnpm](https://pnpm.io/)

## Development

```bash
pnpm i
```

在两个终端中并行运行：

```bash
pnpm watch    # 监听编译
pnpm dev      # 启动 Electron 开发模式
```

## Build

```bash
pnpm package
```

打包输出位于 `ui/native/out` 目录。

## See Also

- [maria 主仓库](../../README.md)
