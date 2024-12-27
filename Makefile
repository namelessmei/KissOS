ARCH ?= x86_64
AS = nasm
CC = $(ARCH)-elf-gcc
LD = $(ARCH)-elf-ld
OBJCOPY = $(ARCH)-elf-objcopy
QEMU = qemu-system-$(ARCH)

NASM_FLAGS = -f elf64
NASM_FLAGS_BIN = -f bin
C_FLAGS = -ffreestanding -nostdlib -mno-red-zone -Wall -Wextra -O3 -mcmodel=kernel \
         -Ilibk/include -Idrivers/include -Ikernel -fno-pic -fno-pie -mgeneral-regs-only
LD_FLAGS = -T arch/$(ARCH)/linker.ld -nostdlib

BUILD_DIR = build/$(ARCH)

BOOT_SRC = arch/$(ARCH)/boot/first_stage.asm arch/$(ARCH)/boot/second_stage.asm
ENTRY_SRC = arch/$(ARCH)/entry.asm
KERNEL_SRC = kernel/kernel.c
LIBK_SRC = $(wildcard libk/src/*.c)
DRIVERS_SRC = $(wildcard arch/$(ARCH)/drivers/src/*.c)

KERNEL_OBJ = $(BUILD_DIR)/kernel.o
ENTRY_OBJ = $(BUILD_DIR)/entry.o
LIBK_OBJ = $(patsubst libk/src/%.c, $(BUILD_DIR)/libk_%.o, $(LIBK_SRC))
DRIVERS_OBJ = $(patsubst arch/$(ARCH)/drivers/src/%.c, $(BUILD_DIR)/driver_%.o, $(DRIVERS_SRC))
BOOT_OBJ = $(patsubst arch/$(ARCH)/boot/%.asm, $(BUILD_DIR)/%.bin, $(BOOT_SRC))

KERNEL_BIN = $(BUILD_DIR)/kernel.bin
KERNEL_ELF = $(BUILD_DIR)/kernel.elf
BOOTLOADER_IMG = $(BUILD_DIR)/disk.img

all: $(BOOTLOADER_IMG)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.bin: arch/$(ARCH)/boot/%.asm | $(BUILD_DIR)
	$(AS) $(NASM_FLAGS_BIN) $< -o $@

$(ENTRY_OBJ): $(ENTRY_SRC) | $(BUILD_DIR)
	$(AS) $(NASM_FLAGS) $< -o $@

$(KERNEL_OBJ): $(KERNEL_SRC) | $(BUILD_DIR)
	$(CC) $(C_FLAGS) -c $< -o $@

$(BUILD_DIR)/libk_%.o: libk/src/%.c | $(BUILD_DIR)
	$(CC) $(C_FLAGS) -c $< -o $@

$(BUILD_DIR)/driver_%.o: arch/$(ARCH)/drivers/src/%.c | $(BUILD_DIR)
	$(CC) $(C_FLAGS) -c $< -o $@

$(KERNEL_ELF): $(ENTRY_OBJ) $(KERNEL_OBJ) $(LIBK_OBJ) $(DRIVERS_OBJ) | $(BUILD_DIR)
	$(LD) $(LD_FLAGS) -o $@ $^

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTLOADER_IMG): $(BUILD_DIR)/first_stage.bin $(BUILD_DIR)/second_stage.bin $(KERNEL_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(BUILD_DIR)/first_stage.bin of=$@ bs=512 seek=0 conv=notrunc
	dd if=$(BUILD_DIR)/second_stage.bin of=$@ bs=512 seek=1 conv=notrunc
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=4 conv=notrunc

clean:
	rm -rf build

run: $(BOOTLOADER_IMG)
	$(QEMU) -drive file=$(BOOTLOADER_IMG),format=raw -serial stdio

debug: $(BOOTLOADER_IMG)
	$(QEMU) -drive file=$(BOOTLOADER_IMG),format=raw -serial stdio -S -gdb tcp::1234

.PHONY: all clean run debug
