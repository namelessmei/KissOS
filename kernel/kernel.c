#include "../libk/include/vga.h"

void kernel_main()
{
    clear_screen();
    printf("KissOS Kernel Test Suite\n");
    printf("=========================\n\n");

    printf("Testing printf:\n");
    printf("  String: %s\n", "Hello, Kernel!");
    printf("  Decimal: %d\n", 12345);
    printf("  Hexadecimal: %x\n", 0xBEEF);
    printf("  Unsigned: %u\n", 98765);
    printf("  Pointer: %p\n\n", (void*)0xCAFEBABE);

    printf("Testing VGA Output:\n");
    for (int i = 0; i < VGA_WIDTH; i++)
    {
        vga_putchar('*');
    }
    printf("\n\n");

    printf("Testing memory functions:\n");
    char mem_test[16];
    memset(mem_test, 'A', sizeof(mem_test));
    mem_test[15] = '\0';
    printf("  Memset result: %s\n", mem_test);

    char src[16] = "SourceData";
    char dest[16];
    memcpy(dest, src, sizeof(src));
    printf("  Memcpy result: %s\n", dest);

    char overlap[16] = "OverlapTest";
    memmove(overlap + 3, overlap, 9);
    printf("  Memmove result: %s\n", overlap);

    printf("  Memcmp test: %d\n\n", memcmp("abc", "abc", 3));

    printf("Testing string functions:\n");
    printf("  Strlen('Hello'): %d\n", (int)strlen("Hello"));

    char str1[32] = "Hello, ";
    char str2[] = "World!";
    strcat(str1, str2);
    printf("  Strcat result: %s\n", str1);

    char str3[32];
    strncpy(str3, "CopyThis", 8);
    str3[8] = '\0';
    printf("  Strncpy result: %s\n", str3);

    printf("  Strcmp('abc', 'abc'): %d\n", strcmp("abc", "abc"));
    printf("  Strncmp('abc', 'abd', 2): %d\n", strncmp("abc", "abd", 2));

    const char* find = strchr("FindMe", 'M');
    printf("  Strchr result: %s\n\n", find);

    printf("Testing edge cases:\n");
    char empty[1] = "";
    printf("  Empty string strlen: %d\n", (int)strlen(empty));

    char self_copy[16] = "SelfCopy";
    memmove(self_copy, self_copy, 8);
    printf("  Self memmove result: %s\n", self_copy);

    char concat_test[32] = "Concat";
    strncat(concat_test, "1234567890", 4);
    printf("  Strncat result: %s\n", concat_test);

    printf("\nKernel test suite completed.\n");

    while (1);
}
