///|
/// 不可变值对象，描述沙箱配置（路径白名单/黑名单、命令开关、cwd）。
pub(all) struct SandboxConfig {
  path_whitelist : Array[String]
  path_blacklist : Array[String]
  command_enabled : Bool
  cwd : String
} derive(Eq, Debug, ToJson, FromJson)
