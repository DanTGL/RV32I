TARGET=riscv64-elf
OBJECTS=start.o add.o and.o auipc.o bge.o blt.o bne.o jal.o lb.o lh.o lui.o or.o sb.o simple.o slli.o slti.o srai.o srli.o sub.o xor.o \
addi.o andi.o beq.o bgeu.o bltu.o j.o jalr.o lbu.o lhu.o lw.o ori.o sh.o sll.o slt.o sra.o srl.o sw.o xori.o

CFLAGS := $(CFLAGS) -mabi=ilp32 -march=rv32i -nostartfiles -nostdlib -ffreestanding
LDFLAGS := $(LDFLAGS) $(CFLAGS)

.PHONY: all clean

all: test.hex

%.o: %.S riscv_test.h test_macros.h
	$(TARGET)-gcc -c $(CFLAGS) -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) -DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

%.elf: $(OBJECTS)
	$(TARGET)-gcc $(LDFLAGS) -T link.ld -o $@ $^

%.bin: %.elf
	$(TARGET)-objcopy -O binary $< $@

%.hex: %.bin
	python3 makehex.py $< 65536 > $@

clean:
	rm -f test.bin test.elf test.hex
	rm -f $(OBJECTS)

