# internal/os

操作系统接口封装 — 命令行参数、环境变量、工作目录、主机名等。

## Overview

- `args()`：命令行参数
- `getenv(name)` / `setenv(name, val)` / `unsetenv(name)`：环境变量
- `cwd()` / `chdir(path)`：工作目录
- `home()` / `tmpdir()` / `executable()`：标准路径
- `gethostname()`：主机名
- `exit(code)` / `atexit(fn)`：进程退出

## Usage

```mbt nocheck
///|
let args = @os.args()
let home = @os.home()
let cwd = @os.cwd()
@os.setenv("MY_VAR", "value")
let val = @os.getenv("MY_VAR")
let hostname = @os.gethostname()
```

## API Reference

```mbt nocheck
///|
pub fn args() -> Array[String]
pub fn getenv(name : StringView) -> String? raise
pub fn setenv(name : StringView, value : StringView, overwrite? : Bool) -> Unit raise
pub fn unsetenv(name : StringView) -> Unit raise
pub fn cwd() -> String raise
pub fn chdir(path : StringView) -> Unit raise
pub fn home() -> String raise
pub fn tmpdir() -> String raise
pub fn executable() -> String raise
pub fn gethostname() -> String raise
pub fn[X] exit(code : Int) -> X
pub fn atexit(fn : FuncRef[() -> Unit]) -> Unit
```

## Integration

- 被全仓库 23+ 个包使用，是最基础的 OS 抽象层
- 被 `@pino` 用于获取 hostname
- 被 `@agent`、`@model`、`@sdk` 等用于读取环境变量配置
- 被 `@tools/search_files` 用于工作目录定位