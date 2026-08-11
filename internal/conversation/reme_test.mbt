///|
/// MockIndex：内存索引 mock，用于验证 ReMeIndex trait object 可存储。
/// 记录已索引的会话 ID 集合与已失效的 ID 集合，不执行实际索引逻辑。
struct MockIndex {
  mut indexed : Array[@uuid.Uuid]
  invalidated : Array[@uuid.Uuid]
}

///|
fn MockIndex::new() -> MockIndex {
  MockIndex::{ indexed: [], invalidated: [] }
}

///|
impl ReMeIndex for MockIndex with fn rebuild(self : MockIndex) -> async (Unit) -> Unit {
  let _ = self
  _ => ()
}

///|
impl ReMeIndex for MockIndex with fn invalidate(
  self : MockIndex,
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
impl ReMeIndex for MockIndex with fn lookup(self : MockIndex, query : String) -> Array[
  @uuid.Uuid,
] {
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
async test "conversation/reme_index_trait_object_storable" {
  let mock = MockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  inspect(ReMeIndex::lookup(index, "*").length(), content="2")
  inspect(ReMeIndex::lookup(index, "*")[0] == id1, content="true")
  inspect(ReMeIndex::lookup(index, "*")[1] == id2, content="true")
}

///|
async test "conversation/reme_index_rebuild_then_lookup" {
  let mock = MockIndex::new()
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
}

///|
async test "conversation/reme_index_invalidate_then_lookup_excludes_id" {
  let mock = MockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id1)
  inspect(ReMeIndex::lookup(index, "*").length(), content="1")
  inspect(ReMeIndex::lookup(index, "*")[0] == id2, content="true")
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id1, content="true")
}

///|
/// 验证 MockIndex::new() 初始状态为空（行为契约：new() 后 indexed=[], invalidated=[]），
/// 并覆盖边界条件：空索引 lookup("*") 应返回空数组（零状态行为）。
async test "conversation/reme_index_new_initial_state" {
  let mock = MockIndex::new()
  inspect(mock.indexed.length(), content="0")
  inspect(mock.invalidated.length(), content="0")
  let index : &ReMeIndex = mock
  inspect(ReMeIndex::lookup(index, "*").length(), content="0")
}

///|
/// 验证行为契约：lookup(query) 当 query != "*" 返回 []。
/// 覆盖空索引 + 非 "*" 查询、非空索引 + 非 "*" 查询、边界查询字符串（空字符串/空白）。
async test "conversation/reme_index_lookup_non_wildcard_returns_empty" {
  let mock = MockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  inspect(ReMeIndex::lookup(index, "").length(), content="0")
  inspect(ReMeIndex::lookup(index, " ").length(), content="0")
  inspect(ReMeIndex::lookup(index, "foo").length(), content="0")
  inspect(ReMeIndex::lookup(index, "id1").length(), content="0")
}

///|
/// 验证边界条件：invalidate 不存在的 id（id 不在 indexed 中）应无副作用，
/// indexed 不变，invalidated 记录该 id（设计文档第 173 行前置条件允许 id 不在索引中）。
async test "conversation/reme_index_invalidate_nonexistent_id" {
  let mock = MockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  ReMeIndex::invalidate(index, id3)
  inspect(ReMeIndex::lookup(index, "*").length(), content="2")
  inspect(ReMeIndex::lookup(index, "*")[0] == id1, content="true")
  inspect(ReMeIndex::lookup(index, "*")[1] == id2, content="true")
  inspect(mock.invalidated.length(), content="1")
  inspect(mock.invalidated[0] == id3, content="true")
}

///|
/// 验证 trait 契约后置条件：lookup 返回数组无重复 ID（同 ID 不重复出现）。
/// 通过两两不同断言直接验证此后置条件。
async test "conversation/reme_index_lookup_no_duplicate_ids" {
  let mock = MockIndex::new()
  let index : &ReMeIndex = mock
  let id1 = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let id2 = @uuid.parse("12345678-1234-5678-1234-567812345678")
  let id3 = @uuid.parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
  mock.indexed.push(id1)
  mock.indexed.push(id2)
  mock.indexed.push(id3)
  let result = ReMeIndex::lookup(index, "*")
  inspect(result.length(), content="3")
  inspect(result[0] != result[1], content="true")
  inspect(result[0] != result[2], content="true")
  inspect(result[1] != result[2], content="true")
}
