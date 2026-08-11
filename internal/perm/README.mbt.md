# internal/perm

Permission model — declarative capability definitions for tool sandboxing.

## Overview

- `Permission` enum: `FileAccess(path, access)` / `NetworkAccess(host, port)` / `Subprocess` / `EnvAccess`
- `Access` enum: `Read` / `Write` / `Execute`
- Derives `ToJson` / `FromJson` / `Debug` / `Eq`

## Usage

```mbt nocheck
///|
let perm = @perm.Permission::FileAccess("/tmp", @perm.Access::Write)
let json = perm.to_json()
let restored : @perm.Permission = @json.from_json(json)
assert_eq(restored, perm)
```

## API Reference

```mbt nocheck
///|
pub(all) enum Permission {
  FileAccess(String, Access)
  NetworkAccess(String, Int)
  Subprocess
  EnvAccess
} derive(ToJson, FromJson, Debug, Eq)

///|
pub(all) enum Access {
  Read
  Write
  Execute
} derive(ToJson, FromJson, Debug, Eq)
```