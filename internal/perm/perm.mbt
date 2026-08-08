///|
/// 路径访问模式（Read/Write/Execute），用于 `Permission::PathAccess` 携带的访问模式声明。
pub(all) enum Access {
  Read
  Write
  Execute
} derive(Eq, ToJson, FromJson, Debug)

///|
/// 权限声明类型，描述工具执行所需的路径访问、命令执行、网络访问权限。
///
/// `PathAccess` 的 `path` 须为规范化路径。调用方构造
/// `Permission::PathAccess(path, access)` 前须先在 async 上下文中调用
/// `@fsx.resolve(path)` 规范化（解析 `.`/`..`、符号链接），与 `check_path`
/// 输入路径规范化契约一致。若 Permission 构造时 path 未规范化，审核链断裂，
/// 前缀匹配可能错误放行未规范化路径（如 `/home/user/app/../../../etc/passwd`），
/// 导致路径遍历攻击。
pub(all) enum Permission {
  PathAccess(String, Access)
  CommandExecution(String)
  NetworkAccess(String)
} derive(Eq, Debug)

///|
/// `Permission` 的 `ToJson` 实现（手动，JSON 对象形式，与 AgentScope 配置格式对齐）。
pub impl ToJson for Permission with fn to_json(self : Permission) -> Json {
  match self {
    PathAccess(path, access) =>
      {
        "type": "PathAccess",
        "path": path.to_json(),
        "access": access.to_json(),
      }
    CommandExecution(command) =>
      { "type": "CommandExecution", "command": command.to_json() }
    NetworkAccess(url) => { "type": "NetworkAccess", "url": url.to_json() }
  }
}

///|
/// `Permission` 的 `FromJson` 实现（手动，与 `ToJson` 对称）。
pub impl @json.FromJson for Permission with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Permission raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path=json_path)
  let type_str : String = object.required("type", path=json_path)
  match type_str {
    "PathAccess" => {
      let path : String = object.required("path", path=json_path)
      let access : Access = object.required("access", path=json_path)
      PathAccess(path, access)
    }
    "CommandExecution" => {
      let command : String = object.required("command", path=json_path)
      CommandExecution(command)
    }
    "NetworkAccess" => {
      let url : String = object.required("url", path=json_path)
      NetworkAccess(url)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "unknown permission type: \{type_str}"),
      )
  }
}
