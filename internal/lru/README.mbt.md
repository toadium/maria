# internal/lru

泛型 LRU 缓存 — 键需 `Eq + Hash`，支持容量上限与 JSON 序列化。

## Overview

- `Cache[K, V]`：不透明泛型缓存类型，`K : Eq + Hash`
- `cache(max_size?)`：创建 LRU 缓存
- `get(key)` / `set(key, val)`：读写操作，自动淘汰最近最少使用项

## Usage

```mbt nocheck
///|
let c = @lru.cache(max_size=3)
c.set("a", 1)
c.set("b", 2)
c.set("c", 3)
c.set("d", 4)  // "a" 被淘汰
inspect(c.get("a"), content="None")
inspect(c.get("d"), content="Some(4)")
```

## API Reference

```mbt nocheck
///|
pub fn[K : Eq + Hash, V] cache(max_size? : Int) -> Cache[K, V]

///|
pub fn[K : Eq + Hash, V] Cache::get(self : Cache[K, V], key : K) -> V?

///|
pub fn[K : Eq + Hash, V] Cache::set(self : Cache[K, V], key : K, value : V) -> Unit
```

## Integration

- 被 `@internal/conversation` 用于缓存会话数据
- 当 `K : Show, V : ToJson` 时，`Cache` 实现 `ToJson` 可序列化