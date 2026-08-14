///|
/// R19 LruIndex 集成测试。
/// 验证 LruIndex 的 add/lookup/invalidate/rebuild/size + 容量淘汰。

///|
test "conversation/lru_index_construct_empty" {
  let index = LruIndex::new()
  inspect(index.size(), content="0")
}

///|
test "conversation/lru_index_add_and_lookup" {
  let index = LruIndex::new()
  let id = @uuid.nil
  index.add("hello", id)
  inspect(index.size(), content="1")
  let result = index.lookup("hello")
  inspect(result.length(), content="1")
  inspect(result[0] == id, content="true")
}

///|
test "conversation/lru_index_lookup_nonexistent_returns_empty" {
  let index = LruIndex::new()
  let result = index.lookup("nonexistent")
  inspect(result.length(), content="0")
}

///|
test "conversation/lru_index_add_overwrite_existing" {
  let index = LruIndex::new()
  let id1 = @uuid.nil
  let id2 = @uuid.max
  index.add("query", id1)
  index.add("query", id2)
  inspect(index.size(), content="1")
  let result = index.lookup("query")
  inspect(result[0] == id2, content="true")
}

///|
test "conversation/lru_index_capacity_eviction" {
  let index = LruIndex::new(capacity=2)
  let id1 = @uuid.nil
  let id2 = @uuid.max
  let id3 = @uuid.nil
  index.add("q1", id1)
  index.add("q2", id2)
  index.add("q3", id3)
  inspect(index.size(), content="2")
  inspect(index.lookup("q1").length(), content="0")
  inspect(index.lookup("q2").length(), content="1")
  inspect(index.lookup("q3").length(), content="1")
}

///|
test "conversation/lru_index_capacity_zero_rejects_all" {
  let index = LruIndex::new(capacity=0)
  let id = @uuid.nil
  index.add("query", id)
  inspect(index.size(), content="0")
}

///|
test "conversation/lru_index_invalidate_removes_entries" {
  let index = LruIndex::new()
  let id = @uuid.nil
  index.add("q1", id)
  index.add("q2", id)
  inspect(index.size(), content="2")
  index.invalidate(id)
  inspect(index.size(), content="0")
  inspect(index.lookup("q1").length(), content="0")
  inspect(index.lookup("q2").length(), content="0")
}

///|
test "conversation/lru_index_invalidate_nonexistent_noop" {
  let index = LruIndex::new()
  let id1 = @uuid.nil
  let id2 = @uuid.max
  index.add("q1", id1)
  index.invalidate(id2)
  inspect(index.size(), content="1")
}

///|
async test "conversation/lru_index_rebuild_clears_all" {
  let index = LruIndex::new()
  let id = @uuid.nil
  index.add("q1", id)
  inspect(index.size(), content="1")
  let f = ReMeIndex::rebuild(index)
  f(())
  inspect(index.size(), content="0")
}

///|
async test "conversation/lru_index_trait_object_storable" {
  let index = LruIndex::new()
  let index_trait : &ReMeIndex = index
  let f = ReMeIndex::rebuild(index_trait)
  f(())
  ()
}
