///|
pub struct InteractiveProcess {
  priv stdin : @process.WriteToProcess
  priv stdout : @process.ReadFromProcess
  priv process : @process.Process
  priv mut closed : Bool
}

///|
pub async fn[X] spawn_interactive(
  tg : @async.TaskGroup[X],
  command : StringView,
  arguments : Array[StringView],
  cwd? : StringView,
  env? : Map[String, String],
) -> InteractiveProcess {
  let (stdin_input, stdin_write) = @process.write_to_process()
  let (stdout_read, stdout_output) = @process.read_from_process() catch {
    error => {
      stdin_write.close()
      raise error
    }
  }
  let args_view = arguments.map(s => "\{s}")
  let process = @process.spawn(
    tg,
    command,
    args_view,
    stdin=stdin_input,
    stdout=stdout_output,
    cwd?,
    extra_env?=env,
    no_wait=true,
  )
  InteractiveProcess::{
    stdin: stdin_write,
    stdout: stdout_read,
    process,
    closed: false,
  }
}

///|
pub async fn InteractiveProcess::write(
  self : InteractiveProcess,
  data : String,
) -> Unit {
  self.stdin.write(data)
}

///|
pub async fn InteractiveProcess::read_line(
  self : InteractiveProcess,
) -> String? {
  match self.stdout.read_until("\n") {
    None => None
    Some(s) => {
      let s = match s.strip_suffix("\r") {
        Some(view) => "\{view}"
        None => s
      }
      Some(s)
    }
  }
}

///|
pub async fn InteractiveProcess::wait(self : InteractiveProcess) -> Int {
  self.process.wait()
}

///|
pub fn InteractiveProcess::close(self : InteractiveProcess) -> Unit {
  if !self.closed {
    self.stdin.close()
    self.stdout.close()
    self.closed = true
  }
}

///|
pub fn InteractiveProcess::pid(self : InteractiveProcess) -> Int {
  self.process.pid
}
