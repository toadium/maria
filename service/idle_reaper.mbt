///|
/// 多会话空闲超时与自动回收（AgentScope 2.0 Scalable Deployment 资源回收扩展点预留）。
///
/// P2 预留：仅 struct 定义 + 骨架方法 + 构造函数 + 注释 + mock 测试，
/// 不实现具体定时器/扫描逻辑（后续实现时添加）。
///
/// 参考 AgentScope 2.0 多会话空闲超时与自动回收，
/// 自动回收路径骨架：周期性扫描 sessions → last_active + idle_timeout_ms < now → close_session(id)。
/// 本步仅定义抽象类型 + 骨架方法不实现具体定时器/扫描逻辑，
/// 后续完整实现时复用 @async task spawn 周期 task + SessionManager::list_sessions + SessionManager::close_session。
///
/// 本步不引入 @async.sleep/@clock.Clock 新依赖以保持 P2 预留最小化（IdleReaper::start 骨架仅设 running = true 占位，不实际 spawn task）。

///|
/// 空闲超时与自动回收配置。
///
/// idle_timeout_ms：空闲超时毫秒数，默认 1800000（30 分钟）。
/// reap_interval_ms：回收扫描间隔毫秒数，默认 60000（60 秒）。
pub(all) struct IdleReaperConfig {
  idle_timeout_ms : Int
  reap_interval_ms : Int
} derive(ToJson, FromJson, Debug)

///|
/// 构造 IdleReaperConfig，默认 idle_timeout_ms=1800000（30 分钟）, reap_interval_ms=60000（60 秒）。
pub fn IdleReaperConfig::new(
  idle_timeout_ms? : Int = 1800000,
  reap_interval_ms? : Int = 60000,
) -> IdleReaperConfig {
  IdleReaperConfig::{ idle_timeout_ms, reap_interval_ms }
}

///|
pub fn IdleReaperConfig::idle_timeout_ms(self : IdleReaperConfig) -> Int {
  self.idle_timeout_ms
}

///|
pub fn IdleReaperConfig::reap_interval_ms(self : IdleReaperConfig) -> Int {
  self.reap_interval_ms
}

///|
/// 空闲超时与自动回收器骨架，持有 SessionManager 引用 + 配置 + running 幂等守卫。
///
/// P2 预留：start/stop/is_running 为骨架实现，不实际 spawn 周期 task / 扫描 sessions / 回收空闲会话。
/// 后续完整实现时：(a) start 内部 @async task spawn 周期 task（@async.sleep(reap_interval_ms) → list_sessions → 过滤 last_active + idle_timeout_ms < now → close_session）+ 幂等守卫；(b) stop 内部设 running = false + 定时 task 自动退出。
#warnings("-unused_field")
pub struct IdleReaper {
  priv manager : SessionManager
  priv config : IdleReaperConfig
  priv mut running : Bool
}

///|
/// 构造 IdleReaper，持有 SessionManager 引用 + IdleReaperConfig 配置，running 初始为 false。
pub fn IdleReaper::new(
  manager~ : SessionManager,
  config~ : IdleReaperConfig,
) -> IdleReaper {
  IdleReaper::{ manager, config, running: false }
}

///|
/// 启动自动回收循环（骨架预留）。
///
/// P2 预留：返回 async 函数值，内部仅设 running = true 占位，不实际 spawn 周期 task。
/// 后续完整实现时 spawn @async 周期 task 执行扫描 + 回收。
pub fn IdleReaper::start(self : IdleReaper) -> async (Unit) -> Unit {
  _ => self.running = true
}

///|
/// 停止自动回收循环（幂等守卫）。
///
/// 同步方法，设 self.running = false。
/// P2 预留：不实际停止定时 task，仅设标志位。
/// 后续完整实现时设 running = false + 定时 task 自动退出。
pub fn IdleReaper::stop(self : IdleReaper) -> Unit {
  self.running = false
}

///|
/// 查询回收器是否正在运行。
///
/// 同步方法，返回 self.running。
pub fn IdleReaper::is_running(self : IdleReaper) -> Bool {
  self.running
}
