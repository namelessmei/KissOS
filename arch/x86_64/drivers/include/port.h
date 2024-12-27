#ifndef __BBOS__PORT_DRIVER__LIBK__
#define  __BBOS__PORT_DRIVER__LIBK__

#include "../../../../libk/include/stddef.h"

void outb(uint16_t port, uint8_t val);
uint8_t inb(uint16_t port);
void io_wait();

#endif
