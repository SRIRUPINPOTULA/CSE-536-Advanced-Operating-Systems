# _entry should be the first function invoked when
# the QEMU CPU starts executing. It's location should
# according to the memory layout provided in param.h

.section .text
.global _entry
_entry:
        la a0, bl_stack
        li a1, 4096
        add sp, a0, a1
        jal start  
spin:
        j spin