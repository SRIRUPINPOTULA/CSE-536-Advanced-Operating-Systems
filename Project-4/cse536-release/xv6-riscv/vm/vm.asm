
vm/vm:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <_entry>:
   0:	00001117          	auipc	sp,0x1
   4:	01010113          	addi	sp,sp,16 # 1010 <stack0>
   8:	6505                	lui	a0,0x1
   a:	f14025f3          	csrr	a1,mhartid
   e:	0585                	addi	a1,a1,1
  10:	02b50533          	mul	a0,a0,a1
  14:	912a                	add	sp,sp,a0
  16:	006000ef          	jal	ra,1c <start>

000000000000001a <spin>:
  1a:	a001                	j	1a <spin>

000000000000001c <start>:
extern void _entry(void);

// entry.S jumps here in machine mode on stack0.
void
start()
{
  1c:	1141                	addi	sp,sp,-16
  1e:	e406                	sd	ra,8(sp)
  20:	e022                	sd	s0,0(sp)
  22:	0800                	addi	s0,sp,16
  assert_linker_symbols();
  24:	00000097          	auipc	ra,0x0
  28:	274080e7          	jalr	628(ra) # 298 <assert_linker_symbols>
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
  2c:	f14027f3          	csrr	a5,mhartid

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);
  30:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
  32:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
  34:	300027f3          	csrr	a5,mstatus

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  38:	7779                	lui	a4,0xffffe
  3a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <ustack+0xfffffffffffed71f>
  3e:	8ff9                	and	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
  40:	30079073          	csrw	mstatus,a5
  asm volatile("csrw satp, %0" : : "r" (x));
  44:	4781                	li	a5,0
  46:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
  4a:	200007b7          	lui	a5,0x20000
  4e:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpaddr1, %0" : : "r" (x));
  52:	200407b7          	lui	a5,0x20040
  56:	3b179073          	csrw	pmpaddr1,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
  5a:	6785                	lui	a5,0x1
  5c:	80078793          	addi	a5,a5,-2048 # 800 <process_entry+0x3d2>
  60:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
  64:	00000797          	auipc	a5,0x0
  68:	3b878793          	addi	a5,a5,952 # 41c <kernel_entry>
  6c:	34179073          	csrw	mepc,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
  70:	67c1                	lui	a5,0x10
  72:	17fd                	addi	a5,a5,-1 # ffff <kstack+0x6f1f>
  74:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
  78:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
  7c:	104027f3          	csrr	a5,sie
  w_mepc((uint64)kernel_entry);

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
  80:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
  84:	10479073          	csrw	sie,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
  88:	30200073          	mret
  8c:	60a2                	ld	ra,8(sp)
  8e:	6402                	ld	s0,0(sp)
  90:	0141                	addi	sp,sp,16
  92:	8082                	ret

0000000000000094 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
  94:	1101                	addi	sp,sp,-32
  96:	ec06                	sd	ra,24(sp)
  98:	e822                	sd	s0,16(sp)
  9a:	e426                	sd	s1,8(sp)
  9c:	1000                	addi	s0,sp,32
  9e:	84aa                	mv	s1,a0
  /* Ramdisk is not even reading from the damn file.. */
  if(b->blockno >= FSSIZE)
  a0:	4558                	lw	a4,12(a0)
  a2:	7cf00793          	li	a5,1999
  a6:	02e7ea63          	bltu	a5,a4,da <userret+0x3e>
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
  aa:	44dc                	lw	a5,12(s1)
  ac:	00a7979b          	slliw	a5,a5,0xa
  b0:	1782                	slli	a5,a5,0x20
  b2:	9381                	srli	a5,a5,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
  b4:	40000613          	li	a2,1024
  b8:	02100593          	li	a1,33
  bc:	05ea                	slli	a1,a1,0x1a
  be:	95be                	add	a1,a1,a5
  c0:	02848513          	addi	a0,s1,40
  c4:	00000097          	auipc	ra,0x0
  c8:	084080e7          	jalr	132(ra) # 148 <memmove>
  b->valid = 1;
  cc:	4785                	li	a5,1
  ce:	c09c                	sw	a5,0(s1)
}
  d0:	60e2                	ld	ra,24(sp)
  d2:	6442                	ld	s0,16(sp)
  d4:	64a2                	ld	s1,8(sp)
  d6:	6105                	addi	sp,sp,32
  d8:	8082                	ret
    panic("ramdiskrw: blockno too big");
  da:	00000517          	auipc	a0,0x0
  de:	37650513          	addi	a0,a0,886 # 450 <process_entry+0x22>
  e2:	00000097          	auipc	ra,0x0
  e6:	1ae080e7          	jalr	430(ra) # 290 <panic>
  ea:	b7c1                	j	aa <userret+0xe>

00000000000000ec <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
  ec:	1141                	addi	sp,sp,-16
  ee:	e422                	sd	s0,8(sp)
  f0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f2:	ca19                	beqz	a2,108 <memset+0x1c>
  f4:	87aa                	mv	a5,a0
  f6:	1602                	slli	a2,a2,0x20
  f8:	9201                	srli	a2,a2,0x20
  fa:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  fe:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 102:	0785                	addi	a5,a5,1
 104:	fee79de3          	bne	a5,a4,fe <memset+0x12>
  }
  return dst;
}
 108:	6422                	ld	s0,8(sp)
 10a:	0141                	addi	sp,sp,16
 10c:	8082                	ret

000000000000010e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
 10e:	1141                	addi	sp,sp,-16
 110:	e422                	sd	s0,8(sp)
 112:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
 114:	ca05                	beqz	a2,144 <memcmp+0x36>
 116:	fff6069b          	addiw	a3,a2,-1
 11a:	1682                	slli	a3,a3,0x20
 11c:	9281                	srli	a3,a3,0x20
 11e:	0685                	addi	a3,a3,1
 120:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
 122:	00054783          	lbu	a5,0(a0)
 126:	0005c703          	lbu	a4,0(a1)
 12a:	00e79863          	bne	a5,a4,13a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
 12e:	0505                	addi	a0,a0,1
 130:	0585                	addi	a1,a1,1
  while(n-- > 0){
 132:	fed518e3          	bne	a0,a3,122 <memcmp+0x14>
  }

  return 0;
 136:	4501                	li	a0,0
 138:	a019                	j	13e <memcmp+0x30>
      return *s1 - *s2;
 13a:	40e7853b          	subw	a0,a5,a4
}
 13e:	6422                	ld	s0,8(sp)
 140:	0141                	addi	sp,sp,16
 142:	8082                	ret
  return 0;
 144:	4501                	li	a0,0
 146:	bfe5                	j	13e <memcmp+0x30>

0000000000000148 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
 148:	1141                	addi	sp,sp,-16
 14a:	e422                	sd	s0,8(sp)
 14c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
 14e:	c205                	beqz	a2,16e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
 150:	02a5e263          	bltu	a1,a0,174 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
 154:	1602                	slli	a2,a2,0x20
 156:	9201                	srli	a2,a2,0x20
 158:	00c587b3          	add	a5,a1,a2
{
 15c:	872a                	mv	a4,a0
      *d++ = *s++;
 15e:	0585                	addi	a1,a1,1
 160:	0705                	addi	a4,a4,1
 162:	fff5c683          	lbu	a3,-1(a1)
 166:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 16a:	fef59ae3          	bne	a1,a5,15e <memmove+0x16>

  return dst;
}
 16e:	6422                	ld	s0,8(sp)
 170:	0141                	addi	sp,sp,16
 172:	8082                	ret
  if(s < d && s + n > d){
 174:	02061693          	slli	a3,a2,0x20
 178:	9281                	srli	a3,a3,0x20
 17a:	00d58733          	add	a4,a1,a3
 17e:	fce57be3          	bgeu	a0,a4,154 <memmove+0xc>
    d += n;
 182:	96aa                	add	a3,a3,a0
    while(n-- > 0)
 184:	fff6079b          	addiw	a5,a2,-1
 188:	1782                	slli	a5,a5,0x20
 18a:	9381                	srli	a5,a5,0x20
 18c:	fff7c793          	not	a5,a5
 190:	97ba                	add	a5,a5,a4
      *--d = *--s;
 192:	177d                	addi	a4,a4,-1
 194:	16fd                	addi	a3,a3,-1
 196:	00074603          	lbu	a2,0(a4)
 19a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
 19e:	fee79ae3          	bne	a5,a4,192 <memmove+0x4a>
 1a2:	b7f1                	j	16e <memmove+0x26>

00000000000001a4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
 1a4:	1141                	addi	sp,sp,-16
 1a6:	e406                	sd	ra,8(sp)
 1a8:	e022                	sd	s0,0(sp)
 1aa:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 1ac:	00000097          	auipc	ra,0x0
 1b0:	f9c080e7          	jalr	-100(ra) # 148 <memmove>
}
 1b4:	60a2                	ld	ra,8(sp)
 1b6:	6402                	ld	s0,0(sp)
 1b8:	0141                	addi	sp,sp,16
 1ba:	8082                	ret

00000000000001bc <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
 1bc:	1141                	addi	sp,sp,-16
 1be:	e422                	sd	s0,8(sp)
 1c0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
 1c2:	ce11                	beqz	a2,1de <strncmp+0x22>
 1c4:	00054783          	lbu	a5,0(a0)
 1c8:	cf89                	beqz	a5,1e2 <strncmp+0x26>
 1ca:	0005c703          	lbu	a4,0(a1)
 1ce:	00f71a63          	bne	a4,a5,1e2 <strncmp+0x26>
    n--, p++, q++;
 1d2:	367d                	addiw	a2,a2,-1
 1d4:	0505                	addi	a0,a0,1
 1d6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
 1d8:	f675                	bnez	a2,1c4 <strncmp+0x8>
  if(n == 0)
    return 0;
 1da:	4501                	li	a0,0
 1dc:	a809                	j	1ee <strncmp+0x32>
 1de:	4501                	li	a0,0
 1e0:	a039                	j	1ee <strncmp+0x32>
  if(n == 0)
 1e2:	ca09                	beqz	a2,1f4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
 1e4:	00054503          	lbu	a0,0(a0)
 1e8:	0005c783          	lbu	a5,0(a1)
 1ec:	9d1d                	subw	a0,a0,a5
}
 1ee:	6422                	ld	s0,8(sp)
 1f0:	0141                	addi	sp,sp,16
 1f2:	8082                	ret
    return 0;
 1f4:	4501                	li	a0,0
 1f6:	bfe5                	j	1ee <strncmp+0x32>

00000000000001f8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
 1f8:	1141                	addi	sp,sp,-16
 1fa:	e422                	sd	s0,8(sp)
 1fc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
 1fe:	87aa                	mv	a5,a0
 200:	86b2                	mv	a3,a2
 202:	367d                	addiw	a2,a2,-1
 204:	00d05963          	blez	a3,216 <strncpy+0x1e>
 208:	0785                	addi	a5,a5,1
 20a:	0005c703          	lbu	a4,0(a1)
 20e:	fee78fa3          	sb	a4,-1(a5)
 212:	0585                	addi	a1,a1,1
 214:	f775                	bnez	a4,200 <strncpy+0x8>
    ;
  while(n-- > 0)
 216:	873e                	mv	a4,a5
 218:	9fb5                	addw	a5,a5,a3
 21a:	37fd                	addiw	a5,a5,-1
 21c:	00c05963          	blez	a2,22e <strncpy+0x36>
    *s++ = 0;
 220:	0705                	addi	a4,a4,1
 222:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
 226:	40e786bb          	subw	a3,a5,a4
 22a:	fed04be3          	bgtz	a3,220 <strncpy+0x28>
  return os;
}
 22e:	6422                	ld	s0,8(sp)
 230:	0141                	addi	sp,sp,16
 232:	8082                	ret

0000000000000234 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
 234:	1141                	addi	sp,sp,-16
 236:	e422                	sd	s0,8(sp)
 238:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
 23a:	02c05363          	blez	a2,260 <safestrcpy+0x2c>
 23e:	fff6069b          	addiw	a3,a2,-1
 242:	1682                	slli	a3,a3,0x20
 244:	9281                	srli	a3,a3,0x20
 246:	96ae                	add	a3,a3,a1
 248:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
 24a:	00d58963          	beq	a1,a3,25c <safestrcpy+0x28>
 24e:	0585                	addi	a1,a1,1
 250:	0785                	addi	a5,a5,1
 252:	fff5c703          	lbu	a4,-1(a1)
 256:	fee78fa3          	sb	a4,-1(a5)
 25a:	fb65                	bnez	a4,24a <safestrcpy+0x16>
    ;
  *s = 0;
 25c:	00078023          	sb	zero,0(a5)
  return os;
}
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret

0000000000000266 <strlen>:

int
strlen(const char *s)
{
 266:	1141                	addi	sp,sp,-16
 268:	e422                	sd	s0,8(sp)
 26a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 26c:	00054783          	lbu	a5,0(a0)
 270:	cf91                	beqz	a5,28c <strlen+0x26>
 272:	0505                	addi	a0,a0,1
 274:	87aa                	mv	a5,a0
 276:	86be                	mv	a3,a5
 278:	0785                	addi	a5,a5,1
 27a:	fff7c703          	lbu	a4,-1(a5)
 27e:	ff65                	bnez	a4,276 <strlen+0x10>
 280:	40a6853b          	subw	a0,a3,a0
 284:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 286:	6422                	ld	s0,8(sp)
 288:	0141                	addi	sp,sp,16
 28a:	8082                	ret
  for(n = 0; s[n]; n++)
 28c:	4501                	li	a0,0
 28e:	bfe5                	j	286 <strlen+0x20>

0000000000000290 <panic>:
#include "buf.h"

#include <stdbool.h>

void panic(char *s)
{
 290:	1141                	addi	sp,sp,-16
 292:	e422                	sd	s0,8(sp)
 294:	0800                	addi	s0,sp,16
  for(;;)
 296:	a001                	j	296 <panic+0x6>

0000000000000298 <assert_linker_symbols>:
    ;
}

int assert_linker_symbols(void) {
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
    return 0;
}
 29e:	4501                	li	a0,0
 2a0:	6422                	ld	s0,8(sp)
 2a2:	0141                	addi	sp,sp,16
 2a4:	8082                	ret

00000000000002a6 <assert_stack_address>:

int assert_stack_address(void) {
 2a6:	1141                	addi	sp,sp,-16
 2a8:	e422                	sd	s0,8(sp)
 2aa:	0800                	addi	s0,sp,16
    return 1;
 2ac:	4505                	li	a0,1
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret

00000000000002b4 <read_kernel_elf>:
#include "elf.h"

#include <stdbool.h>

// Task: Read the ELF header, perform a sanity check, and return binary entry point
uint64 read_kernel_elf(void) {
 2b4:	715d                	addi	sp,sp,-80
 2b6:	e486                	sd	ra,72(sp)
 2b8:	e0a2                	sd	s0,64(sp)
 2ba:	0880                	addi	s0,sp,80
    struct elfhdr elf;
    memmove((void*) &elf, (void*) RAMDISK, sizeof(elf));
 2bc:	04000613          	li	a2,64
 2c0:	02100593          	li	a1,33
 2c4:	05ea                	slli	a1,a1,0x1a
 2c6:	fb040513          	addi	a0,s0,-80
 2ca:	00000097          	auipc	ra,0x0
 2ce:	e7e080e7          	jalr	-386(ra) # 148 <memmove>
    if(elf.magic != ELF_MAGIC)
 2d2:	fb042703          	lw	a4,-80(s0)
 2d6:	464c47b7          	lui	a5,0x464c4
 2da:	57f78793          	addi	a5,a5,1407 # 464c457f <ustack+0x464b349f>
 2de:	00f71863          	bne	a4,a5,2ee <read_kernel_elf+0x3a>
        panic (NULL);
    return elf.entry;
 2e2:	fc843503          	ld	a0,-56(s0)
 2e6:	60a6                	ld	ra,72(sp)
 2e8:	6406                	ld	s0,64(sp)
 2ea:	6161                	addi	sp,sp,80
 2ec:	8082                	ret
        panic (NULL);
 2ee:	4501                	li	a0,0
 2f0:	00000097          	auipc	ra,0x0
 2f4:	fa0080e7          	jalr	-96(ra) # 290 <panic>
 2f8:	b7ed                	j	2e2 <read_kernel_elf+0x2e>

00000000000002fa <kalloc>:

void usertrapret(void);

// simple page-by-page memory allocator
void* kalloc(void) {
    if (alloc_pages == KMEMSIZE) {
 2fa:	00001717          	auipc	a4,0x1
 2fe:	d0672703          	lw	a4,-762(a4) # 1000 <alloc_pages>
 302:	40000793          	li	a5,1024
 306:	02f70063          	beq	a4,a5,326 <kalloc+0x2c>
        panic("panic!");
    }
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 30a:	00001797          	auipc	a5,0x1
 30e:	cf678793          	addi	a5,a5,-778 # 1000 <alloc_pages>
 312:	4388                	lw	a0,0(a5)
    alloc_pages++;
 314:	0015071b          	addiw	a4,a0,1
 318:	c398                	sw	a4,0(a5)
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 31a:	00c5151b          	slliw	a0,a0,0xc
    return (void*) addr;
}
 31e:	4785                	li	a5,1
 320:	07fe                	slli	a5,a5,0x1f
 322:	953e                	add	a0,a0,a5
 324:	8082                	ret
void* kalloc(void) {
 326:	1141                	addi	sp,sp,-16
 328:	e406                	sd	ra,8(sp)
 32a:	e022                	sd	s0,0(sp)
 32c:	0800                	addi	s0,sp,16
        panic("panic!");
 32e:	00000517          	auipc	a0,0x0
 332:	14250513          	addi	a0,a0,322 # 470 <process_entry+0x42>
 336:	00000097          	auipc	ra,0x0
 33a:	f5a080e7          	jalr	-166(ra) # 290 <panic>
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 33e:	00001797          	auipc	a5,0x1
 342:	cc278793          	addi	a5,a5,-830 # 1000 <alloc_pages>
 346:	4388                	lw	a0,0(a5)
    alloc_pages++;
 348:	0015071b          	addiw	a4,a0,1
 34c:	c398                	sw	a4,0(a5)
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 34e:	00c5151b          	slliw	a0,a0,0xc
}
 352:	4785                	li	a5,1
 354:	07fe                	slli	a5,a5,0x1f
 356:	953e                	add	a0,a0,a5
 358:	60a2                	ld	ra,8(sp)
 35a:	6402                	ld	s0,0(sp)
 35c:	0141                	addi	sp,sp,16
 35e:	8082                	ret

0000000000000360 <usertrapret>:
  /* traps here when back from the userspace code. */
  p.trapframe->epc = r_sepc() + 4;
  usertrapret();
}

void usertrapret(void) {
 360:	1141                	addi	sp,sp,-16
 362:	e422                	sd	s0,8(sp)
 364:	0800                	addi	s0,sp,16
    // Set-up for process entry and exit
    p.trapframe->kernel_sp = (uint64) kstack+PGSIZE;
 366:	00009717          	auipc	a4,0x9
 36a:	caa70713          	addi	a4,a4,-854 # 9010 <p>
 36e:	633c                	ld	a5,64(a4)
 370:	0000a697          	auipc	a3,0xa
 374:	d7068693          	addi	a3,a3,-656 # a0e0 <kstack+0x1000>
 378:	e794                	sd	a3,8(a5)

    // Set return trap location
    p.trapframe->kernel_trap = (uint64) usertrap;
 37a:	633c                	ld	a5,64(a4)
 37c:	00000697          	auipc	a3,0x0
 380:	03868693          	addi	a3,a3,56 # 3b4 <usertrap>
 384:	eb94                	sd	a3,16(a5)
    w_stvec((uint64) p.trapframe->kernel_trap);
 386:	633c                	ld	a5,64(a4)
  asm volatile("csrw stvec, %0" : : "r" (x));
 388:	6b94                	ld	a3,16(a5)
 38a:	10569073          	csrw	stvec,a3
// read and write tp, the thread pointer, which xv6 uses to hold
 38e:	8692                	mv	a3,tp

    // Save hart id
    p.trapframe->kernel_hartid = r_tp();
 390:	f394                	sd	a3,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
 392:	100027f3          	csrr	a5,sstatus

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
 396:	eff7f793          	andi	a5,a5,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
 39a:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
 39e:	10079073          	csrw	sstatus,a5
    w_sstatus(x);

    // Set entry location
    w_sepc((uint64) p.trapframe->epc);
 3a2:	633c                	ld	a5,64(a4)
  asm volatile("csrw sepc, %0" : : "r" (x));
 3a4:	6f9c                	ld	a5,24(a5)
 3a6:	14179073          	csrw	sepc,a5

    asm("sret");
 3aa:	10200073          	sret
}
 3ae:	6422                	ld	s0,8(sp)
 3b0:	0141                	addi	sp,sp,16
 3b2:	8082                	ret

00000000000003b4 <usertrap>:
void usertrap(void) {
 3b4:	1141                	addi	sp,sp,-16
 3b6:	e406                	sd	ra,8(sp)
 3b8:	e022                	sd	s0,0(sp)
 3ba:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sepc" : "=r" (x) );
 3bc:	141027f3          	csrr	a5,sepc
  p.trapframe->epc = r_sepc() + 4;
 3c0:	0791                	addi	a5,a5,4
 3c2:	00009717          	auipc	a4,0x9
 3c6:	c8e73703          	ld	a4,-882(a4) # 9050 <p+0x40>
 3ca:	ef1c                	sd	a5,24(a4)
  usertrapret();
 3cc:	00000097          	auipc	ra,0x0
 3d0:	f94080e7          	jalr	-108(ra) # 360 <usertrapret>
}
 3d4:	60a2                	ld	ra,8(sp)
 3d6:	6402                	ld	s0,0(sp)
 3d8:	0141                	addi	sp,sp,16
 3da:	8082                	ret

00000000000003dc <create_process>:

// Creates the user-level process and sets-up initial
void create_process(void) {
 3dc:	1141                	addi	sp,sp,-16
 3de:	e406                	sd	ra,8(sp)
 3e0:	e022                	sd	s0,0(sp)
 3e2:	0800                	addi	s0,sp,16
    // allocate trapframe memory
    p.trapframe = (struct trapframe*) kalloc();
 3e4:	00000097          	auipc	ra,0x0
 3e8:	f16080e7          	jalr	-234(ra) # 2fa <kalloc>
 3ec:	00009797          	auipc	a5,0x9
 3f0:	c2478793          	addi	a5,a5,-988 # 9010 <p>
 3f4:	e3a8                	sd	a0,64(a5)

    // entry point
    p.trapframe->epc = (uint64) process_entry;
 3f6:	00000717          	auipc	a4,0x0
 3fa:	03870713          	addi	a4,a4,56 # 42e <process_entry>
 3fe:	ed18                	sd	a4,24(a0)

    // initial stack values
    p.trapframe->a1 = (uint64) ustack+PGSIZE;
 400:	63bc                	ld	a5,64(a5)
 402:	00012717          	auipc	a4,0x12
 406:	cde70713          	addi	a4,a4,-802 # 120e0 <ustack+0x1000>
 40a:	ffb8                	sd	a4,120(a5)

    // usertrapret
    usertrapret();
 40c:	00000097          	auipc	ra,0x0
 410:	f54080e7          	jalr	-172(ra) # 360 <usertrapret>
}
 414:	60a2                	ld	ra,8(sp)
 416:	6402                	ld	s0,0(sp)
 418:	0141                	addi	sp,sp,16
 41a:	8082                	ret

000000000000041c <kernel_entry>:

void kernel_entry(void) {
 41c:	1141                	addi	sp,sp,-16
 41e:	e406                	sd	ra,8(sp)
 420:	e022                	sd	s0,0(sp)
 422:	0800                	addi	s0,sp,16
  create_process();
 424:	00000097          	auipc	ra,0x0
 428:	fb8080e7          	jalr	-72(ra) # 3dc <create_process>

  /* Nothing to go back to */
  while (true);
 42c:	a001                	j	42c <kernel_entry+0x10>

000000000000042e <process_entry>:
void process_entry(void) {
 42e:	1141                	addi	sp,sp,-16
 430:	e422                	sd	s0,8(sp)
 432:	0800                	addi	s0,sp,16
  asm("ecall");
 434:	00000073          	ecall
  asm("sret");
 438:	10200073          	sret
 43c:	6422                	ld	s0,8(sp)
 43e:	0141                	addi	sp,sp,16
 440:	8082                	ret
