/* This file contains code for a generic page fault handler for processes. */
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"

#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

int loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz);
int flags2perm(int flags);

/* CSE 536: (2.4) read current time. */
uint64 read_current_timestamp() {
  uint64 curticks = 0;
  acquire(&tickslock);
  curticks = ticks;
  wakeup(&ticks);
  release(&tickslock);
  return curticks;
}

bool psa_tracker[PSASIZE];

/* All blocks are free during initialization. */
void init_psa_regions(void)
{
    for (int i = 0; i < PSASIZE; i++) 
        psa_tracker[i] = false;
}

/* Evict heap page to disk when resident pages exceed limit */
void evict_page_to_disk(struct proc* p) {
    /* Find free block */
    int blockno = 0;
    for (int i=0;i<PSASIZE;i=i+4)
    {
        if(psa_tracker[i]==false && psa_tracker[i+1]==false && psa_tracker[i+2]==false && psa_tracker[i+3]==false )
        {
            blockno=i;
            break;
        }
    }

    /* Find victim page using FIFO. */
    long int largest_time=0x0FFFFFFFFFFFFFFF;
    long int curr_time = read_current_timestamp();
    int position=0;
    for(int i=0;i<MAXHEAP;i++)
    {
        long int load_time_heap = p->heap_tracker[i].last_load_time;
        if((p->heap_tracker[i].loaded==true) && ((load_time_heap -curr_time)<largest_time))
        {
            largest_time=load_time_heap-curr_time;
            position=i;
        }
    }

    /* Print statement. */
    print_evict_page(p->heap_tracker[position].addr, blockno);

    /* Read memory from the user to kernel memory first. */
    char *kernel_memory = kalloc();
    copyin(p->pagetable, kernel_memory, p->heap_tracker[position].addr, 4096);
    
    /* Write to the disk blocks. Below is a template as to how this works. There is
     * definitely a better way but this works for now. :p */
    //struct buf* b;
    //b = bread(1, PSASTART+(blockno));
        // Copy page contents to b.data using memmove.
    for (int i=0;i<4;i++){
        struct buf* b;
        b = bread(1, PSASTART+(blockno));
        memmove(b->data, kernel_memory, 1024);
        bwrite(b);
        brelse(b);
        psa_tracker[blockno+i]=true;
    }
    

    /* Unmap swapped out page */
    uvmunmap(p->pagetable, p->heap_tracker[position].addr, 1, 1);
    /* Update the resident heap tracker. */
    p->heap_tracker[position].loaded=false;
    p->heap_tracker[position].startblock=blockno;
    p->resident_heap_pages--;

}

/* Retrieve faulted page from disk. */
void retrieve_page_from_disk(struct proc* p, uint64 uvaddr) {
    /* Find where the page is located in disk */
    int page_location=-1;
    for(int i=0;i<MAXHEAP;i++)
    {
        if(uvaddr == p->heap_tracker[i].addr)
        {
            page_location=i;
            break;
        }
    }
    if(page_location==-1)
    {
        panic("Couldnot find the page in panic mode.");
    }
    /* Print statement. */
    print_retrieve_page(uvaddr, p->heap_tracker[page_location].startblock);

    /* Create a kernel page to read memory temporarily into first. */
    char *kernel_page = kalloc();
    /* Read the disk block into temp kernel page. */
    for (int i=0;i<4;i++){
        struct buf* b;
        b = bread(1, PSASTART+(p->heap_tracker[page_location].startblock+i));
        memmove(kernel_page+ (i*1024), b->data, 1024);
        //bwrite(b);
        brelse(b);
        psa_tracker[p->heap_tracker[page_location].startblock+i]=false;
    }
    /* Copy from temp kernel page to uvaddr (use copyout) */
    copyout(p->pagetable, uvaddr, kernel_page,4096 );
    kfree(kernel_page);
}


void page_fault_handler(void) 
{
    /* Current process struct */
    struct proc *p = myproc();
    struct inode *ip;
    struct elfhdr elf;
    struct proghdr ph;
    /* Track whether the heap page should be brought back from disk or not. */
    bool load_from_disk = false;
    /* Find faulting address. */
    uint64 faulting_addr = r_stval();
    faulting_addr = faulting_addr & (~(0xFFF));
    print_page_fault(p->name, faulting_addr);
    
    if(p->cow_enabled==1 && r_scause()==15)
    {
        copy_on_write();
        goto out;
    }
    
    int i, off, heap_value;
    /*using heap_tracker*/
    bool found=false;
    for(int i=0;i<MAXHEAP;i++){
        if(p->heap_tracker[i].addr == faulting_addr)
        {
            found=true;
            heap_value=i;
            break;
        }
    }
    if(p->heap_tracker[heap_value].startblock!=-1){
                load_from_disk=true;
    }
    if (found==true) {
         goto heap_handle;
    }
    /* Check if the fault address is a heap page. Use p->heap_tracker */
    //if (true) {
    //    goto heap_handle;
    //}
    begin_op();
    if((ip = namei(p->name)) == 0){
        end_op();
        return;
    }
    ilock(ip);
    if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
        goto bad;

    if(elf.magic != ELF_MAGIC)
        goto bad;
    for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
        if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
            goto bad;
        if(ph.type != ELF_PROG_LOAD)
            continue;
        if(ph.memsz < ph.filesz)
            goto bad;
        if(ph.vaddr + ph.memsz < ph.vaddr)
            goto bad;
        if(ph.vaddr % PGSIZE != 0)
            goto bad;
        
        if((faulting_addr >= ph.vaddr) && (faulting_addr < (ph.vaddr + ph.memsz)) ){
            //printf("found page\n\n");
            uvmalloc(p->pagetable,ph.vaddr, ph.vaddr + ph.memsz, flags2perm(ph.flags));
            if(loadseg(p->pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
                goto bad;
            break;
        }
    }
    iunlockput(ip);
    end_op();
    ip = 0;

    /* If it came here, it is a page from the program binary that we must load. */
    print_load_seg(faulting_addr, ph.off, ph.memsz);

    /* Go to out, since the remainder of this code is for the heap. */
    goto out;
bad:
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  if(ip){
    iunlockput(ip);
    end_op();
  }
  return;

heap_handle:
    /* 2.4: Check if resident pages are more than heap pages. If yes, evict. */
    if (p->resident_heap_pages == MAXRESHEAP) {
        evict_page_to_disk(p);
    }

    /* 2.3: Map a heap page into the process' address space. (Hint: check growproc) */
    if(uvmalloc(p->pagetable, faulting_addr, faulting_addr+4096, PTE_W)==0)
        panic("Handled the case");
    /* 2.4: Update the last load time for the loaded heap page in p->heap_tracker. */
    p->heap_tracker[heap_value].last_load_time = read_current_timestamp();
    p->heap_tracker[heap_value].loaded = true;
    /* 2.4: Heap page was swapped to disk previously. We must load it from disk. */
    if (load_from_disk) {
        retrieve_page_from_disk(p, faulting_addr);
    }

    /* Track that another heap page has been brought into memory. */

    p->resident_heap_pages++;

out:
    /* Flush stale page table entries. This is important to always do. */
    sfence_vma();
    return;
}
