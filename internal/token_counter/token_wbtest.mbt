///|
test "token_counter/count_string empty" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // Empty string: only system overhead
  inspect(counter.count_string(""), content="7")
}

///|
test "token_counter/count_string basic" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // "hello world" has 2 tokens with cl100k_base + 7 overhead
  let count = counter.count_string("hello world")
  inspect(count > 7, content="true")
}

///|
test "token_counter/count_message user" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  let msg = @openai.user_message(content="Hello, how are you?")
  let count = counter.count_message(msg)
  inspect(count > 0, content="true")
}

///|
test "token_counter/count_message system" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  let msg = @openai.system_message(content="You are a helpful assistant.")
  let count = counter.count_message(msg)
  inspect(count > 0, content="true")
}

///|
test "token_counter/count_message tool" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  let msg = @openai.tool_message(content="Result: 42", tool_call_id="call_123")
  let count = counter.count_message(msg)
  inspect(count > 0, content="true")
}

///|
test "token_counter/calibrate zero estimated no update" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // calibrate with zero estimated_tokens should not update
  counter.calibrate(
    model_name="test-model",
    estimated_tokens=0,
    actual_tokens=100,
  )
  let result = counter.apply_calibration(model_name="test-model", raw_count=100)
  // Factor should still be default 1.0
  inspect(result, content="100")
}

///|
test "token_counter/apply_calibration unknown model" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // Unknown model should use default factor 1.0
  let result = counter.apply_calibration(model_name="unknown", raw_count=200)
  inspect(result, content="200")
}

///|
test "token_counter/calibrate and apply" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // Estimate 100, actual 120 → ratio 1.2, alpha 0.3
  // new_factor = 0.3 * 1.2 + 0.7 * 1.0 = 0.36 + 0.7 = 1.06
  counter.calibrate(
    model_name="test-model",
    estimated_tokens=100,
    actual_tokens=120,
  )
  let result = counter.apply_calibration(model_name="test-model", raw_count=100)
  // 100 * 1.06 = 106
  inspect(result, content="106")
}

///|
test "token_counter/calibrate clamps to 2.0" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // Estimate 10, actual 100 → ratio 10.0, alpha 0.3
  // new_factor = 0.3 * 10.0 + 0.7 * 1.0 = 3.7, clamped to 2.0
  counter.calibrate(
    model_name="test-model",
    estimated_tokens=10,
    actual_tokens=100,
  )
  let result = counter.apply_calibration(model_name="test-model", raw_count=100)
  // 100 * 2.0 = 200
  inspect(result, content="200")
}

///|
test "token_counter/calibrate clamps to 0.5" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let counter = Counter::new(logger~)
  // Estimate 100, actual 1 → ratio 0.01, alpha 0.3
  // new_factor = 0.3 * 0.01 + 0.7 * 1.0 = 0.703, not clamped
  // Let's try more extreme: estimate 1000, actual 1
  // ratio = 0.001, new_factor = 0.3 * 0.001 + 0.7 = 0.7003, still not clamped
  // Need multiple iterations to reach 0.5
  counter.calibrate(model_name="m", estimated_tokens=1000, actual_tokens=1)
  counter.calibrate(model_name="m", estimated_tokens=1000, actual_tokens=1)
  counter.calibrate(model_name="m", estimated_tokens=1000, actual_tokens=1)
  counter.calibrate(model_name="m", estimated_tokens=1000, actual_tokens=1)
  counter.calibrate(model_name="m", estimated_tokens=1000, actual_tokens=1)
  let result = counter.apply_calibration(model_name="m", raw_count=100)
  // Should be clamped to 0.5 → 100 * 0.5 = 50
  inspect(result, content="50")
}
