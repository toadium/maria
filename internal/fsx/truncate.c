#include <moonbit.h>

#ifdef _WIN32
// Windows stub: ftruncate not available
MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_fsx_ftruncate(int32_t fd, int64_t length) {
  return -1;
}
#else
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_fsx_ftruncate(int32_t fd, int64_t length) {
  return ftruncate(fd, length);
}
#endif
