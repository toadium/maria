///|
test "permission_to_json_from_json_path_access" {
  let perm = @perm.Permission::PathAccess("/home/user/app", @perm.Access::Read)
  let roundtripped : @perm.Permission = @json.from_json(perm.to_json())
  json_inspect(roundtripped == perm, content=true)
  json_inspect(perm.to_json(), content={
    "type": "PathAccess",
    "path": "/home/user/app",
    "access": "Read",
  })
}

///|
test "permission_to_json_from_json_command_execution" {
  let perm = @perm.Permission::CommandExecution("ls -la")
  let roundtripped : @perm.Permission = @json.from_json(perm.to_json())
  json_inspect(roundtripped == perm, content=true)
  json_inspect(perm.to_json(), content={
    "type": "CommandExecution",
    "command": "ls -la",
  })
}

///|
test "permission_to_json_from_json_network_access" {
  let perm = @perm.Permission::NetworkAccess("http://example.com")
  let roundtripped : @perm.Permission = @json.from_json(perm.to_json())
  json_inspect(roundtripped == perm, content=true)
  json_inspect(perm.to_json(), content={
    "type": "NetworkAccess",
    "url": "http://example.com",
  })
}

///|
test "access_to_json_from_json" {
  let read = @perm.Access::Read
  let write = @perm.Access::Write
  let execute = @perm.Access::Execute
  let rt_read : @perm.Access = @json.from_json(read.to_json())
  let rt_write : @perm.Access = @json.from_json(write.to_json())
  let rt_execute : @perm.Access = @json.from_json(execute.to_json())
  json_inspect(rt_read == read, content=true)
  json_inspect(rt_write == write, content=true)
  json_inspect(rt_execute == execute, content=true)
  json_inspect(read.to_json(), content="Read")
  json_inspect(write.to_json(), content="Write")
  json_inspect(execute.to_json(), content="Execute")
}

///|
test "permission_from_json_unknown_type" {
  let unknown : Json = { "type": "Unknown", "path": "/x" }
  try {
    let _ : @perm.Permission = @json.from_json(unknown)
    fail("expected from_json to raise on unknown permission type")
  } catch {
    _ => ()
  }
}

///|
/// 契约2：Permission Eq —— 自反相等、同 path 不同 access 不等、不同变体互异。
test "permission_eq" {
  let p1 = @perm.Permission::PathAccess("/p", @perm.Access::Read)
  let p2 = @perm.Permission::PathAccess("/p", @perm.Access::Read)
  let p3 = @perm.Permission::PathAccess("/p", @perm.Access::Write)
  let p4 = @perm.Permission::CommandExecution("ls")
  let p5 = @perm.Permission::NetworkAccess("http://x")
  // 自反相等
  json_inspect(p1 == p2, content=true)
  // 同 path 不同 access 不等
  json_inspect(p1 == p3, content=false)
  // 不同变体互异
  json_inspect(p1 == p4, content=false)
  json_inspect(p1 == p5, content=false)
  json_inspect(p4 == p5, content=false)
}
