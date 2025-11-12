include ../mk/toolchain.mk

ARCH = -march=rv32izicsr
LINKER_SCRIPT = linker.ld

EMU ?= ../build/rv32emu

AFLAGS = -g $(ARCH)
CFLAGS = -Ofast -march=rv32i_zicsr 
LDFLAGS = -T $(LINKER_SCRIPT)

# EXEC = test-disassembly.elf
# OBJS = improve_compiler-Ofast.o

EXEC = test.elf
OBJS = start.o main.o perfcounter.o libgcc_helpers.o fast_rsqrt_Ofast_improved.o

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJDUMP = $(CROSS_COMPILE)objdump

# 關掉內建隱含規則與後綴，避免自動產生 .s/.S
.SUFFIXES:
MAKEFLAGS += -rR

.PHONY: all run dump clean asm asm_clean

# Directory to place generated assembly (default: sibling Quiz3_Playground)
AS_OUT_DIR ?= .
# list of assembly outputs corresponding to C sources
ASM_SRCS := $(wildcard *.c)
ASM_OUTS := $(patsubst %.c,$(AS_OUT_DIR)/%.S,$(ASM_SRCS))

all: $(EXEC)


$(EXEC): $(OBJS) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.S
	$(AS) $(AFLAGS) $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@ -c

run: $(EXEC)
	@test -f $(EMU) || (echo "Error: $(EMU) not found" && exit 1)
	@grep -q "ENABLE_ELF_LOADER=1" ../build/.config || (echo "Error: ENABLE_ELF_LOADER=1 not set" && exit 1)
	@grep -q "ENABLE_SYSTEM=1" ../build/.config || (echo "Error: ENABLE_SYSTEM=1 not set" && exit 1)
	$(EMU) $(EXEC)

dump: $(EXEC)
	@test -f $(EXEC) || (echo "Error: $(EXEC) not found" && exit 1)
	@id=$$(cat .dumpid 2>/dev/null || echo 0); \
	id=$$((id + 1)); \
	printf "%d\n" $$id > .dumpid; \
	out="$(EXEC).dump-$$id.asm"; \
	echo "Writing $$out"; \
	$(OBJDUMP) -d -j .text -M reg-names=abi $(EXEC) > "$$out"; \
	less "$$out"

clean:
	rm -f $(EXEC) $(OBJS)

# Generate assembly files (only when explicitly requested):
#  make asm
asm: $(AS_OUT_DIR) $(ASM_OUTS)

$(AS_OUT_DIR):
	mkdir -p "$@"

# rule: ../Quiz3_Playground/foo.S from foo.c
$(AS_OUT_DIR)/%.S: %.c
	$(CC) $(CFLAGS) -S $< -o $@ 

asm_clean: 
	rm -f $(ASM_OUTS)
