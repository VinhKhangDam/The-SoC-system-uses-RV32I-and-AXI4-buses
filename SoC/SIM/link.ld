ENTRY(_start)

MEMORY
{
  IRAM (rx) : ORIGIN = 0x10000000, LENGTH = 64K
  DRAM (rw) : ORIGIN = 0x10010000, LENGTH = 64K
}

SECTIONS
{
  .text : ALIGN(4)
  {
    KEEP(*(.text.start))
    *(.text*)
    *(.rodata*)
  } > IRAM

  .data : ALIGN(4)
  {
    *(.sdata*)
    *(.data*)
  } > DRAM AT > IRAM

  .bss (NOLOAD) : ALIGN(4)
  {
    *(.sbss*)
    *(.bss*)
    *(COMMON)
  } > DRAM

  /DISCARD/ :
  {
    *(.comment)
    *(.riscv.attributes)
  }
}
