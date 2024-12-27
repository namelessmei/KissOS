#ifndef __KISSOS__MEMORY__LIBK__
#define __KISSOS__MEMORY__LIBK__

#include "stddef.h"

void* memset(void *s, int c, size_t count);
void* memcpy(void *dest, const void *src, size_t count);
void* memmove(void *dest, const void *src, size_t count);
int memcmp(const void *cs, const void *ct, size_t count);

#endif
