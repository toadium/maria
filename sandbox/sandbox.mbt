///|
/// 沙箱抽象，声明权限审核、路径审核、工具执行包装契约。
pub(open) trait Sandbox {
  fn execute(
    self : Self,
    name : String,
    permissions : Array[@perm.Permission],
    f : async (Json) -> @tool.ToolResult noraise,
  ) -> async (Json) -> @tool.ToolResult noraise
  fn check_permission(self : Self, perm : @perm.Permission) -> Bool
  fn check_path(self : Self, path : String, access : @perm.Access) -> Bool
}

///|
/// 跨平台路径分隔符统一化：将 `\` 统一替换为 `/`。
///
/// 用于 `check_path` 前缀匹配前统一 path 与白名单/黑名单条目的分隔符。
/// 使用 `replace_all` 而非 `replace`——`replace` 只替换第一个匹配，
/// 路径含多个 `\` 时统一化不完整，导致 `check_path` 前缀匹配失败，
/// 可能错误放行本应拒绝的路径（安全缺陷）。
fn normalize_sep(path : String) -> String {
  path.replace_all(old="\\", new="/")
}

///|
/// 路径前缀匹配，在路径分隔符边界上进行。
///
/// 匹配规则：
/// 1. path 须以 prefix 开头（`path.has_prefix(prefix)`）
/// 2. prefix 以路径分隔符结尾（`prefix.has_suffix("/")`），
///    或 path 在 prefix 长度后的字符为分隔符或路径结束
///
/// 示例：
/// - prefix="/home/user/app", path="/home/user/app/file" → true（path[prefix.length()] == '/'）
/// - prefix="/home/user/app", path="/home/user/app" → true（path 长度 == prefix 长度，路径结束）
/// - prefix="/home/user/app", path="/home/user/app-secret/file" → false（path[prefix.length()] == '-'，非分隔符）
/// - prefix="/home/user/app/", path="/home/user/app/file" → true（prefix 以 / 结尾）
fn path_prefix_match(path : String, prefix : String) -> Bool {
  if !path.has_prefix(prefix) {
    return false
  }
  // prefix 以分隔符结尾，直接匹配
  if prefix.has_suffix("/") {
    return true
  }
  // path 长度 == prefix 长度，路径结束，匹配
  if path.length() == prefix.length() {
    return true
  }
  // 检查 path 在 prefix 长度后的字符为分隔符
  match path.get_char(prefix.length()) {
    Some('/') => true
    _ => false
  }
}
