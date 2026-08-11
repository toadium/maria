# file

File management — safe file operations within a working directory boundary.

## API

```mbt nocheck
///|
pub struct Manager {
  cwd : String
}

///|
pub fn Manager::new(cwd~ : String) -> Manager

///|
pub fn Manager::read(self : Manager, path : String) -> String raise FileError

///|
pub fn Manager::write(self : Manager, path : String, content : String) -> Unit raise FileError

///|
pub fn Manager::list(self : Manager, path : String) -> Array[Entry] raise FileError
```

All paths are resolved relative to `cwd`. Path traversal (`../`) is rejected to prevent access outside the working directory boundary.