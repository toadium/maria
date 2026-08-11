# internal/broadcast

内存扇出广播通道 — 保留历史值，新监听者可回放后再接收实时更新。

## Overview

- `Broadcast[T]`：泛型广播通道，保存所有广播过的值历史
- `put(data)`：追加值到历史并通知所有等待的读取者
- `read(index)`：阻塞读取指定索引的值，直到可用
- `add_listener(f)`：注册异步监听函数，可选是否回放历史
- `spawn_in(group)`：在 TaskGroup 中启动所有监听者，返回 `Session` 用于优雅停止
- `flush()`：同步处理所有待处理值
- `listen_forever(f)`：无限循环监听（不响应 Session::stop）

## Usage

```mbt nocheck
///|
let bc = @broadcast.Broadcast::new()
bc.add_listener(fn(event) {
  println("listener 1: \{event}")
})
bc.add_listener(include_history=false, fn(event) {
  println("listener 2: \{event}")
})
bc.put("hello")
bc.put("world")
@async.with_task_group(group => {
  let session = bc.spawn_in(group)
  // ... later
  session.stop()
})
```

## API Reference

```mbt nocheck
///|
pub fn[T] Broadcast::new() -> Broadcast[T]

///|
pub fn[T] Broadcast::put(self : Broadcast[T], data : T) -> Unit

///|
pub async fn[T] Broadcast::read(self : Broadcast[T], index : Int) -> T

///|
pub fn[T] Broadcast::add_listener(
  self : Broadcast[T],
  include_history? : Bool = true,
  f : async (T) -> Unit,
) -> Unit

///|
pub async fn[T, G] Broadcast::spawn_in(
  self : Broadcast[T],
  group : @async.TaskGroup[G],
) -> Session

///|
pub async fn[T] Broadcast::flush(self : Broadcast[T]) -> Unit

///|
pub async fn[T] Broadcast::listen_forever(
  self : Broadcast[T],
  include_history? : Bool = true,
  f : async (T) -> Unit,
) -> Unit

///|
pub fn Session::stop(self : Session) -> Unit
```

## Integration

- 被 `@agent` 用于事件分发（EventBroadcaster）
- 慢消费者不阻塞快消费者，但历史值在所有监听者消费完前会保留在内存
- 基于 `@cond_var.Cond` 实现等待/通知