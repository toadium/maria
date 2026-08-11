///|
/// R22 v22 r1 Verifier 扩展测试：补充 IdleReaperConfig / IdleReaper
/// 行为契约的边界条件、部分自定义参数、序列化往返、惰性求值、多生命周期循环等用例。

///|
/// IdleReaperConfig 部分自定义：仅覆盖 idle_timeout_ms，reap_interval_ms 保持默认。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_partial_custom_timeout" (t : @test.Test) {
  @mock.run(t, _ => {
    let config = IdleReaperConfig::new(idle_timeout_ms=3600000)
    inspect(config.idle_timeout_ms, content="3600000")
    inspect(config.reap_interval_ms, content="60000")
    inspect(config.idle_timeout_ms(), content="3600000")
    inspect(config.reap_interval_ms(), content="60000")
  })
}

///|
/// IdleReaperConfig 部分自定义：仅覆盖 reap_interval_ms，idle_timeout_ms 保持默认。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_partial_custom_interval" (t : @test.Test) {
  @mock.run(t, _ => {
    let config = IdleReaperConfig::new(reap_interval_ms=120000)
    inspect(config.idle_timeout_ms, content="1800000")
    inspect(config.reap_interval_ms, content="120000")
    inspect(config.idle_timeout_ms(), content="1800000")
    inspect(config.reap_interval_ms(), content="120000")
  })
}

///|
/// IdleReaperConfig ToJson/FromJson 往返：默认配置 + 自定义配置序列化往返一致。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_serialize_roundtrip" (t : @test.Test) {
  @mock.run(t, _ => {
    // 默认配置往返
    let config_default = IdleReaperConfig::new()
    let json_default = config_default.to_json()
    let rt_default : IdleReaperConfig = @json.from_json(json_default)
    inspect(rt_default.idle_timeout_ms, content="1800000")
    inspect(rt_default.reap_interval_ms, content="60000")
    json_inspect(json_default, content={
      "idle_timeout_ms": 1800000,
      "reap_interval_ms": 60000,
    })
    // 自定义配置往返
    let config_custom = IdleReaperConfig::new(
      idle_timeout_ms=600000,
      reap_interval_ms=30000,
    )
    let json_custom = config_custom.to_json()
    let rt_custom : IdleReaperConfig = @json.from_json(json_custom)
    inspect(rt_custom.idle_timeout_ms, content="600000")
    inspect(rt_custom.reap_interval_ms, content="30000")
    json_inspect(json_custom, content={
      "idle_timeout_ms": 600000,
      "reap_interval_ms": 30000,
    })
  })
}

///|
/// IdleReaperConfig 边界值：0 / 1 / 大数（Int 边界）。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_boundary_values" (t : @test.Test) {
  @mock.run(t, _ => {
    // 零值边界
    let config_zero = IdleReaperConfig::new(
      idle_timeout_ms=0,
      reap_interval_ms=0,
    )
    inspect(config_zero.idle_timeout_ms, content="0")
    inspect(config_zero.reap_interval_ms, content="0")
    // 单位值边界
    let config_one = IdleReaperConfig::new(
      idle_timeout_ms=1,
      reap_interval_ms=1,
    )
    inspect(config_one.idle_timeout_ms, content="1")
    inspect(config_one.reap_interval_ms, content="1")
    // 大数边界（24 小时毫秒数 = 86400000）
    let config_large = IdleReaperConfig::new(
      idle_timeout_ms=86400000,
      reap_interval_ms=3600000,
    )
    inspect(config_large.idle_timeout_ms, content="86400000")
    inspect(config_large.reap_interval_ms, content="3600000")
  })
}

///|
/// IdleReaperConfig Debug 输出格式（derive Debug）。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_debug_format" (t : @test.Test) {
  @mock.run(t, _ => {
    let config = IdleReaperConfig::new(
      idle_timeout_ms=600000,
      reap_interval_ms=30000,
    )
    inspect(
      config,
      content="IdleReaperConfig::{idle_timeout_ms: 600000, reap_interval_ms: 30000}",
    )
  })
}

///|
/// IdleReaper start 惰性求值：start 返回 async 函数值，未调用 f(()) 前 is_running() 仍为 false。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_start_lazy_evaluation" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name="test-model")
    let sm_config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      sm_config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    let reaper_config = IdleReaperConfig::new()
    let reaper = IdleReaper::new(manager~, config=reaper_config)
    inspect(reaper.is_running(), content="false")
    // 获取 start 返回的 async 函数值但不调用
    let _f = reaper.start()
    inspect(reaper.is_running(), content="false")
  })
}

///|
/// IdleReaper 多生命周期循环：start → stop → start → stop 多次循环，is_running 状态正确切换。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_multiple_lifecycle_cycles" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name="test-model")
    let sm_config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      sm_config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    let reaper_config = IdleReaperConfig::new()
    let reaper = IdleReaper::new(manager~, config=reaper_config)
    // 循环 1
    let f1 = reaper.start()
    f1(())
    inspect(reaper.is_running(), content="true")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
    // 循环 2
    let f2 = reaper.start()
    f2(())
    inspect(reaper.is_running(), content="true")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
    // 循环 3
    let f3 = reaper.start()
    f3(())
    inspect(reaper.is_running(), content="true")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
  })
}

///|
/// IdleReaper 重复 start 幂等：连续两次 start 后 is_running 仍为 true（占位实现每次设 running = true）。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_repeat_start_idempotent" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name="test-model")
    let sm_config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      sm_config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    let reaper_config = IdleReaperConfig::new()
    let reaper = IdleReaper::new(manager~, config=reaper_config)
    let f1 = reaper.start()
    f1(())
    inspect(reaper.is_running(), content="true")
    let f2 = reaper.start()
    f2(())
    inspect(reaper.is_running(), content="true")
    let f3 = reaper.start()
    f3(())
    inspect(reaper.is_running(), content="true")
  })
}

///|
/// IdleReaper 自定义 config 传入：验证 config 字段在构造后保持正确。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_custom_config_preserved" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name="test-model")
    let sm_config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      sm_config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    let reaper_config = IdleReaperConfig::new(
      idle_timeout_ms=7200000,
      reap_interval_ms=300000,
    )
    let reaper = IdleReaper::new(manager~, config=reaper_config)
    // 验证 config 字段值在 IdleReaper 构造后保持正确
    inspect(reaper_config.idle_timeout_ms, content="7200000")
    inspect(reaper_config.reap_interval_ms, content="300000")
    // start/stop 操作不影响 config
    let f = reaper.start()
    f(())
    inspect(reaper_config.idle_timeout_ms, content="7200000")
    inspect(reaper_config.reap_interval_ms, content="300000")
    reaper.stop()
    inspect(reaper_config.idle_timeout_ms, content="7200000")
    inspect(reaper_config.reap_interval_ms, content="300000")
  })
}

///|
/// IdleReaper stop 在未 start 状态下调用：is_running 保持 false（幂等守卫）。
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_stop_without_start" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name="test-model")
    let sm_config = SessionManagerConfig::new(
      cwd=mock.cwd.path(),
      home=mock.cwd.path(),
      model=model.name,
    )
    let manager = SessionManager::new(
      sm_config~,
      uuid=mock.uuid,
      logger=mock.logger,
      clock=mock.clock,
    )
    let reaper_config = IdleReaperConfig::new()
    let reaper = IdleReaper::new(manager~, config=reaper_config)
    inspect(reaper.is_running(), content="false")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
  })
}
