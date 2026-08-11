# internal/spawn

Interactive process spawning — `InteractiveProcess` for subprocess communication.

## Overview

- `InteractiveProcess`: holds a child process with stdin/stdout pipes
- `spawn_interactive(command, args)`: spawns a subprocess and returns `InteractiveProcess`
- Methods: `write(data)` / `read_line() -> String?` / `close()`
- `closed` flag: idempotent close guard

## Usage

```mbt nocheck
///|
let proc = @spawn.spawn_interactive("python", ["-u", "-i"])
proc.write("print('hello')\n")
guard proc.read_line() is Some(line) else {
  fail("expected output")
}
inspect(line, content="hello")
proc.close()
```

## API Reference

```mbt nocheck
///|
pub struct InteractiveProcess {
  write_fd : Int
  read_fd : Int
  pid : Int
  mut closed : Bool
}

///|
pub fn spawn_interactive(
  command : String,
  args : Array[String],
) -> InteractiveProcess raise SpawnError

///|
pub fn InteractiveProcess::write(
  self : InteractiveProcess,
  data : String,
) -> Unit

///|
pub fn InteractiveProcess::read_line(
  self : InteractiveProcess,
) -> String?

///|
pub fn InteractiveProcess::close(
  self : InteractiveProcess,
) -> Unit
```

## Integration

Used by `@mcp.StdioTransport` to communicate with MCP server subprocesses via stdin/stdout.