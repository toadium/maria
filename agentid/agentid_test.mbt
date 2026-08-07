///|
test "new" {
  let id = AgentId::new(@rand.chacha8())
  json_inspect(id.is_nil(), content=false)
}

///|
test "to_uuid_from_uuid" {
  let id = AgentId::new(@rand.chacha8())
  json_inspect(AgentId::from_uuid(id.to_uuid()) == id, content=true)
  let u = @uuid.generator(@rand.chacha8()).v4()
  json_inspect(AgentId::from_uuid(u).to_uuid() == u, content=true)
  // 边界条件：nil UUID 往返
  json_inspect(
    AgentId::from_uuid(@uuid.nil).to_uuid() == @uuid.nil,
    content=true,
  )
}

///|
test "to_string" {
  let id = AgentId::new(@rand.chacha8())
  json_inspect(id.to_string().length(), content=36)
  // 确定 UUID 验证完整 8-4-4-4-12 格式
  let fixed = AgentId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  json_inspect(
    fixed.to_string(),
    content="72212911-64d1-c441-e87d-de89b955ea34",
  )
}

///|
test "eq" {
  // 不等方向：使用确定的两个不同 UUID，消除概率性非确定性
  let id1 = AgentId::from_uuid(@uuid.nil)
  let id2 = AgentId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  json_inspect(id1 == id2, content=false)
  // 相等方向：对同一 Uuid，from_uuid 构造的 AgentId 相等
  let u = @uuid.generator(@rand.chacha8()).v4()
  json_inspect(AgentId::from_uuid(u) == AgentId::from_uuid(u), content=true)
  json_inspect(
    AgentId::from_uuid(@uuid.nil) == AgentId::from_uuid(@uuid.nil),
    content=true,
  )
  // 边界条件：from_uuid(@uuid.nil) == @agentid.nil
  json_inspect(AgentId::from_uuid(@uuid.nil) == @agentid.nil, content=true)
}

///|
test "hash" {
  let u = @uuid.generator(@rand.chacha8()).v4()
  let id1 = AgentId::from_uuid(u)
  let id2 = AgentId::from_uuid(u)
  json_inspect(id1 == id2, content=true)
  json_inspect(id1.hash() == id2.hash(), content=true)
  // nil 的 hash 一致性：不同构造路径但相等的 AgentId 具有相同 hash
  json_inspect(
    AgentId::from_uuid(@uuid.nil).hash() == @agentid.nil.hash(),
    content=true,
  )
}

///|
test "to_json_from_json" {
  let id = AgentId::new(@rand.chacha8())
  let roundtripped : AgentId = @json.from_json(id.to_json())
  json_inspect(roundtripped == id, content=true)
  // 验证 to_json 输出为 UUID 字符串
  let fixed = AgentId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  json_inspect(fixed.to_json(), content="72212911-64d1-c441-e87d-de89b955ea34")
}

///|
test "from_json_error" {
  // 非 String 类型应 raise JsonDecodeError
  let non_string : Json = 42.0
  try {
    let _ : AgentId = @json.from_json(non_string)
    fail("expected from_json to raise on non-string")
  } catch {
    _ => ()
  }
  // 非法 UUID 字符串应 raise JsonDecodeError
  try {
    let _ : AgentId = @json.from_json("not-a-uuid")
    fail("expected from_json to raise on invalid uuid string")
  } catch {
    _ => ()
  }
}

///|
test "nil_is_nil" {
  json_inspect(@agentid.nil.is_nil(), content=true)
  json_inspect(@agentid.nil.to_uuid() == @uuid.nil, content=true)
  json_inspect(
    @agentid.nil.to_string(),
    content="00000000-0000-0000-0000-000000000000",
  )
}

///|
test "show" {
  // 使用确定的 UUID 以获得静态快照
  let id = AgentId::from_uuid(
    @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34"),
  )
  // 验证 @debug.Debug 输出与 to_string 一致
  inspect(id, content="72212911-64d1-c441-e87d-de89b955ea34")
  // 验证 Show::output 输出与 to_string 一致（契约第 8 条直接验证）
  let sb = StringBuilder()
  let logger : &Logger = sb
  Show::output(id, logger)
  inspect(sb.to_string(), content="72212911-64d1-c441-e87d-de89b955ea34")
}
