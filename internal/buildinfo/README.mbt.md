# internal/buildinfo

构建版本信息 — 语义版本号解析、比较与显示。

## Overview

- `Version`：语义版本（major.minor.patch + 可选 build 信息）
- `Build`：构建元数据（number + commit hash）
- `version`：当前构建的版本常量
- `Version::parse(str)`：从字符串解析版本号

## Usage

```mbt nocheck
///|
let v = @buildinfo.Version::parse("1.2.3")
inspect(v.major, content="1")
inspect(v.minor, content="2")
inspect(v.patch, content="3")
let current = @buildinfo.version
assert_true(v < current || v == current || v > current)
```

## API Reference

```mbt nocheck
///|
pub struct Version {
  major : Int
  minor : Int
  patch : Int
  build : Build?
} derive(ToJson)

///|
pub struct Build {
  number : Int
  commit : String
} derive(ToJson)

///|
pub let version : Version

///|
pub fn Version::parse(s : String) -> Version raise
```

## Integration

- 被 `@cmd/daemon` 用于版本检查
- 被 `@cmd/main` 用于 `--version` 输出
- `Version` 实现 `Compare`、`Eq`、`Show` 支持版本比较与显示