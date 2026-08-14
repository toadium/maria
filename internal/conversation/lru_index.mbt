///|
/// LRU 记忆索引实现（AgentScope 2.0 ReMe 索引层具体实现）。
///
/// R19 实现：LruIndex 持有 query → conversation_id 的映射表 + 容量上限。
/// 当条目数超过容量时，按插入顺序淘汰最旧条目（简易 LRU）。
/// 适用于会话历史关键词检索场景。
///
/// 遵循"记忆文件为源数据、索引为派生状态"原则（见 manager.mbt 顶部注释），
/// 所有索引可由源数据重建。
pub struct LruIndex {
  priv mut index : Map[String, @uuid.Uuid]
  priv mut access_order : Array[String]
  priv capacity : Int
}

///|
/// 构造 LruIndex，默认容量 100 条。
pub fn LruIndex::new(capacity? : Int = 100) -> LruIndex {
  LruIndex::{ index: {}, access_order: [], capacity }
}

///|
/// 向索引添加条目。若容量已满，淘汰最旧条目。
pub fn LruIndex::add(self : LruIndex, query : String, id : @uuid.Uuid) -> Unit {
  if self.capacity <= 0 {
    return
  }
  if self.index.contains(query) {
    self.index[query] = id
    return
  }
  if self.index.size() >= self.capacity {
    if self.access_order.length() > 0 {
      let oldest = self.access_order[0]
      self.access_order.remove(0)
      self.index.remove(oldest)
    }
  }
  self.index[query] = id
  self.access_order.push(query)
}

///|
/// 查询索引条目数。
pub fn LruIndex::size(self : LruIndex) -> Int {
  self.index.size()
}

///|
/// 实现 ReMeIndex trait：重建索引（清空全部条目）。
///
/// 完整实现时可扫描 {home}/.moonagent/conversations/ 目录重建索引。
/// 本实现清空索引，由调用方后续 add 条目。
pub impl ReMeIndex for LruIndex with fn rebuild(self : LruIndex) -> async (Unit) -> Unit {
  _ => {
    self.index = {}
    self.access_order = []
  }
}

///|
/// 实现 ReMeIndex trait：使指定会话 ID 的所有索引条目失效。
pub impl ReMeIndex for LruIndex with fn invalidate(
  self : LruIndex,
  id : @uuid.Uuid,
) -> Unit {
  let keys_to_remove = []
  for k, v in self.index {
    if v == id {
      keys_to_remove.push(k)
    }
  }
  for k in keys_to_remove {
    self.index.remove(k)
    self.access_order = self.access_order.filter(fn(x) { x != k })
  }
}

///|
/// 实现 ReMeIndex trait：按查询关键词查找会话 ID。
///
/// 精确匹配 query 字符串，返回匹配的会话 ID 列表（0 或 1 个结果）。
pub impl ReMeIndex for LruIndex with fn lookup(self : LruIndex, query : String) -> Array[
  @uuid.Uuid,
] {
  match self.index.get(query) {
    Some(id) => [id]
    None => []
  }
}
