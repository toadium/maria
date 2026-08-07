#include "moonbit.h"

#ifndef _WIN32
#include <stdint.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_fs_readlink(
  moonbit_bytes_t path,
  moonbit_bytes_t buf,
  uint64_t bufsize
) {
  return (int64_t)readlink((const char *)path, (char *)buf, (size_t)bufsize);
}
#else
/* Windows stub: readlink is not available. Returns -1. */
#include <stdint.h>

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_fs_readlink(
  moonbit_bytes_t path,
  moonbit_bytes_t buf,
  uint64_t bufsize
) {
  (void)path;
  (void)buf;
  (void)bufsize;
  return -1;
}
#endif
