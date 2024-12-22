#include "types.h"
#include "param.h"
#include "layout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "elf.h"

#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(enum kernel ktype) {
    /* CSE 536: Get kernel load address from headers */
    uint64 a = 0;

    if (ktype == NORMAL)
    {
        a = RAMDISK;
    }
    else
    {
        a = RECOVERYDISK;
    }

    kernel_elfhdr = (struct elfhdr*) a;
    uint64 address_phoff = kernel_elfhdr->phoff;
    uint64 address_ehsize = kernel_elfhdr->ehsize;
    
    
    kernel_phdr = (struct proghdr*) (a + address_ehsize + address_phoff);
    uint64 res = kernel_phdr->vaddr;
    return res;
}

uint64 find_kernel_size(enum kernel ktype) {
    /* CSE 536: Get kernel binary size from headers */
    uint64 d = 0;

    if (ktype == NORMAL)
    {
        d = RAMDISK;
    }
    else
    {
        d = RECOVERYDISK;
    }

    kernel_elfhdr = (struct elfhdr*) d;
    uint64 a = kernel_elfhdr->shoff;
    uint64 b = kernel_elfhdr->shentsize;
    uint64 c = b * (kernel_elfhdr->shnum);
    return (a + c);
}

uint64 find_kernel_entry_addr(enum kernel ktype) {
    /* CSE 536: Get kernel entry point from headers */
    uint64 a = 0;

    if (ktype == NORMAL)
    {
        a = RAMDISK;
    }
    else
    {
        a = RECOVERYDISK;
    }

    kernel_elfhdr = (struct elfhdr*) a;
    return kernel_elfhdr->entry;
}
