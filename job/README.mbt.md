# job

Background job management — spawn, track, and wait for subprocess jobs.

## API

```mbt nocheck
///|
pub struct Manager {
  // job tracking state
}

///|
pub fn Manager::new() -> Manager

///|
pub fn Manager::spawn(
  self : Manager,
  command : String,
  args : Array[String],
  timeout~ : Int? = None,
) -> JobId raise JobError

///|
pub fn Manager::status(self : Manager, id : JobId) -> JobStatus

///|
pub fn Manager::wait(self : Manager, id : JobId) -> JobResult raise JobError

///|
pub fn Manager::list(self : Manager) -> Array[JobInfo]
```

## Job Status

```mbt nocheck
///|
pub(all) enum JobStatus {
  Running
  Completed(JobResult)
  Failed(JobError)
  Timeout
}
```