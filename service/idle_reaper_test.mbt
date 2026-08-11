///|
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_default" (t : @test.Test) {
  @mock.run(t, _ => {
    let config = IdleReaperConfig::new()
    inspect(config.idle_timeout_ms, content="1800000")
    inspect(config.reap_interval_ms, content="60000")
    inspect(config.idle_timeout_ms(), content="1800000")
    inspect(config.reap_interval_ms(), content="60000")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_config_custom" (t : @test.Test) {
  @mock.run(t, _ => {
    let config = IdleReaperConfig::new(
      idle_timeout_ms=600000,
      reap_interval_ms=30000,
    )
    inspect(config.idle_timeout_ms, content="600000")
    inspect(config.reap_interval_ms, content="30000")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_construct_and_is_running" (t : @test.Test) {
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
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "service/idle_reaper_start_stop_idempotent" (t : @test.Test) {
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
    let f = reaper.start()
    f(())
    inspect(reaper.is_running(), content="true")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
    reaper.stop()
    inspect(reaper.is_running(), content="false")
    let f2 = reaper.start()
    f2(())
    inspect(reaper.is_running(), content="true")
  })
}
