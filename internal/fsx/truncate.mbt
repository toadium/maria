///|
#cfg(not(platform="windows"))
extern "c" fn fsx_ftruncate(fd : Int, length : Int64) -> Int = "moonbit_maria_fsx_ftruncate"

///|
/// Truncate `file` to the given `length` in bytes.
///
/// On failure this raises an `@errno.Errno` populated from `@errno.get()`.
#cfg(not(platform="windows"))
pub fn truncate(file : @fs.File, length : Int64) -> Unit raise {
  let result = fsx_ftruncate(file.fd(), length)
  if result != 0 {
    raise @errno.Errno(@errno.get())
  }
}

///|
#cfg(platform="windows")
pub fn truncate(file : @fs.File, length : Int64) -> Unit raise {
  ignore(file.fd())
  ignore(length)
  raise @errno.Errno(@errno.enotty)
}
