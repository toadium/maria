# cmd/jsonl2md

JSONL 事件日志转 Markdown 工具 — 将 Maria 产生的 JSONL 日志转换为可读文档。

## Overview

独立可执行程序（`pkgtype: executable`），无对外导出 API。

功能：
- 将工具调用渲染为 XML/代码块
- 为 `replace_in_file`/`submit_fixed_file` 生成 diff
- 按子代理 (subagent) 拆分子日志文件
- 从日志中恢复诊断上下文 (`--recover-diagnostics`)

## CLI 用法

```
jsonl2md <log-file> --output <markdown-file> [--recover-diagnostics]
```

- 未指定 `--output` 时，输出路径为输入文件替换扩展名为 `.md`
- `--recover-diagnostics`：从日志中恢复源码诊断上下文

## Integration

- 终端可执行工具，无被依赖
- 依赖 `@internal/git` 生成 diff
- 依赖 `@event`、`@ai` 解析事件日志