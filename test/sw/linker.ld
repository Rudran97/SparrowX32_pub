 __heap_size    = 0x200;
  __stack_size  = 0x800;

  MEMORY
  {
    ROM (rwx) : ORIGIN = 0x80000000, LENGTH = 0x10000
    RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 0x08000
  }
  SECTIONS
  {
    .text :
    {
      *(.boot)
      *(.text)
      *(.text)
      *(.rodata*)
      . = ALIGN(4);
    } > ROM
    .data :
    {
      *(.sbss)
      *(.data)
      *(.bss)
      *(.rela*)
      *(COMMON)
      . = ALIGN(4);
    } > RAM

    .heap :
    {
      . = ALIGN(4);
      PROVIDE ( end = . );
      _sheap = .;
      . = . + __heap_size;
      . = ALIGN(4);
      _eheap = .;
    } >RAM

    .stack :
    {
      . = ALIGN(4);
      _estack = .;
      . = . + __stack_size;
      . = ALIGN(4);
      _sstack = .;
    } >RAM
  }