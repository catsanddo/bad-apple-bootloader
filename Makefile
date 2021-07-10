AS=nasm -f bin

BOOT_SRC=boot.asm
BOOT_OBJ=boot.bin

ISO=os.iso

all: boot.bin
	cat $^ > $(ISO)

boot.bin: $(BOOT_SRC)
	$(AS) -o $@ $^

run: all
	qemu-system-i386 -fda $(ISO)

clean:
	rm -f $(BOOT_OBJ)
	rm -f $(ISO)

.PHONY: all run clean
