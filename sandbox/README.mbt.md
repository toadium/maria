# sandbox

Tool sandboxing — permission-based execution isolation for agent tools.

## Overview

- `Sandbox` trait: `check_permission(perm) -> Bool` + `execute(command, permissions) -> async Output`
- `LocalSandbox`: full local execution, all permissions granted
- `RestrictedSandbox`: configurable permission whitelist + working directory restriction
- `Permission` / `Access` enums: declarative capability model

## Permission Model

```mbt nocheck
///|
pub(all) enum Permission {
  FileAccess(path : String, access : Access)
  NetworkAccess(host : String, port : Int)
  Subprocess
  EnvAccess
}

///|
pub(all) enum Access {
  Read
  Write
  Execute
}
```

## Usage

```mbt nocheck
///|
let sandbox = @sandbox.LocalSandbox::5
let result = sandbox.execute("ls", [], [])

///|
let restricted = @sandbox.RestrictedSandbox::new(cwd="/tmp", allowed_permissions=[
  @perm.Permission::FileAccess("/tmp", @perm.Access::Write),
])
```

## Sandbox Trait

```mbt nocheck
///|
pub(open) trait Sandbox {
  fn check_permission(self : Self, perm : @perm.Permission) -> Bool
  fn execute(
    self : Self,
    command : String,
    args : Array[String],
    permissions : Array[@perm.Permission],
  ) -> async (Unit) -> Output raise SandboxError
}
```