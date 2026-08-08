///|
test "local_sandbox_check_permission_all_true" {
  let sandbox = LocalSandbox::new()
  json_inspect(
    sandbox.check_permission(
      @perm.Permission::PathAccess("/any", @perm.Access::Read),
    ),
    content=true,
  )
  json_inspect(
    sandbox.check_permission(@perm.Permission::CommandExecution("ls")),
    content=true,
  )
  json_inspect(
    sandbox.check_permission(@perm.Permission::NetworkAccess("http://any")),
    content=true,
  )
}

///|
test "local_sandbox_check_path_all_true" {
  let sandbox = LocalSandbox::new()
  json_inspect(
    sandbox.check_path("/any/path", @perm.Access::Read),
    content=true,
  )
  json_inspect(
    sandbox.check_path("/another", @perm.Access::Write),
    content=true,
  )
}

///|
async test "local_sandbox_execute_returns_f" {
  let sandbox = LocalSandbox::new()
  let f : async (Json) -> @tool.ToolResult noraise = fn(_) {
    @tool.success("ok")
  }
  let wrapped = sandbox.execute(
    "test_tool",
    [@perm.Permission::PathAccess("/any", @perm.Access::Read)],
    f,
  )
  let result = wrapped(Json::empty_object())
  json_inspect(result.to_json(), content=["Success", "ok"])
}

///|
async test "restricted_sandbox_check_permission_path_access" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    let etc_dir = d + "/etc"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    @fsx.make_directory(etc_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [etc_dir],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let app_file = app_dir + "/file"
    let etc_passwd = etc_dir + "/passwd"
    let unknown = d + "/unknown"
    json_inspect(
      sandbox.check_permission(
        @perm.Permission::PathAccess(app_file, @perm.Access::Read),
      ),
      content=true,
    )
    json_inspect(
      sandbox.check_permission(
        @perm.Permission::PathAccess(etc_passwd, @perm.Access::Read),
      ),
      content=false,
    )
    json_inspect(
      sandbox.check_permission(
        @perm.Permission::PathAccess(unknown, @perm.Access::Read),
      ),
      content=false,
    )
  })
}

///|
async test "restricted_sandbox_check_permission_command_execution" {
  let config_true = SandboxConfig::{
    path_whitelist: [],
    path_blacklist: [],
    command_enabled: true,
    cwd: ".",
  }
  let sandbox_true = RestrictedSandbox::new(config_true)
  json_inspect(
    sandbox_true.check_permission(@perm.Permission::CommandExecution("ls")),
    content=true,
  )
  let config_false = SandboxConfig::{
    path_whitelist: [],
    path_blacklist: [],
    command_enabled: false,
    cwd: ".",
  }
  let sandbox_false = RestrictedSandbox::new(config_false)
  json_inspect(
    sandbox_false.check_permission(@perm.Permission::CommandExecution("ls")),
    content=false,
  )
}

///|
async test "restricted_sandbox_check_permission_network_access" {
  let config = SandboxConfig::{
    path_whitelist: [],
    path_blacklist: [],
    command_enabled: false,
    cwd: ".",
  }
  let sandbox = RestrictedSandbox::new(config)
  json_inspect(
    sandbox.check_permission(
      @perm.Permission::NetworkAccess("http://example.com"),
    ),
    content=false,
  )
}

///|
async test "restricted_sandbox_execute_all_pass" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let app_file = app_dir + "/file"
    let f : async (Json) -> @tool.ToolResult noraise = fn(_) {
      @tool.success("ok")
    }
    let wrapped = sandbox.execute(
      "test_tool",
      [@perm.Permission::PathAccess(app_file, @perm.Access::Read)],
      f,
    )
    let result = wrapped(Json::empty_object())
    json_inspect(result.to_json(), content=["Success", "ok"])
  })
}

///|
async test "restricted_sandbox_execute_denied" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let etc_passwd = d + "/etc/passwd"
    let f : async (Json) -> @tool.ToolResult noraise = fn(_) {
      @tool.success("ok")
    }
    let wrapped = sandbox.execute(
      "dangerous_tool",
      [@perm.Permission::PathAccess(etc_passwd, @perm.Access::Read)],
      f,
    )
    let result = wrapped(Json::empty_object())
    json_inspect(result.to_json(), content=[
      "Failed",
      ["ToolFailure", "permission denied for tool dangerous_tool"],
    ])
  })
}

///|
async test "restricted_sandbox_execute_empty_permissions" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let f : async (Json) -> @tool.ToolResult noraise = fn(_) {
      @tool.success("ok")
    }
    let wrapped = sandbox.execute("test_tool", [], f)
    let result = wrapped(Json::empty_object())
    json_inspect(result.to_json(), content=["Success", "ok"])
  })
}

///|
async test "restricted_sandbox_check_path_separator_boundary" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let app_secret_file = d + "/app-secret/file"
    let app_file = app_dir + "/file"
    json_inspect(
      sandbox.check_path(app_secret_file, @perm.Access::Read),
      content=false,
    )
    json_inspect(sandbox.check_path(app_file, @perm.Access::Read), content=true)
  })
}

///|
async test "restricted_sandbox_check_path_blacklist_priority" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [app_dir],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let app_file = app_dir + "/file"
    json_inspect(
      sandbox.check_path(app_file, @perm.Access::Read),
      content=false,
    )
  })
}

///|
async test "restricted_sandbox_check_path_default_deny" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    let etc_dir = d + "/etc"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    @fsx.make_directory(etc_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [etc_dir],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let unknown = d + "/unknown"
    json_inspect(sandbox.check_path(unknown, @perm.Access::Read), content=false)
  })
}

///|
async test "restricted_sandbox_check_path_exact_match" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    json_inspect(sandbox.check_path(app_dir, @perm.Access::Read), content=true)
  })
}

///|
async test "restricted_sandbox_check_path_trailing_slash" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let whitelist_entry = app_dir + "/"
    let config = SandboxConfig::{
      path_whitelist: [whitelist_entry],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let app_file = app_dir + "/file"
    json_inspect(sandbox.check_path(app_file, @perm.Access::Read), content=true)
  })
}

///|
async test "restricted_sandbox_check_path_cross_platform_sep" {
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    let app_dir = d + "/app"
    @fsx.make_directory(app_dir, recursive=true, exists_ok=true)
    let config = SandboxConfig::{
      path_whitelist: [app_dir],
      path_blacklist: [],
      command_enabled: false,
      cwd: ".",
    }
    let sandbox = RestrictedSandbox::new(config)
    let app_file = app_dir + "/file"
    let cross_platform_path = app_file.replace_all(old="/", new="\\")
    json_inspect(
      sandbox.check_path(cross_platform_path, @perm.Access::Read),
      content=true,
    )
  })
}

///|
test "sandbox_config_to_json_from_json" {
  let config = SandboxConfig::{
    path_whitelist: ["/a", "/b"],
    path_blacklist: ["/c"],
    command_enabled: true,
    cwd: "/home",
  }
  let roundtripped : SandboxConfig = @json.from_json(config.to_json())
  json_inspect(roundtripped == config, content=true)
}

///|
test "sandbox_config_to_json_format" {
  let config = SandboxConfig::{
    path_whitelist: ["/a", "/b"],
    path_blacklist: ["/c"],
    command_enabled: true,
    cwd: "/home",
  }
  json_inspect(config.to_json(), content={
    "path_whitelist": ["/a", "/b"],
    "path_blacklist": ["/c"],
    "command_enabled": true,
    "cwd": "/home",
  })
}
