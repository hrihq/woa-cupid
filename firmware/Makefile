CC       ?= clang
OBJCOPY  ?= llvm-objcopy
FD_BASE  ?= 0xA7100000
FD_SIZE  ?= 0x300000
OUT      ?= out

.PHONY: all clean

all: $(OUT)/cupid_bootshim.elf $(OUT)/cupid_bootshim.bin

$(OUT):
	mkdir -p $(OUT)

$(OUT)/cupid_bootshim.elf: cupid_bootshim.S | $(OUT)
	$(CC) --target=aarch64-linux-gnu -c $< -o $@ \
		-DREQUIRES_KERNEL_HEADER=1 -DFD_BASE=$(FD_BASE) -DFD_SIZE=$(FD_SIZE)

$(OUT)/cupid_bootshim.bin: $(OUT)/cupid_bootshim.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(OUT)
