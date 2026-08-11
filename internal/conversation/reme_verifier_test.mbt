///|
/// VerifierMockIndex：验证用 mock，独立于 reme_test.mbt 的 MockIndex。
/// 用于基于行为契约验证 ReMeIndex trait 的语义。
/// 记录已索引的会话 ID 集合与已失效的 ID 集合，不执行实际索引逻辑。
struct VerifierMockIndex {
  mut indexed : Array[@uuid.Uuid]
  invalidated : Array[@uuid.Uuid]
}

///|
fn VerifierMockIndex::new() -> VerifierMockIndex {
  VerifierMockIndex::{ indexed: [], invalidated: [] }
}

///|
impl ReMeIndex for VerifierMockIndex with fn rebuild(self : VerifierMockIndex) -> async (
  Unit,
) -> Unit {
  let _ = self
  _ => ()
}

///|
impl ReMeIndex for VerifierMockIndex with fn invalidate(
  self : VerifierMockIndex,
  id : @uuid.Uuid,
) -> Unit {
  self.invalidated.push(id)
  let result : Array[@uuid.Uuid] = []
  for x in self.indexed {
    if x != id {
      result.push(x)
    }
  }
  self.indexed = result
}

///|
impl ReMeIndex for VerifierMockIndex with fn lookup(
  self : VerifierMockIndex,
  query : String,
) -> Array[@uuid.Uuid] {
  // mock 语义：query 为 "*" 返回全部已索引 ID，否则返回空数组
  if query == "*" {
    let result : Array[@uuid.Uuid] = []
    for x in self.indexed {
      result.push(x)
    }
    result
  } else {
    []
  }
}

///|
/// 边界条件：新创建的索引 lookup("*") 应返回空数组。
async test "conversation/reme_verifier_new_empty_lookup" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  inspect(ReMeIndex::lookup(index, "*").length(), content="0")
}

///|
/// 边界条件：新创建的索引 lookup 对非 "*" 查询返回空数组。
async test "conversation/reme_verifier_new_empty_lookup_non_wildcard" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  inspect(ReMeIndex::lookup(index, "session-1").length(), content="0")
  inspect(ReMeIndex::lookup(index, "").length(), content="0")
}

///|
/// 正常路径：lookup("*") 返回已索引的 ID 集合（副本）。
async test "conversation/reme_verifier_lookup_wildcard_returns_indexed" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  let result = ReMeIndex::lookup(index, "*")
  inspect(result.length(), content="3")
  inspect(result[0] == id1, content="true")
  inspect(result[1] == id2, content="true")
  inspect(result[2] == id3, content="true")
}

///|
/// 边界条件：lookup 对非 "*" 查询始终返回空数组，无论 indexed 状态。
async test "conversation/reme_verifier_lookup_non_wildcard_always_empty" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  inspect(ReMeIndex::lookup(index, "session-1").length(), content="0")
  inspect(ReMeIndex::lookup(index, "id1").length(), content="0")
  inspect(ReMeIndex::lookup(index, "").length(), content="0")
  inspect(ReMeIndex::lookup(index, " ").length(), content="0")
}

///|
/// 正常路径：rebuild 为 no-op，不修改 indexed 状态。
async test "conversation/reme_verifier_rebuild_noop_preserves_indexed" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  let f = ReMeIndex::rebuild(index)
  f(())
  inspect(ReMeIndex::lookup(index, "*").length(), content="3")
  inspect(ReMeIndex::lookup(index, "*")[0] == id1, content="true")
  inspect(ReMeIndex::lookup(index, "*")[1] == id2, content="true")
  inspect(ReMeIndex::lookup(index, "*")[2] == id3, content="true")
}

///|
/// 状态交互：rebuild 为 no-op，不修改 invalidated 状态。
async test "conversation/reme_verifier_rebuild_noop_preserves_invalidated" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id1)
  inspect(mock.invalidated.length(), content="1")
  let f = ReMeIndex::rebuild(index)
  f(())
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id1, content="true")
}

///|
/// 正常路径：invalidate(id) 后置条件——lookup("*") 不包含 id。
async test "conversation/reme_verifier_invalidate_postcondition_excludes_id" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id1)
  let result = ReMeIndex::lookup(index, "*")
  inspect(result.length(), content="1")
  inspect(result[0] == id2, content="true")
  for x in result {
    inspect(x == id1, content="false")
  }
}

///|
/// 正常路径：invalidate(id) 将 id 追加到 invalidated 数组。
async test "conversation/reme_verifier_invalidate_records_invalidated" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id1)
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id1, content="true")
  ReMeIndex::invalidate(index, id2)
  inspect(mock.invalidated.length(), content="2")
  inspect(mock.invalidated[0] == id1, content="true")
  inspect(mock.invalidated[1] == id2, content="true")
}

///|
/// 边界条件：invalidate 不存在的 id 应无副作用（indexed 不变，但 invalidated 记录）。
async test "conversation/reme_verifier_invalidate_nonexistent_no_side_effect" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id3)
  let result = ReMeIndex::lookup(index, "*")
  inspect(result.length(), content="2")
  inspect(result[0] == id1, content="true")
  inspect(result[1] == id2, content="true")
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id3, content="true")
}

///|
/// 边界条件：对空索引 invalidate 应无副作用（indexed 保持空，invalidated 记录）。
async test "conversation/reme_verifier_invalidate_on_empty_index" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  ReMeIndex::invalidate(index, id1)
  inspect(ReMeIndex::lookup(index, "*").length(), content="0")
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id1, content="true")
}

///|
/// 状态交互：多次 invalidate 累积记录，indexed 逐步缩减。
async test "conversation/reme_verifier_multiple_invalidates_accumulate" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  ReMeIndex::invalidate(index, id1)
  inspect(ReMeIndex::lookup(index, "*").length(), content="2")
  ReMeIndex::invalidate(index, id2)
  inspect(ReMeIndex::lookup(index, "*").length(), content="1")
  ReMeIndex::invalidate(index, id3)
  inspect(ReMeIndex::lookup(index, "*").length(), content="0")
  inspect(mock.invalidated.length(), content="3")
  inspect(mock.invalidated[0] == id1, content="true")
  inspect(mock.invalidated[1] == id2, content="true")
  inspect(mock.invalidated[2] == id3, content="true")
}

///|
/// 边界条件：重复 invalidate 同一 id（幂等性——indexed 不含重复，invalidated 记录每次）。
async test "conversation/reme_verifier_invalidate_same_id_twice" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id1)
  ReMeIndex::invalidate(index, id1)
  inspect(ReMeIndex::lookup(index, "*").length(), content="1")
  inspect(ReMeIndex::lookup(index, "*")[0] == id2, content="true")
  inspect(mock.invalidated.length(), content="2")
  inspect(mock.invalidated[0] == id1, content="true")
  inspect(mock.invalidated[1] == id1, content="true")
}

///|
/// 后置条件：lookup 返回数组无重复 ID（同 ID 不重复出现）。
async test "conversation/reme_verifier_lookup_no_duplicates" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  let result = ReMeIndex::lookup(index, "*")
  // 3 个不同 ID，结果长度为 3，且两两不同（无重复）
  inspect(result.length(), content="3")
  inspect(result[0] != result[1], content="true")
  inspect(result[0] != result[2], content="true")
  inspect(result[1] != result[2], content="true")
}

///|
/// 状态交互：lookup("*") 返回副本，修改返回值不影响索引内部状态。
async test "conversation/reme_verifier_lookup_returns_copy" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  let snapshot = ReMeIndex::lookup(index, "*")
  snapshot.clear()
  inspect(ReMeIndex::lookup(index, "*").length(), content="2")
}

///|
/// 状态交互：rebuild 多次调用保持 no-op 语义。
async test "conversation/reme_verifier_multiple_rebuilds_noop" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  let f1 = ReMeIndex::rebuild(index)
  f1(())
  let f2 = ReMeIndex::rebuild(index)
  f2(())
  let f3 = ReMeIndex::rebuild(index)
  f3(())
  inspect(ReMeIndex::lookup(index, "*").length(), content="2")
  inspect(mock.invalidated.length(), content="0")
}

///|
/// 正常路径：VerifierMockIndex 可作为 &ReMeIndex trait object 存储，
/// 且通过 trait object 调用所有 3 个方法行为正确。
async test "conversation/reme_verifier_trait_object_all_methods" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  inspect(ReMeIndex::lookup(index, "*").length(), content="3")
  let f = ReMeIndex::rebuild(index)
  f(())
  inspect(ReMeIndex::lookup(index, "*").length(), content="3")
  ReMeIndex::invalidate(index, id2)
  let result = ReMeIndex::lookup(index, "*")
  inspect(result.length(), content="2")
  inspect(result[0] == id1, content="true")
  inspect(result[1] == id3, content="true")
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id2, content="true")
}

///|
/// 状态交互：rebuild 后 invalidate 后 lookup 的完整生命周期。
async test "conversation/reme_verifier_rebuild_then_invalidate_then_lookup" {
  let mock = VerifierMockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  let f = ReMeIndex::rebuild(index)
  f(())
  ReMeIndex::invalidate(index, id1)
  ReMeIndex::invalidate(index, id3)
  let result = ReMeIndex::lookup(index, "*")
  inspect(result.length(), content="1")
  inspect(result[0] == id2, content="true")
  inspect(mock.invalidated.length(), content="2")
  inspect(mock.invalidated[0] == id1, content="true")
  inspect(mock.invalidated[1] == id3, content="true")
}
