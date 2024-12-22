#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include <stdlib.h> 

// Execution Mode Declarations
#define U_MODE 0
#define S_MODE 1
#define M_MODE 2


bool pmp_config = false;
// Page table parameters
#define PAGE_LEVELS 3
#define PTE_ENTRIES 512

// Define page size
#define PGSIZE 4096

// Define pte variables
typedef uint64 pte_t;
typedef pte_t* pagetable_t;

// Structure representing values of a reg
struct vm_reg {
    int code;  
    int mode; 
    uint64 val;
};

// Structure representing the virtual machine's privileged state
struct vm_virtual_state {
    // M-mode Reg
    struct vm_reg mtvec;
    struct vm_reg mstatus;
    struct vm_reg mepc;
    struct vm_reg medeleg;
    struct vm_reg mideleg;
    struct vm_reg mie;
    struct vm_reg mip;
    struct vm_reg mtval2;
    struct vm_reg mcounteren;
    struct vm_reg mstatush;
    struct vm_reg mvendorid;
    struct vm_reg marchid;
    struct vm_reg mimpid;
    struct vm_reg mhartid;
    struct vm_reg mconfigptr;
    struct vm_reg mcause;
    struct vm_reg mscratch;
    struct vm_reg misa;
    struct vm_reg mtval;
    struct vm_reg mtinst; 

    // S-mode Reg
    struct vm_reg sstatus;
    struct vm_reg sie;
    struct vm_reg sepc;
    struct vm_reg stvec;
    struct vm_reg satp;
    struct vm_reg sedeleg;
    struct vm_reg scounteren;

    // U-mode Regs
    struct vm_reg uepc;
    struct vm_reg utvec;
    struct vm_reg uscratch;
    struct vm_reg ustatus;
    struct vm_reg ucause;
    struct vm_reg ubadaddr;
    struct vm_reg uip;
    struct vm_reg uie;

    // PMP Regs
    struct vm_reg pmpaddr[16];
    struct vm_reg pmpcfg[16];

    uint64 exec_mode; 
    pagetable_t page_table;
    pagetable_t vmm_pagetable;
};

// Mapping for csr registers
struct csr_register_map {
    int csr_code;
    struct vm_reg* vm_reg_val;
};

#define CSR_MAP_SIZE 67
static struct csr_register_map csr_register_map_values[CSR_MAP_SIZE];
static struct vm_virtual_state *vmm;

void pmp_configuration(int current_mode);

// Initialize the csr values the model, code and val
static void
initialize_csr_register_map_values() {
    csr_register_map_values[0]  = (struct csr_register_map){ 0x305, &vmm->mtvec };
    csr_register_map_values[1]  = (struct csr_register_map){ 0xf14, &vmm->mhartid };
    csr_register_map_values[2]  = (struct csr_register_map){ 0x300, &vmm->mstatus };
    csr_register_map_values[3]  = (struct csr_register_map){ 0x341, &vmm->mepc };
    csr_register_map_values[4]  = (struct csr_register_map){ 0x302, &vmm->medeleg };
    csr_register_map_values[5]  = (struct csr_register_map){ 0x303, &vmm->mideleg };
    csr_register_map_values[6]  = (struct csr_register_map){ 0xf11, &vmm->mvendorid };
    csr_register_map_values[7]  = (struct csr_register_map){ 0x140, &vmm->mscratch };
    csr_register_map_values[8]  = (struct csr_register_map){ 0x342, &vmm->mcause };
    csr_register_map_values[9]  = (struct csr_register_map){ 0x343, &vmm->mtval };
    csr_register_map_values[10] = (struct csr_register_map){ 0x344, &vmm->mip };
    csr_register_map_values[11] = (struct csr_register_map){ 0x34A, &vmm->mtinst };
    csr_register_map_values[12] = (struct csr_register_map){ 0x301, &vmm->misa };
    csr_register_map_values[13] = (struct csr_register_map){ 0x304, &vmm->mie };
    csr_register_map_values[14] = (struct csr_register_map){ 0x306, &vmm->mcounteren };
    csr_register_map_values[15] = (struct csr_register_map){ 0xf12, &vmm->marchid };
    csr_register_map_values[16] = (struct csr_register_map){ 0xf13, &vmm->mimpid };
    csr_register_map_values[17] = (struct csr_register_map){ 0xf15, &vmm->mconfigptr };
    csr_register_map_values[18] = (struct csr_register_map){ 0x180, &vmm->satp };
    csr_register_map_values[19] = (struct csr_register_map){ 0x104, &vmm->sie };
    csr_register_map_values[20] = (struct csr_register_map){ 0x105, &vmm->stvec };
    csr_register_map_values[21] = (struct csr_register_map){ 0x100, &vmm->sstatus };
    csr_register_map_values[22] = (struct csr_register_map){ 0x102, &vmm->sedeleg };
    csr_register_map_values[23] = (struct csr_register_map){ 0x106, &vmm->scounteren };
    csr_register_map_values[24] = (struct csr_register_map){ 0x041, &vmm->uepc };
    csr_register_map_values[25] = (struct csr_register_map){ 0x042, &vmm->ucause };
    csr_register_map_values[26] = (struct csr_register_map){ 0x043, &vmm->ubadaddr };
    csr_register_map_values[27] = (struct csr_register_map){ 0x044, &vmm->uip };
    csr_register_map_values[28] = (struct csr_register_map){ 0x004, &vmm->uie };
    csr_register_map_values[29] = (struct csr_register_map){ 0x005, &vmm->utvec };
    csr_register_map_values[30] = (struct csr_register_map){ 0x040, &vmm->uscratch };
    csr_register_map_values[31] = (struct csr_register_map){ 0x34B, &vmm->mtval2 };
    csr_register_map_values[32] = (struct csr_register_map){ 0x141, &vmm->sepc };
    csr_register_map_values[33] = (struct csr_register_map){ 0x34C, NULL }; 
    csr_register_map_values[34] = (struct csr_register_map){ 0x000, NULL }; 
    int index = 35;
    for(int i = 0; i < 16; i++) {
        csr_register_map_values[index++] = (struct csr_register_map){ 0x3a0 + i, &vmm->pmpcfg[i] };
        csr_register_map_values[index++] = (struct csr_register_map){ 0x3b0 + i, &vmm->pmpaddr[i] };
    }
}

static struct vm_reg* csr_register_1(uint32 code, int curr_mode) {
    for(int i = 0; i < CSR_MAP_SIZE; i++) 
    {
        if(csr_register_map_values[i].csr_code == code) 
        {

            if (csr_register_map_values[i].vm_reg_val == NULL)
                return NULL;
            int csr_mode = csr_register_map_values[i].vm_reg_val->mode;
            
            if(curr_mode >= csr_mode) 
            {
                return csr_register_map_values[i].vm_reg_val;
            }
        }
    }
    return NULL;
}


static struct vm_reg* csr_register(uint32 code) {
    for(int i = 0; i < CSR_MAP_SIZE; i++) 
    {
        //printf("\n******THe CSR Code value is: %p, %p\n", csr_register_map_values[i].csr_code, code);
        if(csr_register_map_values[i].csr_code == code) 
        {
            //printf("Found the element");
            //printf("\nFound the element: %p\n", csr_register_map_values[i].vm_reg_val->val);
            return csr_register_map_values[i].vm_reg_val;
        }
    }
    return NULL;
}

static int get_trapframe(struct proc *p, int rs1) {
    if (rs1 == 0) 
    {  
        return 0;
    } 
    else if (rs1 == 1) 
    {  
        return p->trapframe->ra;
    } 
    else if (rs1 == 2) 
    {  
        return p->trapframe->sp;
    } 
    else if (rs1 == 3) 
    {  
        return p->trapframe->gp;
    } 
    else if (rs1 == 4) 
    {  
        return p->trapframe->tp;
    } 
    else if (rs1 == 5) 
    {  
        return p->trapframe->t0;
    } 
    else if (rs1 == 6) 
    {  
        return p->trapframe->t1;
    } 
    else if (rs1 == 7) 
    {  
        return p->trapframe->t2;
    } 
    else if (rs1 == 8) 
    {  
        return p->trapframe->s0;
    } 
    else if (rs1 == 9) 
    {  
        return p->trapframe->s1;
    } 
    else if (rs1 == 10) 
    { 
        return p->trapframe->a0;
    } 
    else if (rs1 == 11) 
    { 
        return p->trapframe->a1;
    } 
    else if (rs1 == 12) 
    { 
        return p->trapframe->a2;
    } 
    else if (rs1 == 13) 
    { 
        return p->trapframe->a3;
    } 
    else if (rs1 == 14) 
    { 
        return p->trapframe->a4;
    } 
    else if (rs1 == 15) 
    { 
        return p->trapframe->a5;
    } 
    else if (rs1 == 16) 
    { 
        return p->trapframe->a6;
    } 
    else if (rs1 == 17) 
    { 
        return p->trapframe->a7;
    } 
    else if (rs1 == 18) 
    { 
        return p->trapframe->s2;
    } 
    else if (rs1 == 19) 
    { 
        return p->trapframe->s3;
    } 
    else if (rs1 == 20) 
    { 
        return p->trapframe->s4;
    } 
    else if (rs1 == 21) 
    { 
        return p->trapframe->s5;
    } 
    else if (rs1 == 22) 
    { 
        return p->trapframe->s6;
    } 
    else if (rs1 == 23) 
    { 
        return p->trapframe->s7;
    } 
    else if (rs1 == 24) 
    { 
        return p->trapframe->s8;
    } 
    else if (rs1 == 25) 
    { 
        return p->trapframe->s9;
    } 
    else if (rs1 == 26) 
    { 
        return p->trapframe->s10;
    } 
    else if (rs1 == 27) 
    { 
        return p->trapframe->s11;
    } 
    else if (rs1 == 28) 
    { 
        return p->trapframe->t3;
    } 
    else if (rs1 == 29) 
    { 
        return p->trapframe->t4;
    } 
    else if (rs1 == 30) 
    { 
        return p->trapframe->t5;
    } 
    else if (rs1 == 31) 
    { 
        return p->trapframe->t6;
    } 
    else 
    { 
        return 0;
    }
}

static void csrr_write_trapframe(int reg_val, int value, struct proc *p) {
    if (reg_val == 0xa) 
    {
        p->trapframe->a0 = value;
    } 
    else if (reg_val == 0xb) 
    {
        p->trapframe->a1 = value;
    } 
    else if (reg_val == 0xc) 
    {
        p->trapframe->a2 = value;
    }
     
    else if (reg_val == 0xd) 
    {
        p->trapframe->a3 = value;
    } 
    else if (reg_val == 0xe) 
    {
        p->trapframe->a4 = value;
    } 
    else if (reg_val == 0xf) 
    {
        p->trapframe->a5 = value;
    } 
    else if (reg_val == 0x10) 
    {
        p->trapframe->a6 = value;
    } 
    else if (reg_val == 0x11) 
    {
        p->trapframe->a7 = value;
    } 
    else if (reg_val == 0x12) 
    {
        p->trapframe->t0 = value;
    } 
    else if (reg_val == 0x13) 
    {
        p->trapframe->t1 = value;
    } 
    else if (reg_val == 0x14) 
    {
        p->trapframe->t2 = value;
    } 
    else if (reg_val == 0x15) 
    {
        p->trapframe->t3 = value;
    } 
    else if (reg_val == 0x16) 
    {
        p->trapframe->t4 = value;
    } 
    else if (reg_val == 0x17) 
    {
        p->trapframe->t5 = value;
    } 
    else if (reg_val == 0x18) 
    {
        p->trapframe->t6 = value;
    } 
    else if (reg_val == 0x19) 
    {
        p->trapframe->s0 = value;
    } 
    else if (reg_val == 0x1a) 
    {
        p->trapframe->s1 = value;
    } 
    else if (reg_val == 0x1b) 
    {
        p->trapframe->s2 = value;
    } 
    else if (reg_val == 0x1c) 
    {
        p->trapframe->s3 = value;
    } 
    else if (reg_val == 0x1d) 
    {
        p->trapframe->s4 = value;
    } 
    else if (reg_val == 0x1e) 
    {
        p->trapframe->s5 = value;
    } 
    else if (reg_val == 0x1f) {
        p->trapframe->s6 = value;
    } 
    else if (reg_val == 0x20) 
    {
        p->trapframe->s7 = value;
    } 
    else if (reg_val == 0x21) 
    {
        p->trapframe->s8 = value;
    } 
    else if (reg_val == 0x22) 
    {
        p->trapframe->s9 = value;
    } 
    else if (reg_val == 0x23) 
    {
        p->trapframe->s10 = value;
    } 
    else if (reg_val == 0x24) 
    {
        p->trapframe->s11 = value;
    }
}

//Function for csrw write
static void csrw_write(uint32 code, int value) {
    struct proc *p = myproc();

    if (code >= 0x3A0 && code <= 0x3BF) 
    {
        if (vmm->exec_mode != M_MODE) 
        {
            //printf("Kill the process");
            kill(p->pid);
            return;
        }
    } 
    else {
    if (code == 0x300) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->mstatus.val = value;
    } 
    else if (code == 0x301) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->misa.val = value;
    } 
    else if (code == 0x302) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->medeleg.val = value;
    } 
    else if (code == 0x303) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->mideleg.val = value;
    } else if (code == 0x304) {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->mie.val = value;
    } 
    else if (code == 0x305) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->mtvec.val = value;
    } 
    else if (code == 0x344) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->mip.val = value;
    } 
    else if (code == 0x341) 
    {
        if (vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->mepc.val = value;
    } 
    else if (code == 0x100) 
    {
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->sstatus.val = value;
    } 
    else if (code == 0x104) 
    {
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->sie.val = value;
    } 
    else if (code == 0x105)
    {
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->stvec.val = value;
    } 
    else if (code == 0x180) 
    {
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->satp.val = value;
    } 
    else if (code == 0x102) 
    {
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->sedeleg.val = value;
    } 
    else if (code == 0x041) 
    {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->uepc.val = value;
    }
     else if (code == 0x042) 
     {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->ucause.val = value;
    } 
    else if (code == 0x044) 
    {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->uip.val = value;
    } 
    else if (code == 0x043) 
    {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->ubadaddr.val = value;
    } 
    else if (code == 0x004) 
    {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->uie.val = value;
    } 
    else if (code == 0x005) 
    {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->utvec.val = value;
    } 
    else if (code == 0x040) 
    {
        if (vmm->exec_mode != U_MODE)
            kill(p->pid);
        vmm->uscratch.val = value;
    } 
    else if (code == 0x141) 
    {
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
            kill(p->pid);
        vmm->sepc.val = value;
    } 
    else 
    {
        printf("Invalid code could not update!!!!: %x\n", code);
        kill(p->pid);
    }
}


    if (code >= 0x3a0 && code <= 0x3bf) 
    {
        if (code >= 0x3a0 && code <= 0x3af) 
        {
            //map the pmp cfg
            int pmp_index = code - 0x3a0;
            if (pmp_index < 0 || pmp_index >= 16) 
            {
                printf("Could not update the code: %p\n", code);
                kill(p->pid);
                return;
            }
            vmm->pmpcfg[pmp_index].val = value;
            //printf("Updated the PMP CFG");
        }
        else if (code >= 0x3b0 && code <= 0x3bf) 
        {
            //Map pmp addr
            int pmp_index = code - 0x3b0;
            if (pmp_index < 0 || pmp_index >= 16) {
                printf("Could not update the code: %p\n", code);
                kill(p->pid);
                return;
            }
            vmm->pmpaddr[pmp_index].val = value;
            //printf("Updated the PMP ADDR");
        }
    }
}


// Main trap and emulate function
void trap_and_emulate(void) {
    struct proc *p = myproc();
    uint64 type_instruction = 0;
    pagetable_t pagetable = p->pagetable;
    //printf("The current mode is: %p\n",vmm->exec_mode);
    // Fetch the instruction causing the trap
    if(copyin(pagetable, (char*)&type_instruction, p->trapframe->epc, sizeof(type_instruction)) < 0){
        //printf("The process is killed here \n");
        kill(p->pid);
        return;
    }

    uint64 addr     = p->trapframe->epc;
    uint32 op       = type_instruction & 0x7F;
    uint32 rd       = (type_instruction >> 7) & 0x1F;
    uint32 funct3   = (type_instruction >> 12) & 0x7;
    uint32 rs1      = (type_instruction >> 15) & 0x1F;
    uint32 uimm     = (type_instruction >> 20) & 0xFFF;

    // Print the instruction details for debugging
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n",
           addr, op, rd, funct3, rs1, uimm);
    
    
    //printf("The value of scause is: ****** %d\n", r_scause());
    
    if(funct3 ==0 && uimm==0){
        //printf("The current mode is: %p\n",vmm->exec_mode);
        printf("(EC at %p)\n", p->trapframe->epc);
        if(vmm->exec_mode == 0)
        {
            vmm->exec_mode = 1;
            vmm->sepc.val = p->trapframe->epc;
            p->trapframe->epc = vmm->stvec.val;
        }

    }
    
    // Handle sret (Supervisor Return)
    else if (funct3 == 0 && uimm == 0x102) {
        uint64 value_sstatus = vmm->sstatus.val;
        uint64 spp_bit_value = (value_sstatus >> 8) & 0x1;
        if(vmm->exec_mode != 1){
            //printf("Killing the sads\n");
            //printf("THe value is %p\n", vmm->exec_mode);
            kill(p->pid);
        }
        else{
    
        if (spp_bit_value == 1) {
            vmm->exec_mode = S_MODE;
            //p->trapframe->epc = vmm->sepc.val;
        } 
        else {
            if (vmm->exec_mode == S_MODE) {
                vmm->exec_mode = U_MODE;
                p->trapframe->epc = vmm->sepc.val;
            } 
            else{
                //printf("Killing the procesdasads\n");
                kill(p->pid);
            }
        }
        }
    }
    // Handle mret (Machine Return)
    else if (funct3 == 0 && uimm == 0x302) {
        uint64 value_mstatus = vmm->mstatus.val;
        uint64 mpp_bit_value = (value_mstatus >> 11) & 0x3;
        if (mpp_bit_value == 3) {
            vmm->exec_mode = M_MODE;
            p->trapframe->epc = vmm->mepc.val;
        } else if (mpp_bit_value == 2) {
            //printf("Killed the process from mret");
            kill(p->pid);
        } else if (mpp_bit_value == 1) {
            vmm->exec_mode = S_MODE;
            p->trapframe->epc = vmm->mepc.val;
        } else if (mpp_bit_value == 0) {
            vmm->exec_mode = U_MODE;
            p->trapframe->epc = vmm->mepc.val;
        }
        pmp_configuration(M_MODE);
        if(pmp_config == true)
        {
            //printf("Kill the process");
            kill(p->pid);
        }
    } 
    // Handle csrr (CSR Read)
    else if (funct3 == 0x2) {
        struct vm_reg* found_reg = csr_register_1(uimm, vmm->exec_mode);
        if (found_reg == NULL) {
            printf("Incorrect CSR code %x for execution mode as : %d\n", uimm, vmm->exec_mode);
            kill(p->pid);
        } else {
            csrr_write_trapframe(rd, found_reg->val, p);
        }
        p->trapframe->epc += 4;
    } 
    // Handle csrw (CSR Write)
    else if (funct3 == 0x1) {
        struct vm_reg* found_reg = csr_register(uimm);
        //printf("The found register value is %p", found_reg);
        if (found_reg != NULL) {
            int source_val = get_trapframe(p, rs1);
            csrw_write(uimm, source_val);
        } else {
            printf("Invalid CSR for he uimm is : %x\n", uimm);
            kill(p->pid);
        }
        p->trapframe->epc += 4;
    }
    else {
        kill(p->pid);
    }
}

static void pmp_pagetable_configuration(uint64 base_addr, uint64 final_addr, int execution_mode) {
    vmm->vmm_pagetable = (pte_t*)kalloc();
    if(vmm->vmm_pagetable == NULL)
        panic("Could not allocate memory to pmp page table");
    memset(vmm->vmm_pagetable, 0, sizeof(pte_t) * PTE_ENTRIES * PAGE_LEVELS);
    //printf("Allocated the memeory for the pmp");

    pte_t *pte;
    uint64 pa, flags;
    //char *mem;
    struct proc *p = myproc();
    pagetable_t old = p->pagetable; 
    pagetable_t new = vmm->vmm_pagetable;
    //printf("The base addr is: %p\n", base_addr);
    //printf("The final addr is: %p\n", final_addr);
    if(execution_mode == M_MODE) {
        // M_MODE: Copy memory pages from old to new pagetable
        //vmm->vmm_pagetable = proc_pagetable(p);
        //vmm->page_table = p->pagetable;
        //printf("In m_moDE \n");
        for(uint64 i = base_addr; i < final_addr; i += PGSIZE){
            if((pte = walk(old, i, 0)) == 0)
                panic("pmp_pagetable_configuration: pte doesnot exist");
            if((*pte & PTE_V) == 0)
                panic("pmp_pagetable_configuration: page was not present");
            pa = PTE2PA(*pte);
            flags = PTE_FLAGS(*pte);
            // if((mem = kalloc()) == 0)
            //     panic("pmp_pagetable_configuration: kalloc failed");
            // memmove(mem, (char*)pa, PGSIZE);
            if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
                //kfree(mem);
                panic("mappages failed, have a look");
            }
            //printf("Allocated the mappages");
        }

        for(uint64 i = 0; i < p->sz; i += PGSIZE){
            //printf("Inside the loop for page table mapping");
            if((pte = walk(old, i, 0)) == 0)
                panic("pmp_pagetable_configuration: pte doesnot exist");
            if((*pte & PTE_V) == 0)
                panic("pmp_pagetable_configuration: page was not present");
            pa = PTE2PA(*pte);
            flags = PTE_FLAGS(*pte);
            // if((mem = kalloc()) == 0)
            //     panic("pmp_pagetable_configuration: kalloc failed");
            // memmove(mem, (char*)pa, PGSIZE);
            if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
                //kfree(mem);
                panic("mappages failed, have a look");
            }
        }
    } 
    else if(execution_mode == S_MODE || execution_mode == U_MODE) {
        p->pagetable = vmm->vmm_pagetable;
    }
}


static void pmp_set_permissions(uint64 pmp_final_addr, uint64 cfg, uint64 pmp_base_addr) {
    //printf("\n**In pmp set permissions function\n");
    //printf("\n**In pmp set permissions function: %p\n", pmp_base_addr);
    //printf("\n**In pmp set permissions function: %p\n", pmp_final_addr);
   // struct proc *p = myproc();
   for (uint64 i = pmp_base_addr; i < pmp_final_addr; i += PGSIZE) {
    //printf("Checking address: 0x%lx\n", i);

    pte_t *pte = walk(vmm->vmm_pagetable, i, 0);
    if (pte && (*pte & PTE_V)) {  // Ensure the PTE is valid
        //printf("Original PTE at address 0x%lx: 0x%lx\n", i, *pte);

        uint64 new_pte = PA2PTE(PTE2PA(*pte)) | PTE_V;

        // Set new permissions based on the configuration
        if (cfg & PTE_R) {
            //printf(" Updated Read permissionn");
            new_pte |= PTE_R;
        }
        if (cfg & PTE_W) {
            //printf("Updated Write permission\n");
            new_pte |= PTE_W;
        }
        if (cfg & PTE_X) {
            //printf("Updated Execute permission\n");
            new_pte |= PTE_X;
        }

        *pte = new_pte;

        // Print the updated PTE for debugging
        //printf("Updated the pointer");
    } 
    }
    pmp_config = true;

    // if(vmm->exec_mode == S_MODE || vmm->exec_mode == U_MODE) {
    //     p->pagetable = vmm->vmm_pagetable;
    // }
}


// PMP Configurations
void pmp_configuration(int current_mode) {
    uint64 base_addr = 0x80000000;
    uint64 final_addr = 0x80400000;
    pmp_pagetable_configuration(base_addr, final_addr, current_mode);
    uint64 final_addr_1 = base_addr;
    
    //printf("in pmp fucntion********");
    if(vmm->pmpaddr[0].val != 0)
    {
        uint64 start_addr = vmm->pmpaddr[0].val;
        start_addr = start_addr << 2;
        if (vmm->pmpaddr[1].val != 0){
    final_addr_1 = vmm->pmpaddr[1].val;
    final_addr_1 = final_addr_1 << 2;
    }
    uint64 cfg = vmm->pmpcfg[0].val;
    cfg = cfg & 0xFF0;
    cfg = cfg >> 8;
    pmp_set_permissions(final_addr_1 , cfg, start_addr);
    //printf("After the pmp configurations");
    }
    
    //printf("Call the pmp set permissions");
    //printf("\n**In pmp set permissions adfasdffunction: %p\n", start_addr);
    //printf("\n**In pmp set permissions fasdfasdffunction: %p\n", final_addr_1);
    //printf("The cfg condition is: %p", cfg);
    //if (final_addr_1 !==0 && start_addr != 0)
    //    pmp_set_permissions(final_addr_1 , cfg, start_addr);
    //printf("Broke the loop\n");
    
    // for (uint64 i = prev_addr; i < final_addr; i+=PGSIZE)
    // {
    //     //printf("Permisions for the remainnig addrewss");
    //     pte_t *pte = walk(vmm->vmm_pagetable, i, 0);
    //     *pte = ~(PTE_R | PTE_W | PTE_X);
    // }
    //printf("The scause value is: *****", r_scause());
}

// Initialize the VM privileged state with specific code, mode, and val for each register
void trap_and_emulate_init(void) {
    //printf("Allocating the memory\n");
    vmm = (struct vm_virtual_state*)kalloc();
    if(vmm == NULL){
        panic("Could not allocate memory");
    }

    memset(vmm, 0, sizeof(struct vm_virtual_state));

    vmm->mtval2.code = 0x34B;
    vmm->mtval2.mode = M_MODE;
    vmm->mtval2.val = 0;

    vmm->mcause.code = 0x342;
    vmm->mcause.mode = M_MODE;
    vmm->mcause.val = 0;

    vmm->mstatush.code = 0x310;
    vmm->mstatush.mode = M_MODE;
    vmm->mstatush.val = 0;

    vmm->mvendorid.code = 0xf11;
    vmm->mvendorid.mode = M_MODE;
    vmm->mvendorid.val = 0x637365353336;

    vmm->marchid.code = 0xf12;
    vmm->marchid.mode = M_MODE;
    vmm->marchid.val = 0;

    vmm->mimpid.code = 0xf13;
    vmm->mimpid.mode = M_MODE;
    vmm->mimpid.val = 0;

    vmm->mhartid.code = 0xf14;
    vmm->mhartid.mode = M_MODE;
    vmm->mhartid.val = 0;

    vmm->mconfigptr.code = 0xf15;
    vmm->mconfigptr.mode = M_MODE;
    vmm->mconfigptr.val = 0;

    vmm->mtvec.code = 0x305;
    vmm->mtvec.mode = M_MODE;
    vmm->mtvec.val = 0;

    vmm->mstatus.code = 0x300;
    vmm->mstatus.mode = M_MODE;
    vmm->mstatus.val = 0;

    vmm->mepc.code = 0x341;
    vmm->mepc.mode = M_MODE;
    vmm->mepc.val = 0;

    vmm->medeleg.code = 0x302;
    vmm->medeleg.mode = M_MODE;
    vmm->medeleg.val = 0;

    vmm->mideleg.code = 0x303;
    vmm->mideleg.mode = M_MODE;
    vmm->mideleg.val = 0;

    vmm->mie.code = 0x304;
    vmm->mie.mode = M_MODE; 
    vmm->mie.val = 0;

    vmm->mip.code = 0x344;
    vmm->mip.mode = M_MODE;
    vmm->mip.val = 0;

    vmm->mcounteren.code = 0x306;
    vmm->mcounteren.mode = M_MODE;
    vmm->mcounteren.val = 0;

    vmm->mscratch.code = 0x140;
    vmm->mscratch.mode = M_MODE;
    vmm->mscratch.val = 0;

    vmm->misa.code = 0x301;
    vmm->misa.mode = M_MODE;
    vmm->misa.val = 0;

    vmm->mtval.code = 0x343;
    vmm->mtval.mode = M_MODE;
    vmm->mtval.val = 0;

    vmm->mtinst.code = 0x34A;
    vmm->mtinst.mode = M_MODE;
    vmm->mtinst.val = 0;

    vmm->sstatus.code = 0x100;
    vmm->sstatus.mode = S_MODE;
    vmm->sstatus.val = 0;

    vmm->sedeleg.code = 0x102;
    vmm->sedeleg.mode = S_MODE;
    vmm->sedeleg.val = 0;

    vmm->sie.code = 0x104;
    vmm->sie.mode = S_MODE;
    vmm->sie.val = 0;

    vmm->stvec.code = 0x105;
    vmm->stvec.mode = S_MODE;
    vmm->stvec.val = 0;

    vmm->scounteren.code = 0x106;
    vmm->scounteren.mode = S_MODE;
    vmm->scounteren.val = 0;

    vmm->sepc.code = 0x141;
    vmm->sepc.mode = S_MODE;
    vmm->sepc.val = 0;

    vmm->satp.code = 0x180;
    vmm->satp.mode = S_MODE;
    vmm->satp.val = 0;

    vmm->uepc.code = 0x041;
    vmm->uepc.mode = U_MODE;
    vmm->uepc.val = 0;

    vmm->ucause.code = 0x042;
    vmm->ucause.mode = U_MODE;
    vmm->ucause.val = 0;

    vmm->ubadaddr.code = 0x043;
    vmm->ubadaddr.mode = U_MODE;
    vmm->ubadaddr.val = 0;

    vmm->uip.code = 0x044;
    vmm->uip.mode = U_MODE;
    vmm->uip.val = 0;

    vmm->ustatus.code = 0x000; 
    vmm->ustatus.mode = U_MODE;
    vmm->ustatus.val = 0;

    vmm->uie.code = 0x004;
    vmm->uie.mode = U_MODE;
    vmm->uie.val = 0;

    vmm->utvec.code = 0x005;
    vmm->utvec.mode = U_MODE;
    vmm->utvec.val = 0;

    vmm->uscratch.code = 0x040;
    vmm->uscratch.mode = U_MODE;
    vmm->uscratch.val = 0;

    for (int i = 0; i < 16; i++) {
        vmm->pmpcfg[i].code = 0x3a0 + i;
        vmm->pmpcfg[i].val = 0;
        vmm->pmpcfg[i].mode = M_MODE;

        vmm->pmpaddr[i].code = 0x3b0 + i;
        vmm->pmpaddr[i].val = 0;
        vmm->pmpaddr[i].mode = M_MODE;
    }

    
    initialize_csr_register_map_values();

    vmm->exec_mode = M_MODE;
    //printf("\nAfter the trap and emulate init\n");
}