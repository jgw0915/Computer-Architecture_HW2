OUTPUT_ARCH(riscv)
ENTRY(_start)

PHDRS
{
  text PT_LOAD FLAGS(4 | 1);  /* PF_R | PF_X */
  data PT_LOAD FLAGS(4 | 2);  /* PF_R | PF_W */
}

SECTIONS
{
  /* ROM / flash start */
  . = 0x10000;

  /* Code + read-only */
  .text : ALIGN(4)
  {
    KEEP(*(.text._start))
    *(.init) *(.init.*)
    *(.text .text.*)
    *(.rodata .rodata.*)
  } :text

  /* Writable data */
  .data : ALIGN(4)
  {
    *(.data .data.*)
  } :data

  /* Zero-initialized */
  .bss (NOLOAD) : ALIGN(4)
  {
    __bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    __bss_end = .;
  } :data

  /* Simple static stack */
  .stack (NOLOAD) : ALIGN(16)
  {
    . += 4096;
    __stack_top = .;
  } :data
}
