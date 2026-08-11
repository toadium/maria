# cmd/main/exec

非交互式单次执行模式 — 从文件读取提示词，运行一次 Maria 会话并输出日志。

## Overview

- `exec(args)`：执行入口
- 参数：`--prompt-file`（必需）、`--model`/`-m`（必需）、`--log-file`（默认 `logs.jsonl`）

## Usage

```mbt nocheck
///|
// CLI: maria exec --prompt-file prompt.txt --model gpt-4o --log-file out.jsonl
@exec.exec(["--prompt-file", "prompt.txt", "--model", "gpt-4o"])
```

## API Reference

```mbt nocheck
///|
pub async fn exec(args : ArrayView[String]) -> Unit
```

## Integration

- 被 `@cmd/main` 作为 `exec` 子命令
- 依赖 `maria` 核心包运行单次会话
- 依赖 `@cmd/main/argument` 抛出 `InvalidArgument`