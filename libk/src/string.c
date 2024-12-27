#define ONES (~0UL / 0xFF)
#define HIGHS (ONES * 0x80)
#define HAS_ZERO(x) (((x) - ONES) & ~(x) & HIGHS)

#include "../include/string.h"

size_t strlen(const char *str)
{
    const char *s = str;
    size_t *ls;
    if ((size_t)s & (sizeof(size_t) - 1))
    {
        while ((size_t)s & (sizeof(size_t) - 1))
        {
            if (!*s)
                return s - str;
            s++;
        }
    }

    ls = (size_t *)s;
    while (!HAS_ZERO(*ls)) ls++;

    s = (const char *)ls;
    while (*s)
        s++;

    return s - str;
}

size_t strnlen(const char *s, size_t maxlen)
{
    const char *es = s;
    while (*es && maxlen)
    {
        es++;
        maxlen--;
    }
    return es - s;
}

char *strcpy(char *dest, const char *src)
{
    char *ret = dest;
    size_t *ldest, *lsrc;

    while ((size_t)src & (sizeof(long) - 1))
    {
        if (!(*dest = *src))
            return ret;
        dest++; src++;
    }

    ldest = (size_t *)dest;
    lsrc = (size_t *)src;
    while (!HAS_ZERO(*lsrc))
        *ldest++ = *lsrc++;

    dest = (char *)ldest;
    src = (char *)lsrc;
    while ((*dest++ = *src++) != '\0');

    return ret;
}

char *strncpy(char *dest, const char *src, size_t n)
{
    char *d = dest;
    while (n && (*d = *src))
    {
        d++;
        src++;
        n--;
    }
    while (n--) *d++ = 0;
    return dest;
}

size_t strlcpy(char *dest, const char *src, size_t size)
{
    const char *s = src;
    size_t n = size;
    if (n != 0 && --n != 0)
    {
        do
        {
            if ((*dest++ = *s++) == 0)
                break;
        }
        while (--n != 0);
    }

    if (n == 0)
    {
        if (size != 0)
            *dest = '\0';
        while (*s++);
    }

    return s - src - 1;
}

char *strcat(char *dest, const char *src)
{
    char *tmp = dest;
    while (*tmp)
        tmp++;

    while ((*tmp++ = *src++) != '\0');

    return dest;
}

char *strncat(char *dest, const char *src, size_t n)
{
    char *tmp = dest;
    while (*tmp)
        tmp++;

    while (n-- > 0 && (*tmp = *src) != '\0')
    {
        tmp++;
        src++;
    }

    *tmp = '\0';
    return dest;
}

size_t strlcat(char *dest, const char *src, size_t size)
{
    const char *s = src;
    char *d = dest;
    size_t n = size;
    size_t dlen;
    while (n-- != 0 && *d != '\0')
        d++;
    dlen = d - dest;
    n = size - dlen;

    if (n == 0)
        return dlen + strlen(s);

    while (*s != '\0')
    {
        if (n != 1)
        {
            *d++ = *s;
            n--;
        }
        s++;
    }
    *d = '\0';

    return dlen + (s - src);
}

int strcmp(const char *s1, const char *s2)
{
    while ((size_t)s1 & (sizeof(size_t) - 1))
    {
        if (*s1 != *s2)
            return ((unsigned char)*s1) - ((unsigned char)*s2);
        if (!*s1)
            return 0;
        s1++; s2++;
    }

    size_t *ls1 = (size_t *)s1;
    size_t *ls2 = (size_t *)s2;
    while (!HAS_ZERO(*ls1) && *ls1 == *ls2)
    {
        ls1++;
        ls2++;
    }

    s1 = (const char *)ls1;
    s2 = (const char *)ls2;
    while (*s1 && *s1 == *s2)
    {
        s1++;
        s2++;
    }
    return ((uint8_t)*s1) - ((uint8_t)*s2);
}

int strncmp(const char *s1, const char *s2, size_t n)
{
    unsigned char c1;
    unsigned char c2;
    while (n)
    {
        c1 = *s1++;
        c2 = *s2++;
        if (c1 != c2)
            return c1 - c2;
        if (!c1)
            break;
        n--;
    }
    return 0;
}

int strcasecmp(const char *s1, const char *s2)
{
    unsigned char c1, c2;

    do
    {
        c1 = (*s1++ | 0x20);
        c2 = (*s2++ | 0x20);
        if (c1 == '\0')
            return c1 - c2;
    }
    while (c1 == c2);

    return c1 - c2;
}

int strncasecmp(const char *s1, const char *s2, size_t len)
{
    unsigned char c1, c2;

    if (!len)
        return 0;

    do
    {
        c1 = (*s1++ | 0x20);
        c2 = (*s2++ | 0x20);
        if (!--len)
            return c1 - c2;
        if (c1 == '\0')
            return c1 - c2;
    }
    while (c1 == c2);

    return c1 - c2;
}

char *strchr(const char *s, int c)
{
    uint8_t ch = (uint8_t)c;
    if (!ch)
    {
        while (*s)
            s++;
        return (char *)s;
    }

    while (*s && *s != ch)
        s++;
    return *s == ch ? (char *)s : NULL;
}

char *strrchr(const char *s, int c)
{
    const char *last = NULL;

    do
    {
        if (*s == (char)c)
            last = s;
    }
    while (*s++);

    return (char *)last;
}

char *strnchr(const char *s, size_t count, int c)
{
    while (count--)
    {
        if (*s == (char)c)
            return (char *)s;
        if (*s++ == '\0')
            break;
    }
    return NULL;
}

char *strnstr(const char *s1, const char *s2, size_t len)
{
    size_t l2 = strlen(s2);

    if (!l2)
        return (char *)s1;

    while (len >= l2)
    {
        size_t i;
        bool match = true;

        for (i = 0; i < l2; i++)
        {
            if (s1[i] != s2[i])
            {
                match = false;
                break;
            }
        }

        if (match)
            return (char *)s1;

        s1++;
        len--;
    }
    return NULL;
}

char *strstr(const char *haystack, const char *needle)
{
    const char first = *needle;
    if (first == '\0')
        return (char *)haystack;

    while (*haystack)
    {
        if (*haystack == first)
        {
            const char *h = haystack + 1;
            const char *n = needle + 1;

            while (*n && *h == *n)
            {
                h++;
                n++;
            }

            if (*n == '\0')
                return (char *)haystack;
        }
        haystack++;
    }

    return NULL;
}
