#ifndef __KISSOS__STDSTRING__LIBK__
#define __KISSOS__STDSTRING__LIBK__

#include "stddef.h"

size_t strlen(const char *s);
size_t strnlen(const char *s, size_t maxlen);

char *strcpy(char *dest, const char *src);
char *strncpy(char *dest, const char *src, size_t count);
size_t strlcpy(char *dest, const char *src, size_t size);

char *strcat(char *dest, const char *src);
char *strncat(char *dest, const char *src, size_t count);
size_t strlcat(char *dest, const char *src, size_t size);

int strcmp(const char *cs, const char *ct);
int strncmp(const char *cs, const char *ct, size_t count);
int strcasecmp(const char *s1, const char *s2);
int strncasecmp(const char *s1, const char *s2, size_t len);

char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);
char *strnchr(const char *s, size_t count, int c);
char *strstr(const char *s1, const char *s2);
char *strnstr(const char *s1, const char *s2, size_t len);

#endif
