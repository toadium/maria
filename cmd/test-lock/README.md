# cmd/test-lock

文件锁测试工具 — 验证 `@fsx.lock_file` 机制与守护进程互斥行为。

## Overview

独立可执行程序（`pkgtype: executable`），无对外导出 API。

对指定路径文件以读写模式打开并加锁，成功后输出 `locked`，可选阻塞等待 stdin 保持锁占用。

## CLI 用法

```
test-lock <file-path> [--stdin]
```

- `--stdin`：加锁后阻塞等待 stdin 读取，使进程保持运行

## Integration

- 测试工具，无被依赖
- 依赖 `@internal/fsx` 提供文件锁