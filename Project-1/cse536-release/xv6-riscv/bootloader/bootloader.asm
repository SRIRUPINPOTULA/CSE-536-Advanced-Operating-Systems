
bootloader/bootloader:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00001517          	auipc	a0,0x1
    80000004:	bf050513          	addi	a0,a0,-1040 # 80000bf0 <bl_stack>
    80000008:	6585                	lui	a1,0x1
    8000000a:	00b50133          	add	sp,a0,a1
    8000000e:	15c000ef          	jal	ra,8000016a <start>

0000000080000012 <spin>:
    80000012:	a001                	j	80000012 <spin>

0000000080000014 <panic>:
};
struct sys_info* sys_info_ptr;

extern void _entry(void);
void panic(char *s)
{
    80000014:	1141                	addi	sp,sp,-16
    80000016:	e422                	sd	s0,8(sp)
    80000018:	0800                	addi	s0,sp,16
  for(;;)
    8000001a:	a001                	j	8000001a <panic+0x6>

000000008000001c <setup_recovery_kernel>:
    ;
}

/* CSE 536: Boot into the RECOVERY kernel instead of NORMAL kernel
 * when hash verification fails. */
void setup_recovery_kernel(void) {
    8000001c:	ba010113          	addi	sp,sp,-1120
    80000020:	44113c23          	sd	ra,1112(sp)
    80000024:	44813823          	sd	s0,1104(sp)
    80000028:	44913423          	sd	s1,1096(sp)
    8000002c:	45213023          	sd	s2,1088(sp)
    80000030:	43313c23          	sd	s3,1080(sp)
    80000034:	43413823          	sd	s4,1072(sp)
    80000038:	46010413          	addi	s0,sp,1120
    uint64 recovery_load_addr = find_kernel_load_addr(RECOVERY);
    8000003c:	4505                	li	a0,1
    8000003e:	00000097          	auipc	ra,0x0
    80000042:	4ec080e7          	jalr	1260(ra) # 8000052a <find_kernel_load_addr>
    80000046:	892a                	mv	s2,a0
    uint64 recovery_binary_size = find_kernel_size(RECOVERY);
    80000048:	4505                	li	a0,1
    8000004a:	00000097          	auipc	ra,0x0
    8000004e:	518080e7          	jalr	1304(ra) # 80000562 <find_kernel_size>
    80000052:	84aa                	mv	s1,a0
    uint64 recovery_kernel_entry = find_kernel_entry_addr(RECOVERY);
    80000054:	4505                	li	a0,1
    80000056:	00000097          	auipc	ra,0x0
    8000005a:	540080e7          	jalr	1344(ra) # 80000596 <find_kernel_entry_addr>
    8000005e:	8a2a                	mv	s4,a0

    struct buf ker_buff;

    uint64 skip_memory = 4096/BSIZE;

    for(int p = skip_memory; p< recovery_total_size; ++p)
    80000060:	6785                	lui	a5,0x1
    80000062:	3ff78793          	addi	a5,a5,1023 # 13ff <_entry-0x7fffec01>
    80000066:	0297fc63          	bgeu	a5,s1,8000009e <setup_recovery_kernel+0x82>
    8000006a:	00a4d993          	srli	s3,s1,0xa
    8000006e:	4491                	li	s1,4
    {
      ker_buff.blockno = p;
    80000070:	ba942a23          	sw	s1,-1100(s0)
      kernel_copy(RECOVERY, &ker_buff);
    80000074:	ba840593          	addi	a1,s0,-1112
    80000078:	4505                	li	a0,1
    8000007a:	00000097          	auipc	ra,0x0
    8000007e:	298080e7          	jalr	664(ra) # 80000312 <kernel_copy>
      uint64 kernel_value = recovery_load_addr;
      uint64 c = (p - skip_memory)*BSIZE;
      kernel_value = kernel_value + c;
      memmove((void *)kernel_value, ker_buff.data, BSIZE);
    80000082:	40000613          	li	a2,1024
    80000086:	bd040593          	addi	a1,s0,-1072
    8000008a:	854a                	mv	a0,s2
    8000008c:	00000097          	auipc	ra,0x0
    80000090:	356080e7          	jalr	854(ra) # 800003e2 <memmove>
    for(int p = skip_memory; p< recovery_total_size; ++p)
    80000094:	0485                	addi	s1,s1,1
    80000096:	40090913          	addi	s2,s2,1024
    8000009a:	fd34ebe3          	bltu	s1,s3,80000070 <setup_recovery_kernel+0x54>
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    8000009e:	341a1073          	csrw	mepc,s4
    }
    w_mepc( recovery_kernel_entry);
}
    800000a2:	45813083          	ld	ra,1112(sp)
    800000a6:	45013403          	ld	s0,1104(sp)
    800000aa:	44813483          	ld	s1,1096(sp)
    800000ae:	44013903          	ld	s2,1088(sp)
    800000b2:	43813983          	ld	s3,1080(sp)
    800000b6:	43013a03          	ld	s4,1072(sp)
    800000ba:	46010113          	addi	sp,sp,1120
    800000be:	8082                	ret

00000000800000c0 <is_secure_boot>:

/* CSE 536: Function verifies if NORMAL kernel is expected or tampered. */
bool is_secure_boot(void) {
    800000c0:	1101                	addi	sp,sp,-32
    800000c2:	ec06                	sd	ra,24(sp)
    800000c4:	e822                	sd	s0,16(sp)
    800000c6:	e426                	sd	s1,8(sp)
    800000c8:	e04a                	sd	s2,0(sp)
    800000ca:	1000                	addi	s0,sp,32
  bool verification = true;

  /* Read the binary and update the observed measurement 
   * (simplified template provided below) */
  sha256_init(&sha256_ctx);
    800000cc:	00001497          	auipc	s1,0x1
    800000d0:	ab448493          	addi	s1,s1,-1356 # 80000b80 <sha256_ctx>
    800000d4:	8526                	mv	a0,s1
    800000d6:	00000097          	auipc	ra,0x0
    800000da:	6ec080e7          	jalr	1772(ra) # 800007c2 <sha256_init>
  //struct buf b;
  sha256_update(&sha256_ctx, (const unsigned char*) RAMDISK, find_kernel_size(NORMAL));
    800000de:	4501                	li	a0,0
    800000e0:	00000097          	auipc	ra,0x0
    800000e4:	482080e7          	jalr	1154(ra) # 80000562 <find_kernel_size>
    800000e8:	862a                	mv	a2,a0
    800000ea:	02100593          	li	a1,33
    800000ee:	05ea                	slli	a1,a1,0x1a
    800000f0:	8526                	mv	a0,s1
    800000f2:	00000097          	auipc	ra,0x0
    800000f6:	734080e7          	jalr	1844(ra) # 80000826 <sha256_update>
  sha256_final(&sha256_ctx, sys_info_ptr->observed_kernel_measurement);
    800000fa:	00009917          	auipc	s2,0x9
    800000fe:	af690913          	addi	s2,s2,-1290 # 80008bf0 <sys_info_ptr>
    80000102:	00093583          	ld	a1,0(s2)
    80000106:	04058593          	addi	a1,a1,64 # 1040 <_entry-0x7fffefc0>
    8000010a:	8526                	mv	a0,s1
    8000010c:	00000097          	auipc	ra,0x0
    80000110:	79e080e7          	jalr	1950(ra) # 800008aa <sha256_final>

  /* Three more tasks required below: 
   *  1. Compare observed measurement with expected hash
   *  2. Setup the recovery kernel if comparison fails
   *  3. Copy expected kernel hash to the system information table */
  for(int i=0;i<32; i++)
    80000114:	00001717          	auipc	a4,0x1
    80000118:	92470713          	addi	a4,a4,-1756 # 80000a38 <trusted_kernel_hash>
    8000011c:	00093783          	ld	a5,0(s2)
    80000120:	04078793          	addi	a5,a5,64
    80000124:	00001517          	auipc	a0,0x1
    80000128:	93450513          	addi	a0,a0,-1740 # 80000a58 <k>
  bool verification = true;
    8000012c:	4485                	li	s1,1
  {
    if(sys_info_ptr->observed_kernel_measurement[i] != trusted_kernel_hash[i])
    {
      verification=false;
    8000012e:	4801                	li	a6,0
    80000130:	a039                	j	8000013e <is_secure_boot+0x7e>
    }
    sys_info_ptr->expected_kernel_measurement[i] = trusted_kernel_hash[i];
    80000132:	fed60023          	sb	a3,-32(a2)
  for(int i=0;i<32; i++)
    80000136:	0705                	addi	a4,a4,1
    80000138:	0785                	addi	a5,a5,1
    8000013a:	00a70b63          	beq	a4,a0,80000150 <is_secure_boot+0x90>
    if(sys_info_ptr->observed_kernel_measurement[i] != trusted_kernel_hash[i])
    8000013e:	863e                	mv	a2,a5
    80000140:	00074683          	lbu	a3,0(a4)
    80000144:	0007c583          	lbu	a1,0(a5)
    80000148:	fed585e3          	beq	a1,a3,80000132 <is_secure_boot+0x72>
      verification=false;
    8000014c:	84c2                	mv	s1,a6
    8000014e:	b7d5                	j	80000132 <is_secure_boot+0x72>
  }
  
  
  if (!verification)
    80000150:	c881                	beqz	s1,80000160 <is_secure_boot+0xa0>
    setup_recovery_kernel();
  
  return verification;
}
    80000152:	8526                	mv	a0,s1
    80000154:	60e2                	ld	ra,24(sp)
    80000156:	6442                	ld	s0,16(sp)
    80000158:	64a2                	ld	s1,8(sp)
    8000015a:	6902                	ld	s2,0(sp)
    8000015c:	6105                	addi	sp,sp,32
    8000015e:	8082                	ret
    setup_recovery_kernel();
    80000160:	00000097          	auipc	ra,0x0
    80000164:	ebc080e7          	jalr	-324(ra) # 8000001c <setup_recovery_kernel>
    80000168:	b7ed                	j	80000152 <is_secure_boot+0x92>

000000008000016a <start>:

// entry.S jumps here in machine mode on stack0.
void start()
{
    8000016a:	b9010113          	addi	sp,sp,-1136
    8000016e:	46113423          	sd	ra,1128(sp)
    80000172:	46813023          	sd	s0,1120(sp)
    80000176:	44913c23          	sd	s1,1112(sp)
    8000017a:	45213823          	sd	s2,1104(sp)
    8000017e:	45313423          	sd	s3,1096(sp)
    80000182:	45413023          	sd	s4,1088(sp)
    80000186:	43513c23          	sd	s5,1080(sp)
    8000018a:	43613823          	sd	s6,1072(sp)
    8000018e:	47010413          	addi	s0,sp,1136
  /* CSE 536: Define the system information table's location. */
  sys_info_ptr = (struct sys_info*) 0x80080000;
    80000192:	010017b7          	lui	a5,0x1001
    80000196:	079e                	slli	a5,a5,0x7
    80000198:	00009717          	auipc	a4,0x9
    8000019c:	a4f73c23          	sd	a5,-1448(a4) # 80008bf0 <sys_info_ptr>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001a0:	f14027f3          	csrr	a5,mhartid

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);
    800001a4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800001a6:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800001a8:	300027f3          	csrr	a5,mstatus

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
    800001ac:	7779                	lui	a4,0xffffe
    800001ae:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <kernel_elfhdr+0xffffffff7fff5bff>
    800001b2:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800001b4:	6705                	lui	a4,0x1
    800001b6:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800001ba:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800001bc:	30079073          	csrw	mstatus,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800001c0:	4781                	li	a5,0
    800001c2:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800001c6:	57fd                	li	a5,-1
    800001c8:	83a9                	srli	a5,a5,0xa
    800001ca:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800001ce:	47bd                	li	a5,15
    800001d0:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800001d4:	21d807b7          	lui	a5,0x21d80
    800001d8:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpaddr1, %0" : : "r" (x));
    800001dc:	21e407b7          	lui	a5,0x21e40
    800001e0:	17fd                	addi	a5,a5,-1 # 21e3ffff <_entry-0x5e1c0001>
    800001e2:	3b179073          	csrw	pmpaddr1,a5
  asm volatile("csrw pmpaddr2, %0" : : "r" (x));
    800001e6:	21fc07b7          	lui	a5,0x21fc0
    800001ea:	17fd                	addi	a5,a5,-1 # 21fbffff <_entry-0x5e040001>
    800001ec:	3b279073          	csrw	pmpaddr2,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800001f0:	001f27b7          	lui	a5,0x1f2
    800001f4:	f0f78793          	addi	a5,a5,-241 # 1f1f0f <_entry-0x7fe0e0f1>
    800001f8:	3a079073          	csrw	pmpcfg0,a5
    //w_pmpaddr0(0x0ull);
    //w_pmpcfg0(0x0);
  #endif

  /* CSE 536: Verify if the kernel is untampered for secure boot */
  if (!is_secure_boot()) {
    800001fc:	00000097          	auipc	ra,0x0
    80000200:	ec4080e7          	jalr	-316(ra) # 800000c0 <is_secure_boot>
    80000204:	e92d                	bnez	a0,80000276 <start+0x10c>
  /* CSE 536: Provide system information to the kernel. */

  /* CSE 536: Send the observed hash value to the kernel (using sys_info_ptr) */

  // delegate all interrupts and exceptions to supervisor mode.
  sys_info_ptr->dr_start = KERNBASE ;
    80000206:	00009617          	auipc	a2,0x9
    8000020a:	9ea60613          	addi	a2,a2,-1558 # 80008bf0 <sys_info_ptr>
    8000020e:	6218                	ld	a4,0(a2)
    80000210:	4785                	li	a5,1
    80000212:	07fe                	slli	a5,a5,0x1f
    80000214:	eb1c                	sd	a5,16(a4)
  sys_info_ptr->dr_end = PHYSTOP;
    80000216:	46c5                	li	a3,17
    80000218:	06ee                	slli	a3,a3,0x1b
    8000021a:	ef14                	sd	a3,24(a4)
  
  sys_info_ptr->bl_start = KERNBASE ;
    8000021c:	e31c                	sd	a5,0(a4)
  sys_info_ptr->bl_end = end;
    8000021e:	621c                	ld	a5,0(a2)
    80000220:	00009717          	auipc	a4,0x9
    80000224:	9d073703          	ld	a4,-1584(a4) # 80008bf0 <sys_info_ptr>
    80000228:	e798                	sd	a4,8(a5)
  asm volatile("csrw medeleg, %0" : : "r" (x));
    8000022a:	67c1                	lui	a5,0x10
    8000022c:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    8000022e:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000232:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000236:	104027f3          	csrr	a5,sie
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000023a:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    8000023e:	10479073          	csrw	sie,a5

  // return address fix
  uint64 addr = (uint64) panic;
  asm volatile("mv ra, %0" : : "r" (addr));
    80000242:	00000797          	auipc	a5,0x0
    80000246:	dd278793          	addi	a5,a5,-558 # 80000014 <panic>
    8000024a:	80be                	mv	ra,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
    8000024c:	30200073          	mret
}
    80000250:	46813083          	ld	ra,1128(sp)
    80000254:	46013403          	ld	s0,1120(sp)
    80000258:	45813483          	ld	s1,1112(sp)
    8000025c:	45013903          	ld	s2,1104(sp)
    80000260:	44813983          	ld	s3,1096(sp)
    80000264:	44013a03          	ld	s4,1088(sp)
    80000268:	43813a83          	ld	s5,1080(sp)
    8000026c:	43013b03          	ld	s6,1072(sp)
    80000270:	47010113          	addi	sp,sp,1136
    80000274:	8082                	ret
  uint64 kernel_load_addr       = find_kernel_load_addr(NORMAL);
    80000276:	4501                	li	a0,0
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	2b2080e7          	jalr	690(ra) # 8000052a <find_kernel_load_addr>
    80000280:	8a2a                	mv	s4,a0
  uint64 kernel_binary_size     = find_kernel_size(NORMAL);     
    80000282:	4501                	li	a0,0
    80000284:	00000097          	auipc	ra,0x0
    80000288:	2de080e7          	jalr	734(ra) # 80000562 <find_kernel_size>
    8000028c:	84aa                	mv	s1,a0
  uint64 kernel_entry           = find_kernel_entry_addr(NORMAL);
    8000028e:	4501                	li	a0,0
    80000290:	00000097          	auipc	ra,0x0
    80000294:	306080e7          	jalr	774(ra) # 80000596 <find_kernel_entry_addr>
    80000298:	8aaa                	mv	s5,a0
  uint64 balance = kernel_binary_size%BSIZE;
    8000029a:	3ff4fb13          	andi	s6,s1,1023
  uint64 total_size = kernel_binary_size/BSIZE;
    8000029e:	00a4d993          	srli	s3,s1,0xa
  for(int p = skip_memory; p< total_size; p++)
    800002a2:	6785                	lui	a5,0x1
    800002a4:	3ff78793          	addi	a5,a5,1023 # 13ff <_entry-0x7fffec01>
    800002a8:	0297fb63          	bgeu	a5,s1,800002de <start+0x174>
    800002ac:	8952                	mv	s2,s4
    800002ae:	4491                	li	s1,4
    ker_buf.blockno = p;
    800002b0:	ba942223          	sw	s1,-1116(s0)
    kernel_copy(NORMAL, &ker_buf);
    800002b4:	b9840593          	addi	a1,s0,-1128
    800002b8:	4501                	li	a0,0
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	058080e7          	jalr	88(ra) # 80000312 <kernel_copy>
    memmove((void *)kernel_value, ker_buf.data, BSIZE);
    800002c2:	40000613          	li	a2,1024
    800002c6:	bc040593          	addi	a1,s0,-1088
    800002ca:	854a                	mv	a0,s2
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	116080e7          	jalr	278(ra) # 800003e2 <memmove>
  for(int p = skip_memory; p< total_size; p++)
    800002d4:	0485                	addi	s1,s1,1
    800002d6:	40090913          	addi	s2,s2,1024
    800002da:	fd34ebe3          	bltu	s1,s3,800002b0 <start+0x146>
  if(balance!=0)
    800002de:	000b1563          	bnez	s6,800002e8 <start+0x17e>
  asm volatile("csrw mepc, %0" : : "r" (x));
    800002e2:	341a9073          	csrw	mepc,s5
}
    800002e6:	b705                	j	80000206 <start+0x9c>
    ker_buf.blockno = total_size;
    800002e8:	bb342223          	sw	s3,-1116(s0)
    kernel_copy(NORMAL, &ker_buf);
    800002ec:	b9840593          	addi	a1,s0,-1128
    800002f0:	4501                	li	a0,0
    800002f2:	00000097          	auipc	ra,0x0
    800002f6:	020080e7          	jalr	32(ra) # 80000312 <kernel_copy>
    uint64 c = (total_size - skip_memory)*BSIZE;
    800002fa:	19f1                	addi	s3,s3,-4
    800002fc:	09aa                	slli	s3,s3,0xa
    memmove((void *)kernel_value, ker_buf.data, balance);
    800002fe:	865a                	mv	a2,s6
    80000300:	bc040593          	addi	a1,s0,-1088
    80000304:	01498533          	add	a0,s3,s4
    80000308:	00000097          	auipc	ra,0x0
    8000030c:	0da080e7          	jalr	218(ra) # 800003e2 <memmove>
    80000310:	bfc9                	j	800002e2 <start+0x178>

0000000080000312 <kernel_copy>:
#include "layout.h"
#include "buf.h"

/* In-built function to load NORMAL/RECOVERY kernels */
void kernel_copy(enum kernel ktype, struct buf *b)
{
    80000312:	1101                	addi	sp,sp,-32
    80000314:	ec06                	sd	ra,24(sp)
    80000316:	e822                	sd	s0,16(sp)
    80000318:	e426                	sd	s1,8(sp)
    8000031a:	e04a                	sd	s2,0(sp)
    8000031c:	1000                	addi	s0,sp,32
    8000031e:	892a                	mv	s2,a0
    80000320:	84ae                	mv	s1,a1
  if(b->blockno >= FSSIZE)
    80000322:	45d8                	lw	a4,12(a1)
    80000324:	7cf00793          	li	a5,1999
    80000328:	02e7ed63          	bltu	a5,a4,80000362 <kernel_copy+0x50>
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    8000032c:	44dc                	lw	a5,12(s1)
    8000032e:	00a7979b          	slliw	a5,a5,0xa
    80000332:	1782                	slli	a5,a5,0x20
    80000334:	9381                	srli	a5,a5,0x20
  char* addr = 0x0; 
  
  if (ktype == NORMAL)
    80000336:	02091f63          	bnez	s2,80000374 <kernel_copy+0x62>
    addr = (char *)RAMDISK + diskaddr;
    8000033a:	02100593          	li	a1,33
    8000033e:	05ea                	slli	a1,a1,0x1a
    80000340:	95be                	add	a1,a1,a5
  else if (ktype == RECOVERY)
    addr = (char *)RECOVERYDISK + diskaddr;

  memmove(b->data, addr, BSIZE);
    80000342:	40000613          	li	a2,1024
    80000346:	02848513          	addi	a0,s1,40
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	098080e7          	jalr	152(ra) # 800003e2 <memmove>
  b->valid = 1;
    80000352:	4785                	li	a5,1
    80000354:	c09c                	sw	a5,0(s1)
    80000356:	60e2                	ld	ra,24(sp)
    80000358:	6442                	ld	s0,16(sp)
    8000035a:	64a2                	ld	s1,8(sp)
    8000035c:	6902                	ld	s2,0(sp)
    8000035e:	6105                	addi	sp,sp,32
    80000360:	8082                	ret
    panic("ramdiskrw: blockno too big");
    80000362:	00000517          	auipc	a0,0x0
    80000366:	7f650513          	addi	a0,a0,2038 # 80000b58 <rodata>
    8000036a:	00000097          	auipc	ra,0x0
    8000036e:	caa080e7          	jalr	-854(ra) # 80000014 <panic>
    80000372:	bf6d                	j	8000032c <kernel_copy+0x1a>
  else if (ktype == RECOVERY)
    80000374:	4705                	li	a4,1
  char* addr = 0x0; 
    80000376:	4581                	li	a1,0
  else if (ktype == RECOVERY)
    80000378:	fce915e3          	bne	s2,a4,80000342 <kernel_copy+0x30>
    addr = (char *)RECOVERYDISK + diskaddr;
    8000037c:	008455b7          	lui	a1,0x845
    80000380:	05a2                	slli	a1,a1,0x8
    80000382:	95be                	add	a1,a1,a5
    80000384:	bf7d                	j	80000342 <kernel_copy+0x30>

0000000080000386 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000386:	1141                	addi	sp,sp,-16
    80000388:	e422                	sd	s0,8(sp)
    8000038a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    8000038c:	ca19                	beqz	a2,800003a2 <memset+0x1c>
    8000038e:	87aa                	mv	a5,a0
    80000390:	1602                	slli	a2,a2,0x20
    80000392:	9201                	srli	a2,a2,0x20
    80000394:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000398:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    8000039c:	0785                	addi	a5,a5,1
    8000039e:	fee79de3          	bne	a5,a4,80000398 <memset+0x12>
  }
  return dst;
}
    800003a2:	6422                	ld	s0,8(sp)
    800003a4:	0141                	addi	sp,sp,16
    800003a6:	8082                	ret

00000000800003a8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800003a8:	1141                	addi	sp,sp,-16
    800003aa:	e422                	sd	s0,8(sp)
    800003ac:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800003ae:	ca05                	beqz	a2,800003de <memcmp+0x36>
    800003b0:	fff6069b          	addiw	a3,a2,-1
    800003b4:	1682                	slli	a3,a3,0x20
    800003b6:	9281                	srli	a3,a3,0x20
    800003b8:	0685                	addi	a3,a3,1
    800003ba:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800003bc:	00054783          	lbu	a5,0(a0)
    800003c0:	0005c703          	lbu	a4,0(a1) # 845000 <_entry-0x7f7bb000>
    800003c4:	00e79863          	bne	a5,a4,800003d4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    800003c8:	0505                	addi	a0,a0,1
    800003ca:	0585                	addi	a1,a1,1
  while(n-- > 0){
    800003cc:	fed518e3          	bne	a0,a3,800003bc <memcmp+0x14>
  }

  return 0;
    800003d0:	4501                	li	a0,0
    800003d2:	a019                	j	800003d8 <memcmp+0x30>
      return *s1 - *s2;
    800003d4:	40e7853b          	subw	a0,a5,a4
}
    800003d8:	6422                	ld	s0,8(sp)
    800003da:	0141                	addi	sp,sp,16
    800003dc:	8082                	ret
  return 0;
    800003de:	4501                	li	a0,0
    800003e0:	bfe5                	j	800003d8 <memcmp+0x30>

00000000800003e2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800003e2:	1141                	addi	sp,sp,-16
    800003e4:	e422                	sd	s0,8(sp)
    800003e6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    800003e8:	c205                	beqz	a2,80000408 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    800003ea:	02a5e263          	bltu	a1,a0,8000040e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800003ee:	1602                	slli	a2,a2,0x20
    800003f0:	9201                	srli	a2,a2,0x20
    800003f2:	00c587b3          	add	a5,a1,a2
{
    800003f6:	872a                	mv	a4,a0
      *d++ = *s++;
    800003f8:	0585                	addi	a1,a1,1
    800003fa:	0705                	addi	a4,a4,1
    800003fc:	fff5c683          	lbu	a3,-1(a1)
    80000400:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000404:	fef59ae3          	bne	a1,a5,800003f8 <memmove+0x16>

  return dst;
}
    80000408:	6422                	ld	s0,8(sp)
    8000040a:	0141                	addi	sp,sp,16
    8000040c:	8082                	ret
  if(s < d && s + n > d){
    8000040e:	02061693          	slli	a3,a2,0x20
    80000412:	9281                	srli	a3,a3,0x20
    80000414:	00d58733          	add	a4,a1,a3
    80000418:	fce57be3          	bgeu	a0,a4,800003ee <memmove+0xc>
    d += n;
    8000041c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    8000041e:	fff6079b          	addiw	a5,a2,-1
    80000422:	1782                	slli	a5,a5,0x20
    80000424:	9381                	srli	a5,a5,0x20
    80000426:	fff7c793          	not	a5,a5
    8000042a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    8000042c:	177d                	addi	a4,a4,-1
    8000042e:	16fd                	addi	a3,a3,-1
    80000430:	00074603          	lbu	a2,0(a4)
    80000434:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000438:	fee79ae3          	bne	a5,a4,8000042c <memmove+0x4a>
    8000043c:	b7f1                	j	80000408 <memmove+0x26>

000000008000043e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000043e:	1141                	addi	sp,sp,-16
    80000440:	e406                	sd	ra,8(sp)
    80000442:	e022                	sd	s0,0(sp)
    80000444:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000446:	00000097          	auipc	ra,0x0
    8000044a:	f9c080e7          	jalr	-100(ra) # 800003e2 <memmove>
}
    8000044e:	60a2                	ld	ra,8(sp)
    80000450:	6402                	ld	s0,0(sp)
    80000452:	0141                	addi	sp,sp,16
    80000454:	8082                	ret

0000000080000456 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e422                	sd	s0,8(sp)
    8000045a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000045c:	ce11                	beqz	a2,80000478 <strncmp+0x22>
    8000045e:	00054783          	lbu	a5,0(a0)
    80000462:	cf89                	beqz	a5,8000047c <strncmp+0x26>
    80000464:	0005c703          	lbu	a4,0(a1)
    80000468:	00f71a63          	bne	a4,a5,8000047c <strncmp+0x26>
    n--, p++, q++;
    8000046c:	367d                	addiw	a2,a2,-1
    8000046e:	0505                	addi	a0,a0,1
    80000470:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000472:	f675                	bnez	a2,8000045e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000474:	4501                	li	a0,0
    80000476:	a809                	j	80000488 <strncmp+0x32>
    80000478:	4501                	li	a0,0
    8000047a:	a039                	j	80000488 <strncmp+0x32>
  if(n == 0)
    8000047c:	ca09                	beqz	a2,8000048e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000047e:	00054503          	lbu	a0,0(a0)
    80000482:	0005c783          	lbu	a5,0(a1)
    80000486:	9d1d                	subw	a0,a0,a5
}
    80000488:	6422                	ld	s0,8(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret
    return 0;
    8000048e:	4501                	li	a0,0
    80000490:	bfe5                	j	80000488 <strncmp+0x32>

0000000080000492 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000492:	1141                	addi	sp,sp,-16
    80000494:	e422                	sd	s0,8(sp)
    80000496:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000498:	87aa                	mv	a5,a0
    8000049a:	86b2                	mv	a3,a2
    8000049c:	367d                	addiw	a2,a2,-1
    8000049e:	00d05963          	blez	a3,800004b0 <strncpy+0x1e>
    800004a2:	0785                	addi	a5,a5,1
    800004a4:	0005c703          	lbu	a4,0(a1)
    800004a8:	fee78fa3          	sb	a4,-1(a5)
    800004ac:	0585                	addi	a1,a1,1
    800004ae:	f775                	bnez	a4,8000049a <strncpy+0x8>
    ;
  while(n-- > 0)
    800004b0:	873e                	mv	a4,a5
    800004b2:	9fb5                	addw	a5,a5,a3
    800004b4:	37fd                	addiw	a5,a5,-1
    800004b6:	00c05963          	blez	a2,800004c8 <strncpy+0x36>
    *s++ = 0;
    800004ba:	0705                	addi	a4,a4,1
    800004bc:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    800004c0:	40e786bb          	subw	a3,a5,a4
    800004c4:	fed04be3          	bgtz	a3,800004ba <strncpy+0x28>
  return os;
}
    800004c8:	6422                	ld	s0,8(sp)
    800004ca:	0141                	addi	sp,sp,16
    800004cc:	8082                	ret

00000000800004ce <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800004ce:	1141                	addi	sp,sp,-16
    800004d0:	e422                	sd	s0,8(sp)
    800004d2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800004d4:	02c05363          	blez	a2,800004fa <safestrcpy+0x2c>
    800004d8:	fff6069b          	addiw	a3,a2,-1
    800004dc:	1682                	slli	a3,a3,0x20
    800004de:	9281                	srli	a3,a3,0x20
    800004e0:	96ae                	add	a3,a3,a1
    800004e2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800004e4:	00d58963          	beq	a1,a3,800004f6 <safestrcpy+0x28>
    800004e8:	0585                	addi	a1,a1,1
    800004ea:	0785                	addi	a5,a5,1
    800004ec:	fff5c703          	lbu	a4,-1(a1)
    800004f0:	fee78fa3          	sb	a4,-1(a5)
    800004f4:	fb65                	bnez	a4,800004e4 <safestrcpy+0x16>
    ;
  *s = 0;
    800004f6:	00078023          	sb	zero,0(a5)
  return os;
}
    800004fa:	6422                	ld	s0,8(sp)
    800004fc:	0141                	addi	sp,sp,16
    800004fe:	8082                	ret

0000000080000500 <strlen>:

int
strlen(const char *s)
{
    80000500:	1141                	addi	sp,sp,-16
    80000502:	e422                	sd	s0,8(sp)
    80000504:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000506:	00054783          	lbu	a5,0(a0)
    8000050a:	cf91                	beqz	a5,80000526 <strlen+0x26>
    8000050c:	0505                	addi	a0,a0,1
    8000050e:	87aa                	mv	a5,a0
    80000510:	86be                	mv	a3,a5
    80000512:	0785                	addi	a5,a5,1
    80000514:	fff7c703          	lbu	a4,-1(a5)
    80000518:	ff65                	bnez	a4,80000510 <strlen+0x10>
    8000051a:	40a6853b          	subw	a0,a3,a0
    8000051e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000520:	6422                	ld	s0,8(sp)
    80000522:	0141                	addi	sp,sp,16
    80000524:	8082                	ret
  for(n = 0; s[n]; n++)
    80000526:	4501                	li	a0,0
    80000528:	bfe5                	j	80000520 <strlen+0x20>

000000008000052a <find_kernel_load_addr>:
#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(enum kernel ktype) {
    8000052a:	1141                	addi	sp,sp,-16
    8000052c:	e422                	sd	s0,8(sp)
    8000052e:	0800                	addi	s0,sp,16
    /* CSE 536: Get kernel load address from headers */
    uint64 a = 0;

    if (ktype == NORMAL)
    80000530:	e50d                	bnez	a0,8000055a <find_kernel_load_addr+0x30>
    {
        a = RAMDISK;
    80000532:	02100713          	li	a4,33
    80000536:	076a                	slli	a4,a4,0x1a
    else
    {
        a = RECOVERYDISK;
    }

    kernel_elfhdr = (struct elfhdr*) a;
    80000538:	00008797          	auipc	a5,0x8
    8000053c:	6ce7b423          	sd	a4,1736(a5) # 80008c00 <kernel_elfhdr>
    uint64 address_phoff = kernel_elfhdr->phoff;
    uint64 address_ehsize = kernel_elfhdr->ehsize;
    
    
    kernel_phdr = (struct proghdr*) (a + address_ehsize + address_phoff);
    80000540:	731c                	ld	a5,32(a4)
    80000542:	97ba                	add	a5,a5,a4
    uint64 address_ehsize = kernel_elfhdr->ehsize;
    80000544:	03475703          	lhu	a4,52(a4)
    kernel_phdr = (struct proghdr*) (a + address_ehsize + address_phoff);
    80000548:	97ba                	add	a5,a5,a4
    8000054a:	00008717          	auipc	a4,0x8
    8000054e:	6af73723          	sd	a5,1710(a4) # 80008bf8 <kernel_phdr>
    uint64 res = kernel_phdr->vaddr;
    return res;
}
    80000552:	6b88                	ld	a0,16(a5)
    80000554:	6422                	ld	s0,8(sp)
    80000556:	0141                	addi	sp,sp,16
    80000558:	8082                	ret
        a = RECOVERYDISK;
    8000055a:	00845737          	lui	a4,0x845
    8000055e:	0722                	slli	a4,a4,0x8
    80000560:	bfe1                	j	80000538 <find_kernel_load_addr+0xe>

0000000080000562 <find_kernel_size>:

uint64 find_kernel_size(enum kernel ktype) {
    80000562:	1141                	addi	sp,sp,-16
    80000564:	e422                	sd	s0,8(sp)
    80000566:	0800                	addi	s0,sp,16
    /* CSE 536: Get kernel binary size from headers */
    uint64 d = 0;

    if (ktype == NORMAL)
    80000568:	e11d                	bnez	a0,8000058e <find_kernel_size+0x2c>
    {
        d = RAMDISK;
    8000056a:	02100793          	li	a5,33
    8000056e:	07ea                	slli	a5,a5,0x1a
    else
    {
        d = RECOVERYDISK;
    }

    kernel_elfhdr = (struct elfhdr*) d;
    80000570:	00008717          	auipc	a4,0x8
    80000574:	68f73823          	sd	a5,1680(a4) # 80008c00 <kernel_elfhdr>
    uint64 a = kernel_elfhdr->shoff;
    uint64 b = kernel_elfhdr->shentsize;
    uint64 c = b * (kernel_elfhdr->shnum);
    80000578:	03c7d703          	lhu	a4,60(a5)
    uint64 b = kernel_elfhdr->shentsize;
    8000057c:	03a7d683          	lhu	a3,58(a5)
    uint64 c = b * (kernel_elfhdr->shnum);
    80000580:	02d70733          	mul	a4,a4,a3
    return (a + c);
    80000584:	7788                	ld	a0,40(a5)
}
    80000586:	953a                	add	a0,a0,a4
    80000588:	6422                	ld	s0,8(sp)
    8000058a:	0141                	addi	sp,sp,16
    8000058c:	8082                	ret
        d = RECOVERYDISK;
    8000058e:	008457b7          	lui	a5,0x845
    80000592:	07a2                	slli	a5,a5,0x8
    80000594:	bff1                	j	80000570 <find_kernel_size+0xe>

0000000080000596 <find_kernel_entry_addr>:

uint64 find_kernel_entry_addr(enum kernel ktype) {
    80000596:	1141                	addi	sp,sp,-16
    80000598:	e422                	sd	s0,8(sp)
    8000059a:	0800                	addi	s0,sp,16
    /* CSE 536: Get kernel entry point from headers */
    uint64 a = 0;

    if (ktype == NORMAL)
    8000059c:	ed01                	bnez	a0,800005b4 <find_kernel_entry_addr+0x1e>
    {
        a = RAMDISK;
    8000059e:	02100793          	li	a5,33
    800005a2:	07ea                	slli	a5,a5,0x1a
    else
    {
        a = RECOVERYDISK;
    }

    kernel_elfhdr = (struct elfhdr*) a;
    800005a4:	00008717          	auipc	a4,0x8
    800005a8:	64f73e23          	sd	a5,1628(a4) # 80008c00 <kernel_elfhdr>
    return kernel_elfhdr->entry;
}
    800005ac:	6f88                	ld	a0,24(a5)
    800005ae:	6422                	ld	s0,8(sp)
    800005b0:	0141                	addi	sp,sp,16
    800005b2:	8082                	ret
        a = RECOVERYDISK;
    800005b4:	008457b7          	lui	a5,0x845
    800005b8:	07a2                	slli	a5,a5,0x8
    800005ba:	b7ed                	j	800005a4 <find_kernel_entry_addr+0xe>

00000000800005bc <sha256_transform>:
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

/*********************** FUNCTION DEFINITIONS ***********************/
void sha256_transform(SHA256_CTX *ctx, const BYTE data[])
{
    800005bc:	710d                	addi	sp,sp,-352
    800005be:	eea2                	sd	s0,344(sp)
    800005c0:	eaa6                	sd	s1,336(sp)
    800005c2:	e6ca                	sd	s2,328(sp)
    800005c4:	e2ce                	sd	s3,320(sp)
    800005c6:	fe52                	sd	s4,312(sp)
    800005c8:	fa56                	sd	s5,304(sp)
    800005ca:	f65a                	sd	s6,296(sp)
    800005cc:	f25e                	sd	s7,288(sp)
    800005ce:	ee62                	sd	s8,280(sp)
    800005d0:	ea66                	sd	s9,272(sp)
    800005d2:	e66a                	sd	s10,264(sp)
    800005d4:	e26e                	sd	s11,256(sp)
    800005d6:	1280                	addi	s0,sp,352
	WORD a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

	for (i = 0, j = 0; i < 16; ++i, j += 4)
    800005d8:	ea040e13          	addi	t3,s0,-352
    800005dc:	ee040613          	addi	a2,s0,-288
{
    800005e0:	8772                	mv	a4,t3
		m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
    800005e2:	0005c783          	lbu	a5,0(a1)
    800005e6:	0187979b          	slliw	a5,a5,0x18
    800005ea:	0015c683          	lbu	a3,1(a1)
    800005ee:	0106969b          	slliw	a3,a3,0x10
    800005f2:	8fd5                	or	a5,a5,a3
    800005f4:	0035c683          	lbu	a3,3(a1)
    800005f8:	8fd5                	or	a5,a5,a3
    800005fa:	0025c683          	lbu	a3,2(a1)
    800005fe:	0086969b          	slliw	a3,a3,0x8
    80000602:	8fd5                	or	a5,a5,a3
    80000604:	c31c                	sw	a5,0(a4)
	for (i = 0, j = 0; i < 16; ++i, j += 4)
    80000606:	0591                	addi	a1,a1,4
    80000608:	0711                	addi	a4,a4,4
    8000060a:	fcc71ce3          	bne	a4,a2,800005e2 <sha256_transform+0x26>
	for ( ; i < 64; ++i)
    8000060e:	0c0e0893          	addi	a7,t3,192
	for (i = 0, j = 0; i < 16; ++i, j += 4)
    80000612:	87f2                	mv	a5,t3
		m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];
    80000614:	5f98                	lw	a4,56(a5)
    80000616:	43d0                	lw	a2,4(a5)
    80000618:	00f7169b          	slliw	a3,a4,0xf
    8000061c:	0117559b          	srliw	a1,a4,0x11
    80000620:	8ecd                	or	a3,a3,a1
    80000622:	00d7159b          	slliw	a1,a4,0xd
    80000626:	0137581b          	srliw	a6,a4,0x13
    8000062a:	0105e5b3          	or	a1,a1,a6
    8000062e:	8ead                	xor	a3,a3,a1
    80000630:	00a7571b          	srliw	a4,a4,0xa
    80000634:	8eb9                	xor	a3,a3,a4
    80000636:	53cc                	lw	a1,36(a5)
    80000638:	4398                	lw	a4,0(a5)
    8000063a:	9f2d                	addw	a4,a4,a1
    8000063c:	9f35                	addw	a4,a4,a3
    8000063e:	0076569b          	srliw	a3,a2,0x7
    80000642:	0196159b          	slliw	a1,a2,0x19
    80000646:	8ecd                	or	a3,a3,a1
    80000648:	00e6159b          	slliw	a1,a2,0xe
    8000064c:	0126581b          	srliw	a6,a2,0x12
    80000650:	0105e5b3          	or	a1,a1,a6
    80000654:	8ead                	xor	a3,a3,a1
    80000656:	0036561b          	srliw	a2,a2,0x3
    8000065a:	8eb1                	xor	a3,a3,a2
    8000065c:	9f35                	addw	a4,a4,a3
    8000065e:	c3b8                	sw	a4,64(a5)
	for ( ; i < 64; ++i)
    80000660:	0791                	addi	a5,a5,4 # 845004 <_entry-0x7f7baffc>
    80000662:	fb1799e3          	bne	a5,a7,80000614 <sha256_transform+0x58>

	a = ctx->state[0];
    80000666:	05052b03          	lw	s6,80(a0)
	b = ctx->state[1];
    8000066a:	05452a83          	lw	s5,84(a0)
	c = ctx->state[2];
    8000066e:	05852a03          	lw	s4,88(a0)
	d = ctx->state[3];
    80000672:	05c52983          	lw	s3,92(a0)
	e = ctx->state[4];
    80000676:	06052903          	lw	s2,96(a0)
	f = ctx->state[5];
    8000067a:	5164                	lw	s1,100(a0)
	g = ctx->state[6];
    8000067c:	06852383          	lw	t2,104(a0)
	h = ctx->state[7];
    80000680:	06c52283          	lw	t0,108(a0)

	for (i = 0; i < 64; ++i) {
    80000684:	00000317          	auipc	t1,0x0
    80000688:	3d430313          	addi	t1,t1,980 # 80000a58 <k>
    8000068c:	00000f97          	auipc	t6,0x0
    80000690:	4ccf8f93          	addi	t6,t6,1228 # 80000b58 <rodata>
	h = ctx->state[7];
    80000694:	8b96                	mv	s7,t0
	g = ctx->state[6];
    80000696:	8e9e                	mv	t4,t2
	f = ctx->state[5];
    80000698:	8826                	mv	a6,s1
	e = ctx->state[4];
    8000069a:	86ca                	mv	a3,s2
	d = ctx->state[3];
    8000069c:	8f4e                	mv	t5,s3
	c = ctx->state[2];
    8000069e:	88d2                	mv	a7,s4
	b = ctx->state[1];
    800006a0:	85d6                	mv	a1,s5
	a = ctx->state[0];
    800006a2:	865a                	mv	a2,s6
    800006a4:	a039                	j	800006b2 <sha256_transform+0xf6>
    800006a6:	8ec2                	mv	t4,a6
    800006a8:	883a                	mv	a6,a4
		t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];
		t2 = EP0(a) + MAJ(a,b,c);
		h = g;
		g = f;
		f = e;
		e = d + t1;
    800006aa:	86e6                	mv	a3,s9
    800006ac:	88ae                	mv	a7,a1
    800006ae:	85ea                	mv	a1,s10
		d = c;
		c = b;
		b = a;
		a = t1 + t2;
    800006b0:	866e                	mv	a2,s11
		t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];
    800006b2:	0066d71b          	srliw	a4,a3,0x6
    800006b6:	01a6979b          	slliw	a5,a3,0x1a
    800006ba:	8f5d                	or	a4,a4,a5
    800006bc:	00b6d79b          	srliw	a5,a3,0xb
    800006c0:	01569c1b          	slliw	s8,a3,0x15
    800006c4:	0187e7b3          	or	a5,a5,s8
    800006c8:	8f3d                	xor	a4,a4,a5
    800006ca:	0076979b          	slliw	a5,a3,0x7
    800006ce:	0196dc1b          	srliw	s8,a3,0x19
    800006d2:	0187e7b3          	or	a5,a5,s8
    800006d6:	8f3d                	xor	a4,a4,a5
    800006d8:	00032c03          	lw	s8,0(t1)
    800006dc:	000e2783          	lw	a5,0(t3)
    800006e0:	018787bb          	addw	a5,a5,s8
    800006e4:	9fb9                	addw	a5,a5,a4
    800006e6:	fff6c713          	not	a4,a3
    800006ea:	01d77733          	and	a4,a4,t4
    800006ee:	0106fc33          	and	s8,a3,a6
    800006f2:	01874733          	xor	a4,a4,s8
    800006f6:	9fb9                	addw	a5,a5,a4
    800006f8:	017787bb          	addw	a5,a5,s7
		t2 = EP0(a) + MAJ(a,b,c);
    800006fc:	0026571b          	srliw	a4,a2,0x2
    80000700:	01e61b9b          	slliw	s7,a2,0x1e
    80000704:	01776733          	or	a4,a4,s7
    80000708:	00d65b9b          	srliw	s7,a2,0xd
    8000070c:	01361c1b          	slliw	s8,a2,0x13
    80000710:	018bebb3          	or	s7,s7,s8
    80000714:	01774733          	xor	a4,a4,s7
    80000718:	00a61b9b          	slliw	s7,a2,0xa
    8000071c:	01665c1b          	srliw	s8,a2,0x16
    80000720:	018bebb3          	or	s7,s7,s8
    80000724:	01774733          	xor	a4,a4,s7
    80000728:	0115cbb3          	xor	s7,a1,a7
    8000072c:	01767bb3          	and	s7,a2,s7
    80000730:	0115fc33          	and	s8,a1,a7
    80000734:	018bcbb3          	xor	s7,s7,s8
    80000738:	0177073b          	addw	a4,a4,s7
		e = d + t1;
    8000073c:	2681                	sext.w	a3,a3
    8000073e:	01e78c3b          	addw	s8,a5,t5
    80000742:	000c0c9b          	sext.w	s9,s8
		a = t1 + t2;
    80000746:	2601                	sext.w	a2,a2
    80000748:	9fb9                	addw	a5,a5,a4
    8000074a:	00078d9b          	sext.w	s11,a5
	for (i = 0; i < 64; ++i) {
    8000074e:	0311                	addi	t1,t1,4
    80000750:	0e11                	addi	t3,t3,4
    80000752:	00060d1b          	sext.w	s10,a2
    80000756:	2581                	sext.w	a1,a1
    80000758:	00088f1b          	sext.w	t5,a7
    8000075c:	0006871b          	sext.w	a4,a3
    80000760:	2801                	sext.w	a6,a6
    80000762:	000e8b9b          	sext.w	s7,t4
    80000766:	f5f310e3          	bne	t1,t6,800006a6 <sha256_transform+0xea>
	}

	ctx->state[0] += a;
    8000076a:	00fb0b3b          	addw	s6,s6,a5
    8000076e:	05652823          	sw	s6,80(a0)
	ctx->state[1] += b;
    80000772:	00ca8abb          	addw	s5,s5,a2
    80000776:	05552a23          	sw	s5,84(a0)
	ctx->state[2] += c;
    8000077a:	00ba0a3b          	addw	s4,s4,a1
    8000077e:	05452c23          	sw	s4,88(a0)
	ctx->state[3] += d;
    80000782:	011989bb          	addw	s3,s3,a7
    80000786:	05352e23          	sw	s3,92(a0)
	ctx->state[4] += e;
    8000078a:	0189093b          	addw	s2,s2,s8
    8000078e:	07252023          	sw	s2,96(a0)
	ctx->state[5] += f;
    80000792:	9cb5                	addw	s1,s1,a3
    80000794:	d164                	sw	s1,100(a0)
	ctx->state[6] += g;
    80000796:	010383bb          	addw	t2,t2,a6
    8000079a:	06752423          	sw	t2,104(a0)
	ctx->state[7] += h;
    8000079e:	01d282bb          	addw	t0,t0,t4
    800007a2:	06552623          	sw	t0,108(a0)
}
    800007a6:	6476                	ld	s0,344(sp)
    800007a8:	64d6                	ld	s1,336(sp)
    800007aa:	6936                	ld	s2,328(sp)
    800007ac:	6996                	ld	s3,320(sp)
    800007ae:	7a72                	ld	s4,312(sp)
    800007b0:	7ad2                	ld	s5,304(sp)
    800007b2:	7b32                	ld	s6,296(sp)
    800007b4:	7b92                	ld	s7,288(sp)
    800007b6:	6c72                	ld	s8,280(sp)
    800007b8:	6cd2                	ld	s9,272(sp)
    800007ba:	6d32                	ld	s10,264(sp)
    800007bc:	6d92                	ld	s11,256(sp)
    800007be:	6135                	addi	sp,sp,352
    800007c0:	8082                	ret

00000000800007c2 <sha256_init>:

void sha256_init(SHA256_CTX *ctx)
{
    800007c2:	1141                	addi	sp,sp,-16
    800007c4:	e422                	sd	s0,8(sp)
    800007c6:	0800                	addi	s0,sp,16
	ctx->datalen = 0;
    800007c8:	04052023          	sw	zero,64(a0)
	ctx->bitlen = 0;
    800007cc:	04053423          	sd	zero,72(a0)
	ctx->state[0] = 0x6a09e667;
    800007d0:	6a09e7b7          	lui	a5,0x6a09e
    800007d4:	66778793          	addi	a5,a5,1639 # 6a09e667 <_entry-0x15f61999>
    800007d8:	c93c                	sw	a5,80(a0)
	ctx->state[1] = 0xbb67ae85;
    800007da:	bb67b7b7          	lui	a5,0xbb67b
    800007de:	e8578793          	addi	a5,a5,-379 # ffffffffbb67ae85 <kernel_elfhdr+0xffffffff3b672285>
    800007e2:	c97c                	sw	a5,84(a0)
	ctx->state[2] = 0x3c6ef372;
    800007e4:	3c6ef7b7          	lui	a5,0x3c6ef
    800007e8:	37278793          	addi	a5,a5,882 # 3c6ef372 <_entry-0x43910c8e>
    800007ec:	cd3c                	sw	a5,88(a0)
	ctx->state[3] = 0xa54ff53a;
    800007ee:	a54ff7b7          	lui	a5,0xa54ff
    800007f2:	53a78793          	addi	a5,a5,1338 # ffffffffa54ff53a <kernel_elfhdr+0xffffffff254f693a>
    800007f6:	cd7c                	sw	a5,92(a0)
	ctx->state[4] = 0x510e527f;
    800007f8:	510e57b7          	lui	a5,0x510e5
    800007fc:	27f78793          	addi	a5,a5,639 # 510e527f <_entry-0x2ef1ad81>
    80000800:	d13c                	sw	a5,96(a0)
	ctx->state[5] = 0x9b05688c;
    80000802:	9b0577b7          	lui	a5,0x9b057
    80000806:	88c78793          	addi	a5,a5,-1908 # ffffffff9b05688c <kernel_elfhdr+0xffffffff1b04dc8c>
    8000080a:	d17c                	sw	a5,100(a0)
	ctx->state[6] = 0x1f83d9ab;
    8000080c:	1f83e7b7          	lui	a5,0x1f83e
    80000810:	9ab78793          	addi	a5,a5,-1621 # 1f83d9ab <_entry-0x607c2655>
    80000814:	d53c                	sw	a5,104(a0)
	ctx->state[7] = 0x5be0cd19;
    80000816:	5be0d7b7          	lui	a5,0x5be0d
    8000081a:	d1978793          	addi	a5,a5,-743 # 5be0cd19 <_entry-0x241f32e7>
    8000081e:	d57c                	sw	a5,108(a0)
}
    80000820:	6422                	ld	s0,8(sp)
    80000822:	0141                	addi	sp,sp,16
    80000824:	8082                	ret

0000000080000826 <sha256_update>:

void sha256_update(SHA256_CTX *ctx, const BYTE data[], size_t len)
{
	WORD i;

	for (i = 0; i < len; ++i) {
    80000826:	c249                	beqz	a2,800008a8 <sha256_update+0x82>
{
    80000828:	7139                	addi	sp,sp,-64
    8000082a:	fc06                	sd	ra,56(sp)
    8000082c:	f822                	sd	s0,48(sp)
    8000082e:	f426                	sd	s1,40(sp)
    80000830:	f04a                	sd	s2,32(sp)
    80000832:	ec4e                	sd	s3,24(sp)
    80000834:	e852                	sd	s4,16(sp)
    80000836:	e456                	sd	s5,8(sp)
    80000838:	0080                	addi	s0,sp,64
    8000083a:	84aa                	mv	s1,a0
    8000083c:	8a2e                	mv	s4,a1
    8000083e:	89b2                	mv	s3,a2
	for (i = 0; i < len; ++i) {
    80000840:	4901                	li	s2,0
    80000842:	4781                	li	a5,0
		ctx->data[ctx->datalen] = data[i];
		ctx->datalen++;
		if (ctx->datalen == 64) {
    80000844:	04000a93          	li	s5,64
    80000848:	a809                	j	8000085a <sha256_update+0x34>
	for (i = 0; i < len; ++i) {
    8000084a:	0019079b          	addiw	a5,s2,1
    8000084e:	0007891b          	sext.w	s2,a5
    80000852:	1782                	slli	a5,a5,0x20
    80000854:	9381                	srli	a5,a5,0x20
    80000856:	0537f063          	bgeu	a5,s3,80000896 <sha256_update+0x70>
		ctx->data[ctx->datalen] = data[i];
    8000085a:	40b8                	lw	a4,64(s1)
    8000085c:	97d2                	add	a5,a5,s4
    8000085e:	0007c683          	lbu	a3,0(a5)
    80000862:	02071793          	slli	a5,a4,0x20
    80000866:	9381                	srli	a5,a5,0x20
    80000868:	97a6                	add	a5,a5,s1
    8000086a:	00d78023          	sb	a3,0(a5)
		ctx->datalen++;
    8000086e:	0017079b          	addiw	a5,a4,1
    80000872:	0007871b          	sext.w	a4,a5
    80000876:	c0bc                	sw	a5,64(s1)
		if (ctx->datalen == 64) {
    80000878:	fd5719e3          	bne	a4,s5,8000084a <sha256_update+0x24>
			sha256_transform(ctx, ctx->data);
    8000087c:	85a6                	mv	a1,s1
    8000087e:	8526                	mv	a0,s1
    80000880:	00000097          	auipc	ra,0x0
    80000884:	d3c080e7          	jalr	-708(ra) # 800005bc <sha256_transform>
			ctx->bitlen += 512;
    80000888:	64bc                	ld	a5,72(s1)
    8000088a:	20078793          	addi	a5,a5,512
    8000088e:	e4bc                	sd	a5,72(s1)
			ctx->datalen = 0;
    80000890:	0404a023          	sw	zero,64(s1)
    80000894:	bf5d                	j	8000084a <sha256_update+0x24>
		}
	}
}
    80000896:	70e2                	ld	ra,56(sp)
    80000898:	7442                	ld	s0,48(sp)
    8000089a:	74a2                	ld	s1,40(sp)
    8000089c:	7902                	ld	s2,32(sp)
    8000089e:	69e2                	ld	s3,24(sp)
    800008a0:	6a42                	ld	s4,16(sp)
    800008a2:	6aa2                	ld	s5,8(sp)
    800008a4:	6121                	addi	sp,sp,64
    800008a6:	8082                	ret
    800008a8:	8082                	ret

00000000800008aa <sha256_final>:

void sha256_final(SHA256_CTX *ctx, BYTE hash[])
{
    800008aa:	1101                	addi	sp,sp,-32
    800008ac:	ec06                	sd	ra,24(sp)
    800008ae:	e822                	sd	s0,16(sp)
    800008b0:	e426                	sd	s1,8(sp)
    800008b2:	e04a                	sd	s2,0(sp)
    800008b4:	1000                	addi	s0,sp,32
    800008b6:	84aa                	mv	s1,a0
    800008b8:	892e                	mv	s2,a1
	WORD i;

	i = ctx->datalen;
    800008ba:	4134                	lw	a3,64(a0)

	// Pad whatever data is left in the buffer.
	if (ctx->datalen < 56) {
    800008bc:	03700793          	li	a5,55
    800008c0:	04d7e763          	bltu	a5,a3,8000090e <sha256_final+0x64>
		ctx->data[i++] = 0x80;
    800008c4:	0016879b          	addiw	a5,a3,1
    800008c8:	0007861b          	sext.w	a2,a5
    800008cc:	02069713          	slli	a4,a3,0x20
    800008d0:	9301                	srli	a4,a4,0x20
    800008d2:	972a                	add	a4,a4,a0
    800008d4:	f8000593          	li	a1,-128
    800008d8:	00b70023          	sb	a1,0(a4)
		while (i < 56)
    800008dc:	03700713          	li	a4,55
    800008e0:	08c76963          	bltu	a4,a2,80000972 <sha256_final+0xc8>
    800008e4:	02079613          	slli	a2,a5,0x20
    800008e8:	9201                	srli	a2,a2,0x20
    800008ea:	00c507b3          	add	a5,a0,a2
    800008ee:	00150713          	addi	a4,a0,1
    800008f2:	9732                	add	a4,a4,a2
    800008f4:	03600613          	li	a2,54
    800008f8:	40d606bb          	subw	a3,a2,a3
    800008fc:	1682                	slli	a3,a3,0x20
    800008fe:	9281                	srli	a3,a3,0x20
    80000900:	9736                	add	a4,a4,a3
			ctx->data[i++] = 0x00;
    80000902:	00078023          	sb	zero,0(a5)
		while (i < 56)
    80000906:	0785                	addi	a5,a5,1
    80000908:	fee79de3          	bne	a5,a4,80000902 <sha256_final+0x58>
    8000090c:	a09d                	j	80000972 <sha256_final+0xc8>
	}
	else {
		ctx->data[i++] = 0x80;
    8000090e:	0016879b          	addiw	a5,a3,1
    80000912:	0007861b          	sext.w	a2,a5
    80000916:	02069713          	slli	a4,a3,0x20
    8000091a:	9301                	srli	a4,a4,0x20
    8000091c:	972a                	add	a4,a4,a0
    8000091e:	f8000593          	li	a1,-128
    80000922:	00b70023          	sb	a1,0(a4)
		while (i < 64)
    80000926:	03f00713          	li	a4,63
    8000092a:	02c76663          	bltu	a4,a2,80000956 <sha256_final+0xac>
    8000092e:	02079613          	slli	a2,a5,0x20
    80000932:	9201                	srli	a2,a2,0x20
    80000934:	00c507b3          	add	a5,a0,a2
    80000938:	00150713          	addi	a4,a0,1
    8000093c:	9732                	add	a4,a4,a2
    8000093e:	03e00613          	li	a2,62
    80000942:	40d606bb          	subw	a3,a2,a3
    80000946:	1682                	slli	a3,a3,0x20
    80000948:	9281                	srli	a3,a3,0x20
    8000094a:	9736                	add	a4,a4,a3
			ctx->data[i++] = 0x00;
    8000094c:	00078023          	sb	zero,0(a5)
		while (i < 64)
    80000950:	0785                	addi	a5,a5,1
    80000952:	fee79de3          	bne	a5,a4,8000094c <sha256_final+0xa2>
		sha256_transform(ctx, ctx->data);
    80000956:	85a6                	mv	a1,s1
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	c62080e7          	jalr	-926(ra) # 800005bc <sha256_transform>
		memset(ctx->data, 0, 56);
    80000962:	03800613          	li	a2,56
    80000966:	4581                	li	a1,0
    80000968:	8526                	mv	a0,s1
    8000096a:	00000097          	auipc	ra,0x0
    8000096e:	a1c080e7          	jalr	-1508(ra) # 80000386 <memset>
	}

	// Append to the padding the total message's length in bits and transform.
	ctx->bitlen += ctx->datalen * 8;
    80000972:	40bc                	lw	a5,64(s1)
    80000974:	0037979b          	slliw	a5,a5,0x3
    80000978:	1782                	slli	a5,a5,0x20
    8000097a:	9381                	srli	a5,a5,0x20
    8000097c:	64b8                	ld	a4,72(s1)
    8000097e:	97ba                	add	a5,a5,a4
    80000980:	e4bc                	sd	a5,72(s1)
	ctx->data[63] = ctx->bitlen;
    80000982:	02f48fa3          	sb	a5,63(s1)
	ctx->data[62] = ctx->bitlen >> 8;
    80000986:	0087d713          	srli	a4,a5,0x8
    8000098a:	02e48f23          	sb	a4,62(s1)
	ctx->data[61] = ctx->bitlen >> 16;
    8000098e:	0107d713          	srli	a4,a5,0x10
    80000992:	02e48ea3          	sb	a4,61(s1)
	ctx->data[60] = ctx->bitlen >> 24;
    80000996:	0187d713          	srli	a4,a5,0x18
    8000099a:	02e48e23          	sb	a4,60(s1)
	ctx->data[59] = ctx->bitlen >> 32;
    8000099e:	0207d713          	srli	a4,a5,0x20
    800009a2:	02e48da3          	sb	a4,59(s1)
	ctx->data[58] = ctx->bitlen >> 40;
    800009a6:	0287d713          	srli	a4,a5,0x28
    800009aa:	02e48d23          	sb	a4,58(s1)
	ctx->data[57] = ctx->bitlen >> 48;
    800009ae:	0307d713          	srli	a4,a5,0x30
    800009b2:	02e48ca3          	sb	a4,57(s1)
	ctx->data[56] = ctx->bitlen >> 56;
    800009b6:	93e1                	srli	a5,a5,0x38
    800009b8:	02f48c23          	sb	a5,56(s1)
	sha256_transform(ctx, ctx->data);
    800009bc:	85a6                	mv	a1,s1
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	bfc080e7          	jalr	-1028(ra) # 800005bc <sha256_transform>

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash.
	for (i = 0; i < 4; ++i) {
    800009c8:	85ca                	mv	a1,s2
	sha256_transform(ctx, ctx->data);
    800009ca:	47e1                	li	a5,24
	for (i = 0; i < 4; ++i) {
    800009cc:	56e1                	li	a3,-8
		hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
    800009ce:	48b8                	lw	a4,80(s1)
    800009d0:	00f7573b          	srlw	a4,a4,a5
    800009d4:	00e58023          	sb	a4,0(a1)
		hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
    800009d8:	48f8                	lw	a4,84(s1)
    800009da:	00f7573b          	srlw	a4,a4,a5
    800009de:	00e58223          	sb	a4,4(a1)
		hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
    800009e2:	4cb8                	lw	a4,88(s1)
    800009e4:	00f7573b          	srlw	a4,a4,a5
    800009e8:	00e58423          	sb	a4,8(a1)
		hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
    800009ec:	4cf8                	lw	a4,92(s1)
    800009ee:	00f7573b          	srlw	a4,a4,a5
    800009f2:	00e58623          	sb	a4,12(a1)
		hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
    800009f6:	50b8                	lw	a4,96(s1)
    800009f8:	00f7573b          	srlw	a4,a4,a5
    800009fc:	00e58823          	sb	a4,16(a1)
		hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
    80000a00:	50f8                	lw	a4,100(s1)
    80000a02:	00f7573b          	srlw	a4,a4,a5
    80000a06:	00e58a23          	sb	a4,20(a1)
		hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
    80000a0a:	54b8                	lw	a4,104(s1)
    80000a0c:	00f7573b          	srlw	a4,a4,a5
    80000a10:	00e58c23          	sb	a4,24(a1)
		hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
    80000a14:	54f8                	lw	a4,108(s1)
    80000a16:	00f7573b          	srlw	a4,a4,a5
    80000a1a:	00e58e23          	sb	a4,28(a1)
	for (i = 0; i < 4; ++i) {
    80000a1e:	37e1                	addiw	a5,a5,-8
    80000a20:	0585                	addi	a1,a1,1
    80000a22:	fad796e3          	bne	a5,a3,800009ce <sha256_final+0x124>
	}
    80000a26:	60e2                	ld	ra,24(sp)
    80000a28:	6442                	ld	s0,16(sp)
    80000a2a:	64a2                	ld	s1,8(sp)
    80000a2c:	6902                	ld	s2,0(sp)
    80000a2e:	6105                	addi	sp,sp,32
    80000a30:	8082                	ret
