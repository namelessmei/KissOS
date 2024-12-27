#ifndef __KISSOS__STDIO__LIBK__
#define __KISSOS__STDIO__LIBK__

#include "stddef.h"
#include "memory.h"
#include "string.h"

#define VGA_MEMORY ((uint16_t*)0xFFFFFFFF800B8000)
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

#define VGA_BLACK          0
#define VGA_BLUE           1
#define VGA_GREEN          2
#define VGA_CYAN           3
#define VGA_RED            4
#define VGA_MAGENTA        5
#define VGA_BROWN          6
#define VGA_LIGHT_GREY     7
#define VGA_DARK_GREY      8
#define VGA_LIGHT_BLUE     9
#define VGA_LIGHT_GREEN    10
#define VGA_LIGHT_CYAN     11
#define VGA_LIGHT_RED      12
#define VGA_LIGHT_MAGENTA  13
#define VGA_YELLOW         14
#define VGA_WHITE          15

#define VGA_COLOR(fg, bg) ((bg << 4) | (fg))
#define VGA_ENTRY(c, color) ((uint16_t)(c) | ((uint16_t)(color) << 8))

#define MAX_NUMBER_LENGTH 32
#define PRINT_BUF_SIZE 1024

typedef __builtin_va_list va_list;
#define va_start(v,l)   __builtin_va_start(v,l)
#define va_end(v)       __builtin_va_end(v)
#define va_arg(v,l)     __builtin_va_arg(v,l)
#define va_copy(d,s)    __builtin_va_copy(d,s)

int printf(const char* format, ...);
int snprintf(char* buf, size_t size, const char* fmt, ...);

void putc(char c);
void puts(const char* str);

void print_hex(uint64_t value);
void print_dec(int64_t value);
void print_ptr(void* ptr);

void vga_putchar(char c);
void clear_screen();

#endif
