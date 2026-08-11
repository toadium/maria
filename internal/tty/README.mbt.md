# internal/tty

终端控制接口 — tty 检测、原始模式设置、终端窗口尺寸查询。

## Overview

- `isatty(fd)`：检测文件描述符是否为终端
- `set_raw_mode(fd)`：设置终端原始模式（禁用行缓冲、回显等）
- `window_size()`：获取终端窗口尺寸（行 × 列）
- `Size`：终端尺寸结构体

## Usage

```mbt nocheck
///|
if @tty.isatty(0) {
  println("stdin is a tty")
  @tty.set_raw_mode(0)
  let size = @tty.window_size()
  println("\{size.row} rows x \{size.col} cols")
}
```

## API Reference

```mbt nocheck
///|
pub struct Size {
  row : Int
  col : Int
} derive(ToJson)

///|
pub fn isatty(fd : Int, loc~ : SourceLoc) -> Bool raise

///|
pub fn set_raw_mode(fd : Int) -> Unit raise

///|
pub fn window_size() -> Size raise
```

## Integration

- 被 `@internal/readline` 用于检测终端与设置原始模式
- 依赖系统调用 `ioctl` 获取窗口尺寸