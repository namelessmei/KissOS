#include "../include/memory.h"

void* memset(void *s, const int c, size_t count)
{
    uint8_t *xs = s;
    uint8_t b = c;
    if (count < 8)
    {
        while (count--)
            *xs++ = b;
        return s;
    }

    size_t align = -(uintptr_t)xs & (sizeof(size_t) - 1);
    count -= align;
    while (align--)
        *xs++ = b;

    size_t pattern = (b << 24) | (b << 16) | (b << 8) | b;
    pattern = (pattern << 32) | pattern;

    size_t *xw = (size_t *)xs;
    while (count >= sizeof(size_t))
    {
        *xw++ = pattern;
        count -= sizeof(size_t);
    }

    xs = (uint8_t *)xw;
    while (count--)
        *xs++ = b;

    return s;
}

void* memcpy(void *dest, const void *src, size_t count)
{
    uint8_t *d = dest;
    const uint8_t *s = src;
    if (count < 8)
    {
        while (count--)
            *d++ = *s++;
        return dest;
    }

    size_t align = -(uintptr_t)d & (sizeof(size_t)-1);
    count -= align;
    while (align--)
        *d++ = *s++;

    size_t *dw = (size_t *)d;
    const size_t *sw = (const size_t *)s;

    while (count >= sizeof(size_t))
    {
        *dw++ = *sw++;
        count -= sizeof(size_t);
    }

    d = (uint8_t *)dw;
    s = (const uint8_t *)sw;
    while (count--)
        *d++ = *s++;

    return dest;
}

int memcmp(const void *cs, const void *ct, size_t count)
{
    const uint8_t *s1 = cs;
    const uint8_t *s2 = ct;
    if (count < 8)
    {
        while (count--)
        {
            if (*s1 != *s2)
                return *s1 - *s2;
            s1++;
            s2++;
        }
        return 0;
    }

    size_t align = -(uintptr_t)s1 & (sizeof(size_t)-1);
    count -= align;
    while (align--)
    {
        if (*s1 != *s2)
            return *s1 - *s2;
        s1++;
        s2++;
    }

    const size_t *w1 = (const size_t *)s1;
    const size_t *w2 = (const size_t *)s2;
    while (count >= sizeof(size_t))
    {
        if (*w1 != *w2)
        {
            s1 = (const uint8_t *)w1;
            s2 = (const uint8_t *)w2;
            for (size_t i = 0; i < sizeof(size_t); i++)
            {
                if (s1[i] != s2[i])
                    return s1[i] - s2[i];
            }
        }
        w1++;
        w2++;
        count -= sizeof(size_t);
    }

    s1 = (const uint8_t *)w1;
    s2 = (const uint8_t *)w2;
    while (count--)
    {
        if (*s1 != *s2)
            return *s1 - *s2;
        s1++;
        s2++;
    }

    return 0;
}

void* memmove(void *dest, const void *src, size_t count)
{
    uint8_t *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;

    if (d == s || count == 0)
        return dest;

    if (d > s && d < s + count)
    {
        d += count;
        s += count;

        if (count >= 8)
        {
            size_t align = (uintptr_t)d & (sizeof(size_t) - 1);
            count -= align;
            while (align--)
                *--d = *--s;

            size_t *dw = (size_t *)d;
            const size_t *sw = (const size_t *)s;

            while (count >= sizeof(size_t))
            {
                *--dw = *--sw;
                count -= sizeof(size_t);
            }

            d = (uint8_t *)dw;
            s = (const uint8_t *)sw;
        }

        while (count--)
            *--d = *--s;
    }
    else
    {
        if (count >= 8)
        {
            size_t align = -(uintptr_t)d & (sizeof(size_t) - 1);
            count -= align;
            while (align--)
                *d++ = *s++;

            size_t *dw = (size_t *)d;
            const size_t *sw = (const size_t *)s;

            while (count >= sizeof(size_t))
            {
                *dw++ = *sw++;
                count -= sizeof(size_t);
            }

            d = (uint8_t *)dw;
            s = (const uint8_t *)sw;
        }

        while (count--)
            *d++ = *s++;
    }

    return dest;
}
