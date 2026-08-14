///|
/// 多会话空闲超时与自动回收（AgentScope 2.0 Scalable Deployment 资源回收）。
///
/// R23 实现：IdleReaper 持有 SessionManager 引用 + Clock 引用 + 配置 + running 守卫。
/// start 方法启动周期性扫描循环：sleep(reap_interval_ms) → list_sessions →
/// 过滤 last_active + idle_timeout_ms < now → close_session(id)。
/// stop 方法设 running = false，循环自动退出。
///
/// 注意：start 返回的 async 函数会阻塞直到 stop 被调用，
/// 调用方应在独立 task 中运行 start（如 spawn_bg）。

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
/// 空闲超时与自动回收器，持有 SessionManager 引用 + Clock 引用 + 配置 + running 守卫。
#warnings("-unused_field")
pub struct IdleReaper {
  priv manager : SessionManager
  priv config : IdleReaperConfig
  priv clock : &@clock.Clock
  priv mut running : Bool
}

///|
/// 构造 IdleReaper，持有 SessionManager 引用 + IdleReaperConfig 配置 + Clock 引用，running 初始为 false。
pub fn IdleReaper::new(
  manager~ : SessionManager,
  config~ : IdleReaperConfig,
  clock~ : &@clock.Clock,
) -> IdleReaper {
  IdleReaper::{ manager, config, clock, running: false }
}

///|
/// 启动自动回收循环。
///
/// 返回 async 函数值，内部循环：sleep(reap_interval_ms) → list_sessions →
/// 过滤空闲会话 → close_session。stop 设 running=false 后循环退出。
///
/// 注意：此函数会阻塞直到 stop 被调用，应在独立 task 中运行。
pub fn IdleReaper::start(self : IdleReaper) -> async (Unit) -> Unit {
  _ => {
    self.running = true
    for ;; {
      if not(self.running) {
        break
      }
      @async.sleep(self.config.reap_interval_ms)
      if not(self.running) {
        break
      }
      try {
        let sessions = self.manager.list_sessions()
        let now = self.clock.now()
        for session in sessions {
          let idle_ms = now.ms_since(session.last_active)
          if idle_ms > self.config.idle_timeout_ms {
            ignore(self.manager.close_session(session.id)) catch {
              _ => ()
            }
          }
        }
      } catch {
        _ => ()
      }
    }
  }
}

///|
/// 停止自动回收循环（幂等守卫）。
///
/// 设 self.running = false，start 循环在下一次迭代时退出。
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
