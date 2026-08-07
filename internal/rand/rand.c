#include "moonbit.h"

#ifndef _WIN32
#include <errno.h>
#include <sys/random.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_rand_bytes(moonbit_bytes_t buf) {
  int32_t result = getentropy(buf, Moonbit_array_length(buf));
  if (result == -1) {
    return errno;
  } else {
    return 0;
  }
}
#else
/* Windows fallback: use rand() to fill the buffer. */
#include <stdlib.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_rand_bytes(moonbit_bytes_t buf) {
  uint32_t len = Moonbit_array_length(buf);
  for (uint32_t i = 0; i < len; i++) {
    buf[i] = (unsigned char)rand();
  }
  return 0;
}
#endif
