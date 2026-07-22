OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*MEMORY
{
  /*MEM : ORIGIN = 0, LENGTH = 64K/
  ROM (rx) : ORIGIN = 0, LENGTH = 48K
  RAM (!rx) : ORIGIN = 0xC000, LENGTH = 16K
}/*

SECTIONS
{
  /*. = 0x00000000;
  . = ALIGN(0x1000);
  .text.init : { *(.text.init) } > ROM
  . = ALIGN(0x1000);
  .text : {
    _stext = .;
    *(.text)
    _etext = .;
  } >ROM
  . = ALIGN(0x1000);
  .data : {
    _sdata = .;
    *(.data)
    _edata = .;
  } > RAM AT >ROM
  .bss : {
    _sbss = .;
    *(.bss)
    _ebss = .;
  } > RAM
  _end = .;
  */
  
SECTIONS
{
    . = 0x00000000;
    .text.init : { *(.text.init) }
    . = ALIGN(0x1000);
    .text : { *(.text) } 
    . = ALIGN(0x1000);
    .data : { *(.data) } 
    .bss : { *(.bss) }
    _end = .;
}
