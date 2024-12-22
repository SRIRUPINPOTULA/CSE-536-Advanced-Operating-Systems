OUTPUT_ARCH( "riscv" )

/* Task: ensure the correct starting function. */
ENTRY( _entry )

SECTIONS
{
  /* Task: ensure the correct entry address based on where -kernel in QEMU jumps. */
  . = 0x80000000;
  
  .text : {
    *(.text)
    ecode = .;
  }
  .data : {
    *(.data)
    edata = .;
  }
  .rodata : {
    *(.rodata)
    rodata = .;
  }
  .bss : {
    *(.bss)
    ebss = .;
  }
  end = .;


  /* Task lay out the sections as mentioned in the handout */
}