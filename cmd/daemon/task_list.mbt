///|
/// Holds a list of tasks that shares the same working directory (cwd).
///
/// This is necessary because we might have 1 running task and potentially have
/// many stopped tasks that shares the same cwd. This struct helps to group them
/// together and enforcing the invariant that at most 1 running task exists in
/// the list.
priv struct TaskLock {
  /// Mutex to synchronize spawning of new tasks.
  ///
  /// Life cycle:
  ///
  /// 1. Check if a running task exists without acquiring the mutex.
  /// 2. Acquire `spawn_mutex` before spawning a new task.
  /// 3. Spawn the task process.
  /// 4. Register the task in `running` field.
  /// 5. Release `spawn_mutex`.
  ///
  /// MoonBit's single-threaded async runtime ensures semaphore is sufficient
  /// for mutual exclusion. A `Mutex[T]` wrapper would be more idiomatic but
  /// is not strictly necessary here.
  spawn_mutex : @semaphore.Semaphore
  mut running : Running?
}

///|
fn TaskLock::new() -> TaskLock {
  TaskLock::{ spawn_mutex: @semaphore.Semaphore::new(1), running: None }
}
