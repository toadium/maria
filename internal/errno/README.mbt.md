# internal/errno

系统错误码常量与封装 — 提供常见 errno 值与当前 errno 获取。

## Overview

- `Errno`：可显示/可序列化的错误码子错误类型
- 常量：`eacces`、`eagain`、`ebadf`、`eexist`、`einval`、`enametoolong`、`enoent`、`enotty`、`erange`
- `get()`：获取当前 errno 值

## Usage

```mbt nocheck
///|
try {
  @fs.open("/nonexistent")
} catch {
  @os_error.OSError(errno, ..) if errno == @errno.enoent => {
    println("file not found")
  }
  error => raise error
}
```

## API Reference

```mbt nocheck
///|
pub(all) suberror Errno {
  Errno(Int)
}

///|
pub let eacces : Int
pub let eagain : Int
pub let ebadf : Int
pub let eexist : Int
pub let einval : Int
pub let enametoolong : Int
pub let enoent : Int
pub let enotty : Int
pub let erange : Int

///|
pub fn get() -> Int
```

## Integration

- 被全仓库 7+ 个包使用
- 被 `@internal/spawn` 用于子进程错误处理
- 被 `@internal/fsx`、`@internal/os` 用于文件/系统调用错误
- 被 `@internal/rand` 用于熵源读取错误
- 被 `@internal/tty` 用于终端操作错误