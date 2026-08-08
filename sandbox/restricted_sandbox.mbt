///|
/// 受限沙箱，基于白名单/黑名单前缀匹配审核权限。
pub struct RestrictedSandbox {
  priv config : SandboxConfig
  priv normalized_whitelist : Array[String]
  priv normalized_blacklist : Array[String]
}

///|
/// 创建受限沙箱。
///
/// 遍历 config.path_whitelist 和 config.path_blacklist，调用 `@fsx.resolve`
/// 预规范化每个条目（解析 `.`/`..`、符号链接），存入 normalized_whitelist/
/// normalized_blacklist 供 `check_path` 同步前缀匹配。
///
/// **约定**：config.path_whitelist 和 config.path_blacklist 中的路径须存在。
/// `@fsx.resolve` 对不存在路径会触发运行时 panic（`@fs.realpath` raise OSError）。
pub async fn RestrictedSandbox::new(
  config : SandboxConfig,
) -> RestrictedSandbox {
  let normalized_whitelist = []
  for entry in config.path_whitelist {
    // async 上下文中直接调用 async fn，无需 await 关键字
    normalized_whitelist.push(@fsx.resolve(entry))
  }
  let normalized_blacklist = []
  for entry in config.path_blacklist {
    normalized_blacklist.push(@fsx.resolve(entry))
  }
  RestrictedSandbox::{ config, normalized_whitelist, normalized_blacklist }
}

///|
/// execute 遍历 permissions 调用 check_permission 审核，全通过返回 f，否则返回常量 async 函数值。
pub fn RestrictedSandbox::execute(
  self : RestrictedSandbox,
  name : String,
  permissions : Array[@perm.Permission],
  f : async (Json) -> @tool.ToolResult noraise,
) -> async (Json) -> @tool.ToolResult noraise {
  // 遍历 permissions 审核，任一失败则返回常量 async 函数值
  // 空 permissions 边界：遍历不执行，隐含全通过返回 f
  for perm in permissions {
    if !self.check_permission(perm) {
      return fn(_) {
        @tool.ToolResult::failed("permission denied for tool \{name}")
      }
    }
  }
  f
}

///|
/// check_permission 审核逻辑：PathAccess 委托 check_path；CommandExecution 返回 config.command_enabled；NetworkAccess 返回 false。
pub fn RestrictedSandbox::check_permission(
  self : RestrictedSandbox,
  perm : @perm.Permission,
) -> Bool {
  match perm {
    @perm.PathAccess(path, access) => self.check_path(path, access)
    @perm.CommandExecution(_command) => self.config.command_enabled
    @perm.NetworkAccess(_url) => false
  }
}

///|
/// check_path 基于预规范化白名单/黑名单做同步前缀匹配（黑名单优先，默认拒绝）。
pub fn RestrictedSandbox::check_path(
  self : RestrictedSandbox,
  path : String,
  _access : @perm.Access,
) -> Bool {
  // 输入 path 须为规范化路径（调用方在 async 上下文中先调用 @fsx.resolve 规范化）
  // check_path 内部仅做同步前缀匹配，不负责路径规范化
  // 跨平台分隔符统一化：将 \ 统一替换为 / 后做前缀匹配
  // _access 未使用：P0 阶段路径审核不区分 Read/Write/Execute，保留参数以对齐 Sandbox trait 签名
  let normalized_path = normalize_sep(path)
  // 黑名单优先：先查黑名单匹配返回 false
  for entry in self.normalized_blacklist {
    if path_prefix_match(normalized_path, normalize_sep(entry)) {
      return false
    }
  }
  // 再查白名单匹配返回 true
  for entry in self.normalized_whitelist {
    if path_prefix_match(normalized_path, normalize_sep(entry)) {
      return true
    }
  }
  // 均不匹配返回 false（默认拒绝）
  false
}
