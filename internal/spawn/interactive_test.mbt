///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/sh_roundtrip" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "sh", ["-c", "read x; echo $x"])
    ip.write("hello\n")
    let line = ip.read_line()
    assert_eq(line, Some("hello"))
    let eof = ip.read_line()
    assert_eq(eof, None)
    let status = ip.wait()
    assert_eq(status, 0)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/printf_crlf" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "sh", ["-c", "printf 'hello\r\n'"])
    let line = ip.read_line()
    assert_eq(line, Some("hello"))
    let eof = ip.read_line()
    assert_eq(eof, None)
    let status = ip.wait()
    assert_eq(status, 0)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/echo_single" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "echo", ["hello"])
    let line = ip.read_line()
    assert_eq(line, Some("hello"))
    let eof = ip.read_line()
    assert_eq(eof, None)
    let status = ip.wait()
    assert_eq(status, 0)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/exit_code" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "sh", ["-c", "exit 42"])
    let status = ip.wait()
    assert_eq(status, 42)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/close_idempotent" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "cat", [])
    ip.close()
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/pid_positive" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "cat", [])
    assert_true(ip.pid() > 0)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/empty_line_vs_eof" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "sh", ["-c", "printf '\n'"])
    let line = ip.read_line()
    assert_eq(line, Some(""))
    let eof = ip.read_line()
    assert_eq(eof, None)
    let status = ip.wait()
    assert_eq(status, 0)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/wait_idempotent" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "sh", ["-c", "exit 7"])
    let status1 = ip.wait()
    let status2 = ip.wait()
    assert_eq(status1, 7)
    assert_eq(status2, 7)
    ip.close()
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/close_then_wait" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "sh", ["-c", "exit 0"])
    ip.close()
    let status = ip.wait()
    assert_eq(status, 0)
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/write_after_close_raises" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "cat", [])
    ip.close()
    try ip.write("data\n") catch {
      _ => ()
    } noraise {
      _ => fail("expected write after close to raise")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/read_line_after_close_raises" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(mock.group, "cat", [])
    ip.close()
    try ip.read_line() catch {
      _ => ()
    } noraise {
      _ => fail("expected read_line after close to raise")
    }
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "interactive/env_param" (t : @test.Test) {
  @mock.run(t, mock => {
    let ip = spawn_interactive(
      mock.group,
      "sh",
      ["-c", "echo $INTERACTIVE_TEST_VAR"],
      env={ "INTERACTIVE_TEST_VAR": "env_value" },
    )
    let line = ip.read_line()
    assert_eq(line, Some("env_value"))
    let eof = ip.read_line()
    assert_eq(eof, None)
    let status = ip.wait()
    assert_eq(status, 0)
    ip.close()
  })
}
