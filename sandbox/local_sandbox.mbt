///|
/// 默认沙箱，全放行，保证与 v0.1.0 行为完全一致。
pub struct LocalSandbox {}

///|
/// 创建默认沙箱（全放行）。
pub fn LocalSandbox::new() -> LocalSandbox {
  LocalSandbox::{  }
}

///|
/// execute 直接返回 f（全放行，不审核）。
pub fn LocalSandbox::execute(
  self : LocalSandbox,
  name : String,
  permissions : Array[@perm.Permission],
  f : async (Json) -> @tool.ToolResult noraise,
) -> async (Json) -> @tool.ToolResult noraise {
  // 全放行：直接返回 f，不审核 permissions
  // name/permissions/self 参数未使用但保留以对齐 Sandbox trait 签名
  ignore(self)
  ignore(name)
  ignore(permissions)
  f
}

///|
/// check_permission 全返回 true（全放行）。
pub fn LocalSandbox::check_permission(
  self : LocalSandbox,
  perm : @perm.Permission,
) -> Bool {
  ignore(self)
  ignore(perm)
  true
}

///|
/// check_path 全返回 true（全放行）。
pub fn LocalSandbox::check_path(
  self : LocalSandbox,
  path : String,
  access : @perm.Access,
) -> Bool {
  ignore(self)
  ignore(path)
  ignore(access)
  true
}
