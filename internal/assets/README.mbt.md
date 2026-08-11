# internal/assets

资产文件安装 — 将一组文件（路径+内容）异步安装到指定目标目录。

## Overview

- `Asset`：单个资产文件（path + content）
- `install_assets(target, assets, ...)`：批量安装资产文件到目标目录

## Usage

```mbt nocheck
///|
let assets = [
  { path: "config/default.json", content: "{}" },
  { path: "templates/welcome.md", content: "# Welcome" },
]
@assets.install_assets(
  "/target/dir",
  assets,
  "source_name",
  "version_tag",
  log,
)
```

## API Reference

```mbt nocheck
///|
pub(all) struct Asset {
  path : String
  content : String
} derive(ToJson, Debug)

///|
pub async fn install_assets(
  target : String,
  assets : Array[Asset],
  source : String,
  version : String,
  logger : @pino.Logger,
) -> Unit
```

## Integration

- 被 `@internal/skills` 用于安装 skill 资产文件
- 自动创建目标目录结构并写入文件内容
- 带日志记录便于追踪安装过程