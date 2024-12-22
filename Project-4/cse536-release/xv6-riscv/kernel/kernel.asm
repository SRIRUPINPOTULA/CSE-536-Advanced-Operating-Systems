
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	dc010113          	addi	sp,sp,-576 # 80009dc0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	ra,80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	ra,80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	addi	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	slliw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	slli	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	slli	a3,a3,0x3
    80000054:	0000a717          	auipc	a4,0xa
    80000058:	c2c70713          	addi	a4,a4,-980 # 80009c80 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c5a78793          	addi	a5,a5,-934 # 80005cc0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	addi	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	addi	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb0df>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	addi	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srli	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	addi	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	addi	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	42a080e7          	jalr	1066(ra) # 80002558 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	addi	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	addi	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	addi	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00012517          	auipc	a0,0x12
    8000018c:	c3850513          	addi	a0,a0,-968 # 80011dc0 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	c2848493          	addi	s1,s1,-984 # 80011dc0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	cb890913          	addi	s2,s2,-840 # 80011e58 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1e2080e7          	jalr	482(ra) # 800023a2 <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f2c080e7          	jalr	-212(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00012717          	auipc	a4,0x12
    800001e6:	bde70713          	addi	a4,a4,-1058 # 80011dc0 <cons>
    800001ea:	0017869b          	addiw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	andi	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	addi	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2ee080e7          	jalr	750(ra) # 80002502 <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00012517          	auipc	a0,0x12
    80000230:	b9450513          	addi	a0,a0,-1132 # 80011dc0 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00012517          	auipc	a0,0x12
    80000246:	b7e50513          	addi	a0,a0,-1154 # 80011dc0 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	addi	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00012717          	auipc	a4,0x12
    80000276:	bef72323          	sw	a5,-1050(a4) # 80011e58 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00012517          	auipc	a0,0x12
    800002d0:	af450513          	addi	a0,a0,-1292 # 80011dc0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00012517          	auipc	a0,0x12
    800002fe:	ac650513          	addi	a0,a0,-1338 # 80011dc0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00012717          	auipc	a4,0x12
    80000322:	aa270713          	addi	a4,a4,-1374 # 80011dc0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00012797          	auipc	a5,0x12
    8000034c:	a7878793          	addi	a5,a5,-1416 # 80011dc0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00012797          	auipc	a5,0x12
    8000037a:	ae27a783          	lw	a5,-1310(a5) # 80011e58 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00012717          	auipc	a4,0x12
    8000038e:	a3670713          	addi	a4,a4,-1482 # 80011dc0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00012497          	auipc	s1,0x12
    8000039e:	a2648493          	addi	s1,s1,-1498 # 80011dc0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00012717          	auipc	a4,0x12
    800003da:	9ea70713          	addi	a4,a4,-1558 # 80011dc0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00012717          	auipc	a4,0x12
    800003f0:	a6f72a23          	sw	a5,-1420(a4) # 80011e60 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00012797          	auipc	a5,0x12
    80000416:	9ae78793          	addi	a5,a5,-1618 # 80011dc0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00012797          	auipc	a5,0x12
    8000043a:	a2c7a323          	sw	a2,-1498(a5) # 80011e5c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00012517          	auipc	a0,0x12
    80000442:	a1a50513          	addi	a0,a0,-1510 # 80011e58 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d18080e7          	jalr	-744(ra) # 8000215e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00009597          	auipc	a1,0x9
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80009010 <etext+0x10>
    80000460:	00012517          	auipc	a0,0x12
    80000464:	96050513          	addi	a0,a0,-1696 # 80011dc0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	ce078793          	addi	a5,a5,-800 # 80022158 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	addi	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	addi	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00009617          	auipc	a2,0x9
    800004be:	b8660613          	addi	a2,a2,-1146 # 80009040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00012797          	auipc	a5,0x12
    80000550:	9207aa23          	sw	zero,-1740(a5) # 80011e80 <pr+0x18>
  printf("panic: ");
    80000554:	00009517          	auipc	a0,0x9
    80000558:	ac450513          	addi	a0,a0,-1340 # 80009018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00009517          	auipc	a0,0x9
    80000572:	53250513          	addi	a0,a0,1330 # 80009aa0 <syscalls+0x630>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	6af72823          	sw	a5,1712(a4) # 80009c30 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	addi	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00009a97          	auipc	s5,0x9
    800005dc:	a68a8a93          	addi	s5,s5,-1432 # 80009040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00009517          	auipc	a0,0x9
    800005f0:	a3c50513          	addi	a0,a0,-1476 # 80009028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addiw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addiw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	addi	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	addi	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	addi	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addiw	s2,s2,1
    800006b0:	00f7f713          	andi	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srliw	a5,a5,0x4
    800006c6:	0685                	addi	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	addi	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addiw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addiw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addiw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	addi	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	addi	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addiw	s3,s3,-1
    80000724:	197d                	addi	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	addi	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00009917          	auipc	s2,0x9
    800007aa:	87a90913          	addi	s2,s2,-1926 # 80009020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	addi	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00011497          	auipc	s1,0x11
    800007f6:	67648493          	addi	s1,s1,1654 # 80011e68 <pr>
    800007fa:	00009597          	auipc	a1,0x9
    800007fe:	83e58593          	addi	a1,a1,-1986 # 80009038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	addi	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00009597          	auipc	a1,0x9
    8000084e:	80e58593          	addi	a1,a1,-2034 # 80009058 <digits+0x18>
    80000852:	00011517          	auipc	a0,0x11
    80000856:	63650513          	addi	a0,a0,1590 # 80011e88 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	addi	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	addi	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	addi	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	andi	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	addi	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00009797          	auipc	a5,0x9
    800008ae:	38e7b783          	ld	a5,910(a5) # 80009c38 <uart_tx_r>
    800008b2:	00009717          	auipc	a4,0x9
    800008b6:	38e73703          	ld	a4,910(a4) # 80009c40 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	addi	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00011a17          	auipc	s4,0x11
    800008d8:	5b4a0a13          	addi	s4,s4,1460 # 80011e88 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00009497          	auipc	s1,0x9
    800008e0:	35c48493          	addi	s1,s1,860 # 80009c38 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00009997          	auipc	s3,0x9
    800008e8:	35c98993          	addi	s3,s3,860 # 80009c40 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	andi	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	addi	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	858080e7          	jalr	-1960(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00011517          	auipc	a0,0x11
    80000946:	54650513          	addi	a0,a0,1350 # 80011e88 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00009797          	auipc	a5,0x9
    80000956:	2de7a783          	lw	a5,734(a5) # 80009c30 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00009717          	auipc	a4,0x9
    80000960:	2e473703          	ld	a4,740(a4) # 80009c40 <uart_tx_w>
    80000964:	00009797          	auipc	a5,0x9
    80000968:	2d47b783          	ld	a5,724(a5) # 80009c38 <uart_tx_r>
    8000096c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00011997          	auipc	s3,0x11
    80000974:	51898993          	addi	s3,s3,1304 # 80011e88 <uart_tx_lock>
    80000978:	00009497          	auipc	s1,0x9
    8000097c:	2c048493          	addi	s1,s1,704 # 80009c38 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00009917          	auipc	s2,0x9
    80000984:	2c090913          	addi	s2,s2,704 # 80009c40 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	76a080e7          	jalr	1898(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	addi	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00011497          	auipc	s1,0x11
    800009aa:	4e248493          	addi	s1,s1,1250 # 80011e88 <uart_tx_lock>
    800009ae:	01f77793          	andi	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	addi	a4,a4,1
    800009ba:	00009797          	auipc	a5,0x9
    800009be:	28e7b323          	sd	a4,646(a5) # 80009c40 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	addi	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	addi	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	andi	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	addi	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	addi	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00011497          	auipc	s1,0x11
    80000a30:	45c48493          	addi	s1,s1,1116 # 80011e88 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	addi	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	slli	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00023797          	auipc	a5,0x23
    80000a72:	cb278793          	addi	a5,a5,-846 # 80023720 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	slli	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00011917          	auipc	s2,0x11
    80000a92:	43290913          	addi	s2,s2,1074 # 80011ec0 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	addi	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00008517          	auipc	a0,0x8
    80000ac4:	5a050513          	addi	a0,a0,1440 # 80009060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	addi	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	addi	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00008597          	auipc	a1,0x8
    80000b28:	54458593          	addi	a1,a1,1348 # 80009068 <digits+0x28>
    80000b2c:	00011517          	auipc	a0,0x11
    80000b30:	39450513          	addi	a0,a0,916 # 80011ec0 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	slli	a1,a1,0x1b
    80000b40:	00023517          	auipc	a0,0x23
    80000b44:	be050513          	addi	a0,a0,-1056 # 80023720 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	addi	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00011497          	auipc	s1,0x11
    80000b66:	35e48493          	addi	s1,s1,862 # 80011ec0 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00011517          	auipc	a0,0x11
    80000b7e:	34650513          	addi	a0,a0,838 # 80011ec0 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	addi	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00011517          	auipc	a0,0x11
    80000baa:	31a50513          	addi	a0,a0,794 # 80011ec0 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	addi	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srli	s1,s1,0x1
    80000c42:	8885                	andi	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00008517          	auipc	a0,0x8
    80000c90:	3e450513          	addi	a0,a0,996 # 80009070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addiw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00008517          	auipc	a0,0x8
    80000ce0:	39c50513          	addi	a0,a0,924 # 80009078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00008517          	auipc	a0,0x8
    80000cf0:	3a450513          	addi	a0,a0,932 # 80009090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00008517          	auipc	a0,0x8
    80000d38:	36450513          	addi	a0,a0,868 # 80009098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	addi	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	slli	a2,a2,0x20
    80000d50:	9201                	srli	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	addi	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	addi	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	slli	a3,a3,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	0685                	addi	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	slli	a2,a2,0x20
    80000dae:	9201                	srli	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb8e1>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	slli	a3,a2,0x20
    80000dd0:	9281                	srli	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addiw	a5,a2,-1
    80000de0:	1782                	slli	a5,a5,0x20
    80000de2:	9381                	srli	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	addi	a4,a4,-1
    80000dec:	16fd                	addi	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addiw	a2,a2,-1
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	addi	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addiw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addiw	a3,a2,-1
    80000e9a:	1682                	slli	a3,a3,0x20
    80000e9c:	9281                	srli	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	addi	a1,a1,1
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    //printf("After the call ");

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	00009717          	auipc	a4,0x9
    80000efc:	d5070713          	addi	a4,a4,-688 # 80009c48 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00008517          	auipc	a0,0x8
    80000f1a:	1a250513          	addi	a0,a0,418 # 800090b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7c2080e7          	jalr	1986(ra) # 800026f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	dca080e7          	jalr	-566(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	00a080e7          	jalr	10(ra) # 80001f48 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	00009517          	auipc	a0,0x9
    80000f5a:	b4a50513          	addi	a0,a0,-1206 # 80009aa0 <syscalls+0x630>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00008517          	auipc	a0,0x8
    80000f6a:	13a50513          	addi	a0,a0,314 # 800090a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	00009517          	auipc	a0,0x9
    80000f7a:	b2a50513          	addi	a0,a0,-1238 # 80009aa0 <syscalls+0x630>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	722080e7          	jalr	1826(ra) # 800026c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	742080e7          	jalr	1858(ra) # 800026f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d34080e7          	jalr	-716(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d42080e7          	jalr	-702(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	ec0080e7          	jalr	-320(ra) # 80002e86 <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	55e080e7          	jalr	1374(ra) # 8000352c <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	4d4080e7          	jalr	1236(ra) # 800044aa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e2a080e7          	jalr	-470(ra) # 80005e08 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d44080e7          	jalr	-700(ra) # 80001d2a <userinit>
    trap_and_emulate_init();
    80000fee:	00006097          	auipc	ra,0x6
    80000ff2:	216080e7          	jalr	534(ra) # 80007204 <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00009717          	auipc	a4,0x9
    80001000:	c4f72623          	sw	a5,-948(a4) # 80009c48 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	addi	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00009797          	auipc	a5,0x9
    80001014:	c407b783          	ld	a5,-960(a5) # 80009c50 <kernel_pagetable>
    80001018:	83b1                	srli	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	slli	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	addi	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	addi	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	addi	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srli	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00008517          	auipc	a0,0x8
    80001058:	07c50513          	addi	a0,a0,124 # 800090d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srli	a5,s1,0xc
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb8d7>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04b2                	slli	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srli	a0,s3,0xc
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srli	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srli	a5,a5,0xa
    8000110c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	addi	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00008517          	auipc	a0,0x8
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800090d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00008517          	auipc	a0,0x8
    8000118e:	f5e50513          	addi	a0,a0,-162 # 800090e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00008517          	auipc	a0,0x8
    800011da:	f2250513          	addi	a0,a0,-222 # 800090f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00008917          	auipc	s2,0x8
    80001250:	db490913          	addi	s2,s2,-588 # 80009000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80008697          	auipc	a3,0x80008
    8000125a:	daa68693          	addi	a3,a3,-598 # 9000 <_entry-0x7fff7000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	slli	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	slli	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00007617          	auipc	a2,0x7
    8000128e:	d7660613          	addi	a2,a2,-650 # 80008000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	slli	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	addi	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	addi	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00009797          	auipc	a5,0x9
    800012d0:	98a7b223          	sd	a0,-1660(a5) # 80009c50 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	addi	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	addi	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	slli	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	slli	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	addi	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00008517          	auipc	a0,0x8
    80001326:	dde50513          	addi	a0,a0,-546 # 80009100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00008517          	auipc	a0,0x8
    80001336:	de650513          	addi	a0,a0,-538 # 80009118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00008517          	auipc	a0,0x8
    80001346:	de650513          	addi	a0,a0,-538 # 80009128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00008517          	auipc	a0,0x8
    80001356:	dee50513          	addi	a0,a0,-530 # 80009140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	andi	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	andi	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	slli	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	addi	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	addi	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00008517          	auipc	a0,0x8
    80001434:	d2850513          	addi	a0,a0,-728 # 80009158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	addi	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	addi	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	addi	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	addi	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	slli	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	andi	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	andi	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00008517          	auipc	a0,0x8
    80001580:	bfc50513          	addi	a0,a0,-1028 # 80009178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srli	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00008517          	auipc	a0,0x8
    8000165e:	b2e50513          	addi	a0,a0,-1234 # 80009188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00008517          	auipc	a0,0x8
    8000166e:	b3e50513          	addi	a0,a0,-1218 # 800091a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00008517          	auipc	a0,0x8
    800016d8:	af450513          	addi	a0,a0,-1292 # 800091c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	addi	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	addi	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addiw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdb8e0>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	addi	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addiw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	addi	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	addi	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	00011497          	auipc	s1,0x11
    800018c8:	a4c48493          	addi	s1,s1,-1460 # 80012310 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00007a97          	auipc	s5,0x7
    800018d2:	732a8a93          	addi	s5,s5,1842 # 80009000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00016a17          	auipc	s4,0x16
    800018e2:	632a0a13          	addi	s4,s4,1586 # 80017f10 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	srai	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addiw	a1,a1,1
    80001902:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	addi	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	addi	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00008517          	auipc	a0,0x8
    80001938:	8a450513          	addi	a0,a0,-1884 # 800091d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00008597          	auipc	a1,0x8
    8000195c:	88858593          	addi	a1,a1,-1912 # 800091e0 <digits+0x1a0>
    80001960:	00010517          	auipc	a0,0x10
    80001964:	58050513          	addi	a0,a0,1408 # 80011ee0 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00008597          	auipc	a1,0x8
    80001974:	87858593          	addi	a1,a1,-1928 # 800091e8 <digits+0x1a8>
    80001978:	00010517          	auipc	a0,0x10
    8000197c:	58050513          	addi	a0,a0,1408 # 80011ef8 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	00011497          	auipc	s1,0x11
    8000198c:	98848493          	addi	s1,s1,-1656 # 80012310 <proc>
      initlock(&p->lock, "proc");
    80001990:	00008b17          	auipc	s6,0x8
    80001994:	868b0b13          	addi	s6,s6,-1944 # 800091f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00007a17          	auipc	s4,0x7
    8000199e:	666a0a13          	addi	s4,s4,1638 # 80009000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00016997          	auipc	s3,0x16
    800019ae:	56698993          	addi	s3,s3,1382 # 80017f10 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	srai	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addiw	a5,a5,1
    800019d2:	00d7979b          	slliw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	addi	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	addi	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a14:	00010517          	auipc	a0,0x10
    80001a18:	4fc50513          	addi	a0,a0,1276 # 80011f10 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	addi	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	slli	a5,a5,0x7
    80001a3c:	00010717          	auipc	a4,0x10
    80001a40:	4a470713          	addi	a4,a4,1188 # 80011ee0 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	addi	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	00008797          	auipc	a5,0x8
    80001a78:	16c7a783          	lw	a5,364(a5) # 80009be0 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	c8a080e7          	jalr	-886(ra) # 80002708 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00008797          	auipc	a5,0x8
    80001a92:	1407a923          	sw	zero,338(a5) # 80009be0 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a14080e7          	jalr	-1516(ra) # 800034ac <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	00010917          	auipc	s2,0x10
    80001ab2:	43290913          	addi	s2,s2,1074 # 80011ee0 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	00008797          	auipc	a5,0x8
    80001ac4:	12478793          	addi	a5,a5,292 # 80009be4 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00006697          	auipc	a3,0x6
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80008000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00007597          	auipc	a1,0x7
    80001be8:	61c58593          	addi	a1,a1,1564 # 80009200 <digits+0x1c0>
    80001bec:	15850513          	addi	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c539                	beqz	a0,80001c46 <freeproc+0x70>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	40000613          	li	a2,1024
    80001c4c:	4585                	li	a1,1
    80001c4e:	05fe                	slli	a1,a1,0x1f
    80001c50:	68a8                	ld	a0,80(s1)
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	68a080e7          	jalr	1674(ra) # 800012dc <uvmunmap>
    80001c5a:	b745                	j	80001bfa <freeproc+0x24>

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00010497          	auipc	s1,0x10
    80001c6c:	6a848493          	addi	s1,s1,1704 # 80012310 <proc>
    80001c70:	00016917          	auipc	s2,0x16
    80001c74:	2a090913          	addi	s2,s2,672 # 80017f10 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	fce080e7          	jalr	-50(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	074080e7          	jalr	116(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a889                	j	80001cec <allocproc+0x90>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e06080e7          	jalr	-506(ra) # 80001aa2 <allocpid>
    80001ca4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e2e080e7          	jalr	-466(ra) # 80001ae8 <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	addi	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	072080e7          	jalr	114(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d8278793          	addi	a5,a5,-638 # 80001a5c <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	addi	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eda080e7          	jalr	-294(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ff6080e7          	jalr	-10(ra) # 80000cfc <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0x90>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ec2080e7          	jalr	-318(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fde080e7          	jalr	-34(ra) # 80000cfc <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0x90>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f28080e7          	jalr	-216(ra) # 80001c5c <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00008797          	auipc	a5,0x8
    80001d42:	f0a7bd23          	sd	a0,-230(a5) # 80009c58 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00008597          	auipc	a1,0x8
    80001d4e:	ea658593          	addi	a1,a1,-346 # 80009bf0 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	67a080e7          	jalr	1658(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00007597          	auipc	a1,0x7
    80001d70:	49c58593          	addi	a1,a1,1180 # 80009208 <digits+0x1c8>
    80001d74:	15848513          	addi	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	114080e7          	jalr	276(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00007517          	auipc	a0,0x7
    80001d84:	49850513          	addi	a0,a0,1176 # 80009218 <digits+0x1d8>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	142080e7          	jalr	322(ra) # 80003eca <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f62080e7          	jalr	-158(ra) # 80000cfc <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	addi	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	addi	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6a2080e7          	jalr	1698(ra) # 80001488 <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	644080e7          	jalr	1604(ra) # 80001440 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	addi	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c0a080e7          	jalr	-1014(ra) # 80001a24 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e38080e7          	jalr	-456(ra) # 80001c5c <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7a4080e7          	jalr	1956(ra) # 800015e0 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	addi	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	addi	a5,a5,32
    80001e76:	02070713          	addi	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	addi	s1,s5,208
    80001e8a:	0d0a0913          	addi	s2,s4,208
    80001e8e:	150a8993          	addi	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	d40080e7          	jalr	-704(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	e5c080e7          	jalr	-420(ra) # 80000cfc <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	addi	s1,s1,8
    80001eae:	0921                	addi	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	684080e7          	jalr	1668(ra) # 8000453c <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	81c080e7          	jalr	-2020(ra) # 800036e6 <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	addi	a1,s5,344
    80001edc:	158a0513          	addi	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	fac080e7          	jalr	-84(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e0e080e7          	jalr	-498(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001ef6:	00010497          	auipc	s1,0x10
    80001efa:	00248493          	addi	s1,s1,2 # 80011ef8 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d48080e7          	jalr	-696(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dee080e7          	jalr	-530(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d30080e7          	jalr	-720(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dd4080e7          	jalr	-556(ra) # 80000cfc <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	addi	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	addi	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	00010717          	auipc	a4,0x10
    80001f68:	f7c70713          	addi	a4,a4,-132 # 80011ee0 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	00010717          	auipc	a4,0x10
    80001f76:	fa670713          	addi	a4,a4,-90 # 80011f18 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	00010a17          	auipc	s4,0x10
    80001f86:	f5ea0a13          	addi	s4,s4,-162 # 80011ee0 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00016917          	auipc	s2,0x16
    80001f90:	f8490913          	addi	s2,s2,-124 # 80017f10 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	00010497          	auipc	s1,0x10
    80001fa4:	37048493          	addi	s1,s1,880 # 80012310 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c8a080e7          	jalr	-886(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	addi	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	684080e7          	jalr	1668(ra) # 8000265e <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a2e080e7          	jalr	-1490(ra) # 80001a24 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bce080e7          	jalr	-1074(ra) # 80000bce <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	00010717          	auipc	a4,0x10
    80002014:	ed070713          	addi	a4,a4,-304 # 80011ee0 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	00010917          	auipc	s2,0x10
    8000203a:	eaa90913          	addi	s2,s2,-342 # 80011ee0 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	00010597          	auipc	a1,0x10
    80002052:	eca58593          	addi	a1,a1,-310 # 80011f18 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	addi	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	602080e7          	jalr	1538(ra) # 8000265e <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00007517          	auipc	a0,0x7
    80002082:	1a250513          	addi	a0,a0,418 # 80009220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    panic("sched locks");
    8000208e:	00007517          	auipc	a0,0x7
    80002092:	1a250513          	addi	a0,a0,418 # 80009230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>
    panic("sched running");
    8000209e:	00007517          	auipc	a0,0x7
    800020a2:	1a250513          	addi	a0,a0,418 # 80009240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ae:	00007517          	auipc	a0,0x7
    800020b2:	1a250513          	addi	a0,a0,418 # 80009250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48a080e7          	jalr	1162(ra) # 80000540 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	95c080e7          	jalr	-1700(ra) # 80001a24 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b76080e7          	jalr	-1162(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	c14080e7          	jalr	-1004(ra) # 80000cfc <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	918080e7          	jalr	-1768(ra) # 80001a24 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	bdc080e7          	jalr	-1060(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	bbe080e7          	jalr	-1090(ra) # 80000cfc <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b00080e7          	jalr	-1280(ra) # 80000c48 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	addi	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	addi	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	00010497          	auipc	s1,0x10
    80002176:	19e48493          	addi	s1,s1,414 # 80012310 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00016917          	auipc	s2,0x16
    80002182:	d9290913          	addi	s2,s2,-622 # 80017f10 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b72080e7          	jalr	-1166(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	17048493          	addi	s1,s1,368
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	88a080e7          	jalr	-1910(ra) # 80001a24 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	aa0080e7          	jalr	-1376(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	addi	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	00010497          	auipc	s1,0x10
    800021ea:	12a48493          	addi	s1,s1,298 # 80012310 <proc>
      pp->parent = initproc;
    800021ee:	00008a17          	auipc	s4,0x8
    800021f2:	a6aa0a13          	addi	s4,s4,-1430 # 80009c58 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00016997          	auipc	s3,0x16
    800021fa:	d1a98993          	addi	s3,s3,-742 # 80017f10 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	17048493          	addi	s1,s1,368
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	addi	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	addi	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	7e4080e7          	jalr	2020(ra) # 80001a24 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00008797          	auipc	a5,0x8
    8000224e:	a0e7b783          	ld	a5,-1522(a5) # 80009c58 <initproc>
    80002252:	0d050493          	addi	s1,a0,208
    80002256:	15050913          	addi	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00007517          	auipc	a0,0x7
    80002262:	00a50513          	addi	a0,a0,10 # 80009268 <digits+0x228>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	320080e7          	jalr	800(ra) # 8000458e <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	addi	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	e44080e7          	jalr	-444(ra) # 800040ca <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00001097          	auipc	ra,0x1
    80002296:	64c080e7          	jalr	1612(ra) # 800038de <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	eaa080e7          	jalr	-342(ra) # 80004144 <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	00010497          	auipc	s1,0x10
    800022aa:	c5248493          	addi	s1,s1,-942 # 80011ef8 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	998080e7          	jalr	-1640(ra) # 80000c48 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	978080e7          	jalr	-1672(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a18080e7          	jalr	-1512(ra) # 80000cfc <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00007517          	auipc	a0,0x7
    800022f8:	f8450513          	addi	a0,a0,-124 # 80009278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	addi	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	00010497          	auipc	s1,0x10
    80002318:	ffc48493          	addi	s1,s1,-4 # 80012310 <proc>
    8000231c:	00016997          	auipc	s3,0x16
    80002320:	bf498993          	addi	s3,s3,-1036 # 80017f10 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	922080e7          	jalr	-1758(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9c6080e7          	jalr	-1594(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	17048493          	addi	s1,s1,368
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9a4080e7          	jalr	-1628(ra) # 80000cfc <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8c6080e7          	jalr	-1850(ra) # 80000c48 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	addi	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	898080e7          	jalr	-1896(ra) # 80000c48 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	93e080e7          	jalr	-1730(ra) # 80000cfc <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	addi	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	addi	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	00010517          	auipc	a0,0x10
    800023fc:	b0050513          	addi	a0,a0,-1280 # 80011ef8 <wait_lock>
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	848080e7          	jalr	-1976(ra) # 80000c48 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00016997          	auipc	s3,0x16
    80002412:	b0298993          	addi	s3,s3,-1278 # 80017f10 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	00010c17          	auipc	s8,0x10
    8000241a:	ae2c0c13          	addi	s8,s8,-1310 # 80011ef8 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	2b0080e7          	jalr	688(ra) # 800016e4 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	794080e7          	jalr	1940(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8b0080e7          	jalr	-1872(ra) # 80000cfc <release>
          release(&wait_lock);
    80002454:	00010517          	auipc	a0,0x10
    80002458:	aa450513          	addi	a0,a0,-1372 # 80011ef8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	87c080e7          	jalr	-1924(ra) # 80000cfc <release>
            release(&wait_lock);
    80002488:	00010517          	auipc	a0,0x10
    8000248c:	a7050513          	addi	a0,a0,-1424 # 80011ef8 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	79c080e7          	jalr	1948(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	840080e7          	jalr	-1984(ra) # 80000cfc <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	00010497          	auipc	s1,0x10
    800024e8:	e2c48493          	addi	s1,s1,-468 # 80012310 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	00010517          	auipc	a0,0x10
    800024f2:	a0a50513          	addi	a0,a0,-1526 # 80011ef8 <wait_lock>
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	806080e7          	jalr	-2042(ra) # 80000cfc <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	50a080e7          	jalr	1290(ra) # 80001a24 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	1b8080e7          	jalr	440(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	854080e7          	jalr	-1964(ra) # 80000da0 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	4b4080e7          	jalr	1204(ra) # 80001a24 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	1ee080e7          	jalr	494(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7fe080e7          	jalr	2046(ra) # 80000da0 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00007517          	auipc	a0,0x7
    800025c8:	4dc50513          	addi	a0,a0,1244 # 80009aa0 <syscalls+0x630>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	00010497          	auipc	s1,0x10
    800025d8:	e9448493          	addi	s1,s1,-364 # 80012468 <proc+0x158>
    800025dc:	00016917          	auipc	s2,0x16
    800025e0:	a8c90913          	addi	s2,s2,-1396 # 80018068 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00007997          	auipc	s3,0x7
    800025ea:	ca298993          	addi	s3,s3,-862 # 80009288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00007a97          	auipc	s5,0x7
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80009290 <digits+0x250>
    printf("\n");
    800025f6:	00007a17          	auipc	s4,0x7
    800025fa:	4aaa0a13          	addi	s4,s4,1194 # 80009aa0 <syscalls+0x630>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00007b97          	auipc	s7,0x7
    80002602:	cd2b8b93          	addi	s7,s7,-814 # 800092d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	17048493          	addi	s1,s1,368
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	slli	a4,a5,0x20
    8000263a:	01d75793          	srli	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d0:	00007597          	auipc	a1,0x7
    800026d4:	c3058593          	addi	a1,a1,-976 # 80009300 <states.0+0x30>
    800026d8:	00016517          	auipc	a0,0x16
    800026dc:	83850513          	addi	a0,a0,-1992 # 80017f10 <tickslock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	4d8080e7          	jalr	1240(ra) # 80000bb8 <initlock>
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	addi	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f0:	1141                	addi	sp,sp,-16
    800026f2:	e422                	sd	s0,8(sp)
    800026f4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	00003797          	auipc	a5,0x3
    800026fa:	53a78793          	addi	a5,a5,1338 # 80005c30 <kernelvec>
    800026fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	addi	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002708:	1141                	addi	sp,sp,-16
    8000270a:	e406                	sd	ra,8(sp)
    8000270c:	e022                	sd	s0,0(sp)
    8000270e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	314080e7          	jalr	788(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002722:	00006697          	auipc	a3,0x6
    80002726:	8de68693          	addi	a3,a3,-1826 # 80008000 <_trampoline>
    8000272a:	00006717          	auipc	a4,0x6
    8000272e:	8d670713          	addi	a4,a4,-1834 # 80008000 <_trampoline>
    80002732:	8f15                	sub	a4,a4,a3
    80002734:	040007b7          	lui	a5,0x4000
    80002738:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273a:	07b2                	slli	a5,a5,0xc
    8000273c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002744:	18002673          	csrr	a2,satp
    80002748:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274a:	6d30                	ld	a2,88(a0)
    8000274c:	6138                	ld	a4,64(a0)
    8000274e:	6585                	lui	a1,0x1
    80002750:	972e                	add	a4,a4,a1
    80002752:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	00000617          	auipc	a2,0x0
    8000275a:	13460613          	addi	a2,a2,308 # 8000288a <usertrap>
    8000275e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002760:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002762:	8612                	mv	a2,tp
    80002764:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002766:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002772:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002778:	6f18                	ld	a4,24(a4)
    8000277a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002782:	00006717          	auipc	a4,0x6
    80002786:	91a70713          	addi	a4,a4,-1766 # 8000809c <userret>
    8000278a:	8f15                	sub	a4,a4,a3
    8000278c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000278e:	577d                	li	a4,-1
    80002790:	177e                	slli	a4,a4,0x3f
    80002792:	8d59                	or	a0,a0,a4
    80002794:	9782                	jalr	a5
}
    80002796:	60a2                	ld	ra,8(sp)
    80002798:	6402                	ld	s0,0(sp)
    8000279a:	0141                	addi	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a8:	00015497          	auipc	s1,0x15
    800027ac:	76848493          	addi	s1,s1,1896 # 80017f10 <tickslock>
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	496080e7          	jalr	1174(ra) # 80000c48 <acquire>
  ticks++;
    800027ba:	00007517          	auipc	a0,0x7
    800027be:	4a650513          	addi	a0,a0,1190 # 80009c60 <ticks>
    800027c2:	411c                	lw	a5,0(a0)
    800027c4:	2785                	addiw	a5,a5,1
    800027c6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	996080e7          	jalr	-1642(ra) # 8000215e <wakeup>
  release(&tickslock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	52a080e7          	jalr	1322(ra) # 80000cfc <release>
}
    800027da:	60e2                	ld	ra,24(sp)
    800027dc:	6442                	ld	s0,16(sp)
    800027de:	64a2                	ld	s1,8(sp)
    800027e0:	6105                	addi	sp,sp,32
    800027e2:	8082                	ret

00000000800027e4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e4:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e8:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027ea:	0807df63          	bgez	a5,80002888 <devintr+0xa4>
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800027f8:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027fc:	46a5                	li	a3,9
    800027fe:	00d70d63          	beq	a4,a3,80002818 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002802:	577d                	li	a4,-1
    80002804:	177e                	slli	a4,a4,0x3f
    80002806:	0705                	addi	a4,a4,1
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	04e78e63          	beq	a5,a4,80002866 <devintr+0x82>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret
    int irq = plic_claim();
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	520080e7          	jalr	1312(ra) # 80005d38 <plic_claim>
    80002820:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002822:	47a9                	li	a5,10
    80002824:	02f50763          	beq	a0,a5,80002852 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002828:	4785                	li	a5,1
    8000282a:	02f50963          	beq	a0,a5,8000285c <devintr+0x78>
    return 1;
    8000282e:	4505                	li	a0,1
    } else if(irq){
    80002830:	dcf9                	beqz	s1,8000280e <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002832:	85a6                	mv	a1,s1
    80002834:	00007517          	auipc	a0,0x7
    80002838:	ad450513          	addi	a0,a0,-1324 # 80009308 <states.0+0x38>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d4e080e7          	jalr	-690(ra) # 8000058a <printf>
      plic_complete(irq);
    80002844:	8526                	mv	a0,s1
    80002846:	00003097          	auipc	ra,0x3
    8000284a:	516080e7          	jalr	1302(ra) # 80005d5c <plic_complete>
    return 1;
    8000284e:	4505                	li	a0,1
    80002850:	bf7d                	j	8000280e <devintr+0x2a>
      uartintr();
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	1b8080e7          	jalr	440(ra) # 80000a0a <uartintr>
    if(irq)
    8000285a:	b7ed                	j	80002844 <devintr+0x60>
      virtio_disk_intr();
    8000285c:	00004097          	auipc	ra,0x4
    80002860:	b78080e7          	jalr	-1160(ra) # 800063d4 <virtio_disk_intr>
    if(irq)
    80002864:	b7c5                	j	80002844 <devintr+0x60>
    if(cpuid() == 0){
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	192080e7          	jalr	402(ra) # 800019f8 <cpuid>
    8000286e:	c901                	beqz	a0,8000287e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002870:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002874:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002876:	14479073          	csrw	sip,a5
    return 2;
    8000287a:	4509                	li	a0,2
    8000287c:	bf49                	j	8000280e <devintr+0x2a>
      clockintr();
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	f20080e7          	jalr	-224(ra) # 8000279e <clockintr>
    80002886:	b7ed                	j	80002870 <devintr+0x8c>
}
    80002888:	8082                	ret

000000008000288a <usertrap>:
{
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	e04a                	sd	s2,0(sp)
    80002894:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289a:	1007f793          	andi	a5,a5,256
    8000289e:	ebb1                	bnez	a5,800028f2 <usertrap+0x68>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	39078793          	addi	a5,a5,912 # 80005c30 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	178080e7          	jalr	376(ra) # 80001a24 <myproc>
    800028b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b8:	14102773          	csrr	a4,sepc
    800028bc:	ef98                	sd	a4,24(a5)
  if (p->vmprocess == true && (r_scause() == 2))
    800028be:	16c54783          	lbu	a5,364(a0)
    800028c2:	c791                	beqz	a5,800028ce <usertrap+0x44>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c4:	14202773          	csrr	a4,scause
    800028c8:	4789                	li	a5,2
    800028ca:	02f70c63          	beq	a4,a5,80002902 <usertrap+0x78>
    800028ce:	14202773          	csrr	a4,scause
  else if(r_scause() == 8){
    800028d2:	47a1                	li	a5,8
    800028d4:	06f70163          	beq	a4,a5,80002936 <usertrap+0xac>
  } else if((which_dev = devintr()) != 0){
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	f0c080e7          	jalr	-244(ra) # 800027e4 <devintr>
    800028e0:	892a                	mv	s2,a0
    800028e2:	cd49                	beqz	a0,8000297c <usertrap+0xf2>
  if(killed(p))
    800028e4:	8526                	mv	a0,s1
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	abc080e7          	jalr	-1348(ra) # 800023a2 <killed>
    800028ee:	c96d                	beqz	a0,800029e0 <usertrap+0x156>
    800028f0:	a0dd                	j	800029d6 <usertrap+0x14c>
    panic("usertrap: not from user mode");
    800028f2:	00007517          	auipc	a0,0x7
    800028f6:	a3650513          	addi	a0,a0,-1482 # 80009328 <states.0+0x58>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c46080e7          	jalr	-954(ra) # 80000540 <panic>
    trap_and_emulate();
    80002902:	00004097          	auipc	ra,0x4
    80002906:	f48080e7          	jalr	-184(ra) # 8000684a <trap_and_emulate>
    if(p->vmprocess == true && r_scause() == 15){
    8000290a:	16c4c783          	lbu	a5,364(s1)
    8000290e:	c3dd                	beqz	a5,800029b4 <usertrap+0x12a>
    80002910:	14202773          	csrr	a4,scause
    80002914:	47bd                	li	a5,15
    80002916:	08f71f63          	bne	a4,a5,800029b4 <usertrap+0x12a>
        kill(p->pid);
    8000291a:	5888                	lw	a0,48(s1)
    8000291c:	00000097          	auipc	ra,0x0
    80002920:	9e8080e7          	jalr	-1560(ra) # 80002304 <kill>
        printf("Killed from trap.c");
    80002924:	00007517          	auipc	a0,0x7
    80002928:	a2450513          	addi	a0,a0,-1500 # 80009348 <states.0+0x78>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c5e080e7          	jalr	-930(ra) # 8000058a <printf>
    80002934:	a041                	j	800029b4 <usertrap+0x12a>
    if(killed(p))
    80002936:	8526                	mv	a0,s1
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	a6a080e7          	jalr	-1430(ra) # 800023a2 <killed>
    80002940:	e909                	bnez	a0,80002952 <usertrap+0xc8>
    if(p->vmprocess == true)
    80002942:	16c4c783          	lbu	a5,364(s1)
    80002946:	cf81                	beqz	a5,8000295e <usertrap+0xd4>
      trap_and_emulate();
    80002948:	00004097          	auipc	ra,0x4
    8000294c:	f02080e7          	jalr	-254(ra) # 8000684a <trap_and_emulate>
    80002950:	a095                	j	800029b4 <usertrap+0x12a>
      exit(-1);
    80002952:	557d                	li	a0,-1
    80002954:	00000097          	auipc	ra,0x0
    80002958:	8da080e7          	jalr	-1830(ra) # 8000222e <exit>
    8000295c:	b7dd                	j	80002942 <usertrap+0xb8>
    else{p->trapframe->epc += 4;
    8000295e:	6cb8                	ld	a4,88(s1)
    80002960:	6f1c                	ld	a5,24(a4)
    80002962:	0791                	addi	a5,a5,4
    80002964:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002966:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000296a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296e:	10079073          	csrw	sstatus,a5
    syscall();
    80002972:	00000097          	auipc	ra,0x0
    80002976:	2c8080e7          	jalr	712(ra) # 80002c3a <syscall>
    8000297a:	a82d                	j	800029b4 <usertrap+0x12a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002980:	5890                	lw	a2,48(s1)
    80002982:	00007517          	auipc	a0,0x7
    80002986:	9de50513          	addi	a0,a0,-1570 # 80009360 <states.0+0x90>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c00080e7          	jalr	-1024(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002992:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002996:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299a:	00007517          	auipc	a0,0x7
    8000299e:	9f650513          	addi	a0,a0,-1546 # 80009390 <states.0+0xc0>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	be8080e7          	jalr	-1048(ra) # 8000058a <printf>
    setkilled(p);
    800029aa:	8526                	mv	a0,s1
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	9ca080e7          	jalr	-1590(ra) # 80002376 <setkilled>
  if(killed(p))
    800029b4:	8526                	mv	a0,s1
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	9ec080e7          	jalr	-1556(ra) # 800023a2 <killed>
    800029be:	e919                	bnez	a0,800029d4 <usertrap+0x14a>
  usertrapret();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	d48080e7          	jalr	-696(ra) # 80002708 <usertrapret>
}
    800029c8:	60e2                	ld	ra,24(sp)
    800029ca:	6442                	ld	s0,16(sp)
    800029cc:	64a2                	ld	s1,8(sp)
    800029ce:	6902                	ld	s2,0(sp)
    800029d0:	6105                	addi	sp,sp,32
    800029d2:	8082                	ret
  if(killed(p))
    800029d4:	4901                	li	s2,0
    exit(-1);
    800029d6:	557d                	li	a0,-1
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	856080e7          	jalr	-1962(ra) # 8000222e <exit>
  if(which_dev == 2)
    800029e0:	4789                	li	a5,2
    800029e2:	fcf91fe3          	bne	s2,a5,800029c0 <usertrap+0x136>
    yield();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	6d8080e7          	jalr	1752(ra) # 800020be <yield>
    800029ee:	bfc9                	j	800029c0 <usertrap+0x136>

00000000800029f0 <kerneltrap>:
{
    800029f0:	7179                	addi	sp,sp,-48
    800029f2:	f406                	sd	ra,40(sp)
    800029f4:	f022                	sd	s0,32(sp)
    800029f6:	ec26                	sd	s1,24(sp)
    800029f8:	e84a                	sd	s2,16(sp)
    800029fa:	e44e                	sd	s3,8(sp)
    800029fc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fe:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a06:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a0a:	1004f793          	andi	a5,s1,256
    80002a0e:	cb85                	beqz	a5,80002a3e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a14:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a16:	ef85                	bnez	a5,80002a4e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	dcc080e7          	jalr	-564(ra) # 800027e4 <devintr>
    80002a20:	cd1d                	beqz	a0,80002a5e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a22:	4789                	li	a5,2
    80002a24:	06f50a63          	beq	a0,a5,80002a98 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a28:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2c:	10049073          	csrw	sstatus,s1
}
    80002a30:	70a2                	ld	ra,40(sp)
    80002a32:	7402                	ld	s0,32(sp)
    80002a34:	64e2                	ld	s1,24(sp)
    80002a36:	6942                	ld	s2,16(sp)
    80002a38:	69a2                	ld	s3,8(sp)
    80002a3a:	6145                	addi	sp,sp,48
    80002a3c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a3e:	00007517          	auipc	a0,0x7
    80002a42:	97250513          	addi	a0,a0,-1678 # 800093b0 <states.0+0xe0>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	afa080e7          	jalr	-1286(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a4e:	00007517          	auipc	a0,0x7
    80002a52:	98a50513          	addi	a0,a0,-1654 # 800093d8 <states.0+0x108>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a5e:	85ce                	mv	a1,s3
    80002a60:	00007517          	auipc	a0,0x7
    80002a64:	99850513          	addi	a0,a0,-1640 # 800093f8 <states.0+0x128>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	b22080e7          	jalr	-1246(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a74:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a78:	00007517          	auipc	a0,0x7
    80002a7c:	99050513          	addi	a0,a0,-1648 # 80009408 <states.0+0x138>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b0a080e7          	jalr	-1270(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a88:	00007517          	auipc	a0,0x7
    80002a8c:	99850513          	addi	a0,a0,-1640 # 80009420 <states.0+0x150>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	ab0080e7          	jalr	-1360(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	f8c080e7          	jalr	-116(ra) # 80001a24 <myproc>
    80002aa0:	d541                	beqz	a0,80002a28 <kerneltrap+0x38>
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	f82080e7          	jalr	-126(ra) # 80001a24 <myproc>
    80002aaa:	4d18                	lw	a4,24(a0)
    80002aac:	4791                	li	a5,4
    80002aae:	f6f71de3          	bne	a4,a5,80002a28 <kerneltrap+0x38>
    yield();
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	60c080e7          	jalr	1548(ra) # 800020be <yield>
    80002aba:	b7bd                	j	80002a28 <kerneltrap+0x38>

0000000080002abc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	f5c080e7          	jalr	-164(ra) # 80001a24 <myproc>
  switch (n) {
    80002ad0:	4795                	li	a5,5
    80002ad2:	0497e163          	bltu	a5,s1,80002b14 <argraw+0x58>
    80002ad6:	048a                	slli	s1,s1,0x2
    80002ad8:	00007717          	auipc	a4,0x7
    80002adc:	98070713          	addi	a4,a4,-1664 # 80009458 <states.0+0x188>
    80002ae0:	94ba                	add	s1,s1,a4
    80002ae2:	409c                	lw	a5,0(s1)
    80002ae4:	97ba                	add	a5,a5,a4
    80002ae6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6105                	addi	sp,sp,32
    80002af4:	8082                	ret
    return p->trapframe->a1;
    80002af6:	6d3c                	ld	a5,88(a0)
    80002af8:	7fa8                	ld	a0,120(a5)
    80002afa:	bfcd                	j	80002aec <argraw+0x30>
    return p->trapframe->a2;
    80002afc:	6d3c                	ld	a5,88(a0)
    80002afe:	63c8                	ld	a0,128(a5)
    80002b00:	b7f5                	j	80002aec <argraw+0x30>
    return p->trapframe->a3;
    80002b02:	6d3c                	ld	a5,88(a0)
    80002b04:	67c8                	ld	a0,136(a5)
    80002b06:	b7dd                	j	80002aec <argraw+0x30>
    return p->trapframe->a4;
    80002b08:	6d3c                	ld	a5,88(a0)
    80002b0a:	6bc8                	ld	a0,144(a5)
    80002b0c:	b7c5                	j	80002aec <argraw+0x30>
    return p->trapframe->a5;
    80002b0e:	6d3c                	ld	a5,88(a0)
    80002b10:	6fc8                	ld	a0,152(a5)
    80002b12:	bfe9                	j	80002aec <argraw+0x30>
  panic("argraw");
    80002b14:	00007517          	auipc	a0,0x7
    80002b18:	91c50513          	addi	a0,a0,-1764 # 80009430 <states.0+0x160>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a24080e7          	jalr	-1500(ra) # 80000540 <panic>

0000000080002b24 <fetchaddr>:
{
    80002b24:	1101                	addi	sp,sp,-32
    80002b26:	ec06                	sd	ra,24(sp)
    80002b28:	e822                	sd	s0,16(sp)
    80002b2a:	e426                	sd	s1,8(sp)
    80002b2c:	e04a                	sd	s2,0(sp)
    80002b2e:	1000                	addi	s0,sp,32
    80002b30:	84aa                	mv	s1,a0
    80002b32:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	ef0080e7          	jalr	-272(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b3c:	653c                	ld	a5,72(a0)
    80002b3e:	02f4f863          	bgeu	s1,a5,80002b6e <fetchaddr+0x4a>
    80002b42:	00848713          	addi	a4,s1,8
    80002b46:	02e7e663          	bltu	a5,a4,80002b72 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b4a:	46a1                	li	a3,8
    80002b4c:	8626                	mv	a2,s1
    80002b4e:	85ca                	mv	a1,s2
    80002b50:	6928                	ld	a0,80(a0)
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	c1e080e7          	jalr	-994(ra) # 80001770 <copyin>
    80002b5a:	00a03533          	snez	a0,a0
    80002b5e:	40a00533          	neg	a0,a0
}
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6902                	ld	s2,0(sp)
    80002b6a:	6105                	addi	sp,sp,32
    80002b6c:	8082                	ret
    return -1;
    80002b6e:	557d                	li	a0,-1
    80002b70:	bfcd                	j	80002b62 <fetchaddr+0x3e>
    80002b72:	557d                	li	a0,-1
    80002b74:	b7fd                	j	80002b62 <fetchaddr+0x3e>

0000000080002b76 <fetchstr>:
{
    80002b76:	7179                	addi	sp,sp,-48
    80002b78:	f406                	sd	ra,40(sp)
    80002b7a:	f022                	sd	s0,32(sp)
    80002b7c:	ec26                	sd	s1,24(sp)
    80002b7e:	e84a                	sd	s2,16(sp)
    80002b80:	e44e                	sd	s3,8(sp)
    80002b82:	1800                	addi	s0,sp,48
    80002b84:	892a                	mv	s2,a0
    80002b86:	84ae                	mv	s1,a1
    80002b88:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	e9a080e7          	jalr	-358(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b92:	86ce                	mv	a3,s3
    80002b94:	864a                	mv	a2,s2
    80002b96:	85a6                	mv	a1,s1
    80002b98:	6928                	ld	a0,80(a0)
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	c64080e7          	jalr	-924(ra) # 800017fe <copyinstr>
    80002ba2:	00054e63          	bltz	a0,80002bbe <fetchstr+0x48>
  return strlen(buf);
    80002ba6:	8526                	mv	a0,s1
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	316080e7          	jalr	790(ra) # 80000ebe <strlen>
}
    80002bb0:	70a2                	ld	ra,40(sp)
    80002bb2:	7402                	ld	s0,32(sp)
    80002bb4:	64e2                	ld	s1,24(sp)
    80002bb6:	6942                	ld	s2,16(sp)
    80002bb8:	69a2                	ld	s3,8(sp)
    80002bba:	6145                	addi	sp,sp,48
    80002bbc:	8082                	ret
    return -1;
    80002bbe:	557d                	li	a0,-1
    80002bc0:	bfc5                	j	80002bb0 <fetchstr+0x3a>

0000000080002bc2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	eee080e7          	jalr	-274(ra) # 80002abc <argraw>
    80002bd6:	c088                	sw	a0,0(s1)
}
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6105                	addi	sp,sp,32
    80002be0:	8082                	ret

0000000080002be2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	1000                	addi	s0,sp,32
    80002bec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	ece080e7          	jalr	-306(ra) # 80002abc <argraw>
    80002bf6:	e088                	sd	a0,0(s1)
}
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6105                	addi	sp,sp,32
    80002c00:	8082                	ret

0000000080002c02 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c02:	7179                	addi	sp,sp,-48
    80002c04:	f406                	sd	ra,40(sp)
    80002c06:	f022                	sd	s0,32(sp)
    80002c08:	ec26                	sd	s1,24(sp)
    80002c0a:	e84a                	sd	s2,16(sp)
    80002c0c:	1800                	addi	s0,sp,48
    80002c0e:	84ae                	mv	s1,a1
    80002c10:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c12:	fd840593          	addi	a1,s0,-40
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	fcc080e7          	jalr	-52(ra) # 80002be2 <argaddr>
  return fetchstr(addr, buf, max);
    80002c1e:	864a                	mv	a2,s2
    80002c20:	85a6                	mv	a1,s1
    80002c22:	fd843503          	ld	a0,-40(s0)
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	f50080e7          	jalr	-176(ra) # 80002b76 <fetchstr>
}
    80002c2e:	70a2                	ld	ra,40(sp)
    80002c30:	7402                	ld	s0,32(sp)
    80002c32:	64e2                	ld	s1,24(sp)
    80002c34:	6942                	ld	s2,16(sp)
    80002c36:	6145                	addi	sp,sp,48
    80002c38:	8082                	ret

0000000080002c3a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	e04a                	sd	s2,0(sp)
    80002c44:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	dde080e7          	jalr	-546(ra) # 80001a24 <myproc>
    80002c4e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c50:	05853903          	ld	s2,88(a0)
    80002c54:	0a893783          	ld	a5,168(s2)
    80002c58:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c5c:	37fd                	addiw	a5,a5,-1
    80002c5e:	4751                	li	a4,20
    80002c60:	00f76f63          	bltu	a4,a5,80002c7e <syscall+0x44>
    80002c64:	00369713          	slli	a4,a3,0x3
    80002c68:	00007797          	auipc	a5,0x7
    80002c6c:	80878793          	addi	a5,a5,-2040 # 80009470 <syscalls>
    80002c70:	97ba                	add	a5,a5,a4
    80002c72:	639c                	ld	a5,0(a5)
    80002c74:	c789                	beqz	a5,80002c7e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c76:	9782                	jalr	a5
    80002c78:	06a93823          	sd	a0,112(s2)
    80002c7c:	a839                	j	80002c9a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c7e:	15848613          	addi	a2,s1,344
    80002c82:	588c                	lw	a1,48(s1)
    80002c84:	00006517          	auipc	a0,0x6
    80002c88:	7b450513          	addi	a0,a0,1972 # 80009438 <states.0+0x168>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8fe080e7          	jalr	-1794(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c94:	6cbc                	ld	a5,88(s1)
    80002c96:	577d                	li	a4,-1
    80002c98:	fbb8                	sd	a4,112(a5)
  }
}
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	64a2                	ld	s1,8(sp)
    80002ca0:	6902                	ld	s2,0(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret

0000000080002ca6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ca6:	1101                	addi	sp,sp,-32
    80002ca8:	ec06                	sd	ra,24(sp)
    80002caa:	e822                	sd	s0,16(sp)
    80002cac:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cae:	fec40593          	addi	a1,s0,-20
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	f0e080e7          	jalr	-242(ra) # 80002bc2 <argint>
  exit(n);
    80002cbc:	fec42503          	lw	a0,-20(s0)
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	56e080e7          	jalr	1390(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002cc8:	4501                	li	a0,0
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret

0000000080002cd2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cd2:	1141                	addi	sp,sp,-16
    80002cd4:	e406                	sd	ra,8(sp)
    80002cd6:	e022                	sd	s0,0(sp)
    80002cd8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	d4a080e7          	jalr	-694(ra) # 80001a24 <myproc>
}
    80002ce2:	5908                	lw	a0,48(a0)
    80002ce4:	60a2                	ld	ra,8(sp)
    80002ce6:	6402                	ld	s0,0(sp)
    80002ce8:	0141                	addi	sp,sp,16
    80002cea:	8082                	ret

0000000080002cec <sys_fork>:

uint64
sys_fork(void)
{
    80002cec:	1141                	addi	sp,sp,-16
    80002cee:	e406                	sd	ra,8(sp)
    80002cf0:	e022                	sd	s0,0(sp)
    80002cf2:	0800                	addi	s0,sp,16
  return fork();
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	114080e7          	jalr	276(ra) # 80001e08 <fork>
}
    80002cfc:	60a2                	ld	ra,8(sp)
    80002cfe:	6402                	ld	s0,0(sp)
    80002d00:	0141                	addi	sp,sp,16
    80002d02:	8082                	ret

0000000080002d04 <sys_wait>:

uint64
sys_wait(void)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d0c:	fe840593          	addi	a1,s0,-24
    80002d10:	4501                	li	a0,0
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	ed0080e7          	jalr	-304(ra) # 80002be2 <argaddr>
  return wait(p);
    80002d1a:	fe843503          	ld	a0,-24(s0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	6b6080e7          	jalr	1718(ra) # 800023d4 <wait>
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d2e:	7179                	addi	sp,sp,-48
    80002d30:	f406                	sd	ra,40(sp)
    80002d32:	f022                	sd	s0,32(sp)
    80002d34:	ec26                	sd	s1,24(sp)
    80002d36:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d38:	fdc40593          	addi	a1,s0,-36
    80002d3c:	4501                	li	a0,0
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	e84080e7          	jalr	-380(ra) # 80002bc2 <argint>
  addr = myproc()->sz;
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	cde080e7          	jalr	-802(ra) # 80001a24 <myproc>
    80002d4e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d50:	fdc42503          	lw	a0,-36(s0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	058080e7          	jalr	88(ra) # 80001dac <growproc>
    80002d5c:	00054863          	bltz	a0,80002d6c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d60:	8526                	mv	a0,s1
    80002d62:	70a2                	ld	ra,40(sp)
    80002d64:	7402                	ld	s0,32(sp)
    80002d66:	64e2                	ld	s1,24(sp)
    80002d68:	6145                	addi	sp,sp,48
    80002d6a:	8082                	ret
    return -1;
    80002d6c:	54fd                	li	s1,-1
    80002d6e:	bfcd                	j	80002d60 <sys_sbrk+0x32>

0000000080002d70 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d70:	7139                	addi	sp,sp,-64
    80002d72:	fc06                	sd	ra,56(sp)
    80002d74:	f822                	sd	s0,48(sp)
    80002d76:	f426                	sd	s1,40(sp)
    80002d78:	f04a                	sd	s2,32(sp)
    80002d7a:	ec4e                	sd	s3,24(sp)
    80002d7c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d7e:	fcc40593          	addi	a1,s0,-52
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	e3e080e7          	jalr	-450(ra) # 80002bc2 <argint>
  acquire(&tickslock);
    80002d8c:	00015517          	auipc	a0,0x15
    80002d90:	18450513          	addi	a0,a0,388 # 80017f10 <tickslock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	eb4080e7          	jalr	-332(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002d9c:	00007917          	auipc	s2,0x7
    80002da0:	ec492903          	lw	s2,-316(s2) # 80009c60 <ticks>
  while(ticks - ticks0 < n){
    80002da4:	fcc42783          	lw	a5,-52(s0)
    80002da8:	cf9d                	beqz	a5,80002de6 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002daa:	00015997          	auipc	s3,0x15
    80002dae:	16698993          	addi	s3,s3,358 # 80017f10 <tickslock>
    80002db2:	00007497          	auipc	s1,0x7
    80002db6:	eae48493          	addi	s1,s1,-338 # 80009c60 <ticks>
    if(killed(myproc())){
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	5e0080e7          	jalr	1504(ra) # 800023a2 <killed>
    80002dca:	ed15                	bnez	a0,80002e06 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dcc:	85ce                	mv	a1,s3
    80002dce:	8526                	mv	a0,s1
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	32a080e7          	jalr	810(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002dd8:	409c                	lw	a5,0(s1)
    80002dda:	412787bb          	subw	a5,a5,s2
    80002dde:	fcc42703          	lw	a4,-52(s0)
    80002de2:	fce7ece3          	bltu	a5,a4,80002dba <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002de6:	00015517          	auipc	a0,0x15
    80002dea:	12a50513          	addi	a0,a0,298 # 80017f10 <tickslock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	f0e080e7          	jalr	-242(ra) # 80000cfc <release>
  return 0;
    80002df6:	4501                	li	a0,0
}
    80002df8:	70e2                	ld	ra,56(sp)
    80002dfa:	7442                	ld	s0,48(sp)
    80002dfc:	74a2                	ld	s1,40(sp)
    80002dfe:	7902                	ld	s2,32(sp)
    80002e00:	69e2                	ld	s3,24(sp)
    80002e02:	6121                	addi	sp,sp,64
    80002e04:	8082                	ret
      release(&tickslock);
    80002e06:	00015517          	auipc	a0,0x15
    80002e0a:	10a50513          	addi	a0,a0,266 # 80017f10 <tickslock>
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	eee080e7          	jalr	-274(ra) # 80000cfc <release>
      return -1;
    80002e16:	557d                	li	a0,-1
    80002e18:	b7c5                	j	80002df8 <sys_sleep+0x88>

0000000080002e1a <sys_kill>:

uint64
sys_kill(void)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e22:	fec40593          	addi	a1,s0,-20
    80002e26:	4501                	li	a0,0
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	d9a080e7          	jalr	-614(ra) # 80002bc2 <argint>
  return kill(pid);
    80002e30:	fec42503          	lw	a0,-20(s0)
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	4d0080e7          	jalr	1232(ra) # 80002304 <kill>
}
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret

0000000080002e44 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	e426                	sd	s1,8(sp)
    80002e4c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e4e:	00015517          	auipc	a0,0x15
    80002e52:	0c250513          	addi	a0,a0,194 # 80017f10 <tickslock>
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	df2080e7          	jalr	-526(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e5e:	00007497          	auipc	s1,0x7
    80002e62:	e024a483          	lw	s1,-510(s1) # 80009c60 <ticks>
  release(&tickslock);
    80002e66:	00015517          	auipc	a0,0x15
    80002e6a:	0aa50513          	addi	a0,a0,170 # 80017f10 <tickslock>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	e8e080e7          	jalr	-370(ra) # 80000cfc <release>
  return xticks;
}
    80002e76:	02049513          	slli	a0,s1,0x20
    80002e7a:	9101                	srli	a0,a0,0x20
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	64a2                	ld	s1,8(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e86:	7179                	addi	sp,sp,-48
    80002e88:	f406                	sd	ra,40(sp)
    80002e8a:	f022                	sd	s0,32(sp)
    80002e8c:	ec26                	sd	s1,24(sp)
    80002e8e:	e84a                	sd	s2,16(sp)
    80002e90:	e44e                	sd	s3,8(sp)
    80002e92:	e052                	sd	s4,0(sp)
    80002e94:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e96:	00006597          	auipc	a1,0x6
    80002e9a:	68a58593          	addi	a1,a1,1674 # 80009520 <syscalls+0xb0>
    80002e9e:	00015517          	auipc	a0,0x15
    80002ea2:	08a50513          	addi	a0,a0,138 # 80017f28 <bcache>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	d12080e7          	jalr	-750(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eae:	0001d797          	auipc	a5,0x1d
    80002eb2:	07a78793          	addi	a5,a5,122 # 8001ff28 <bcache+0x8000>
    80002eb6:	0001d717          	auipc	a4,0x1d
    80002eba:	2da70713          	addi	a4,a4,730 # 80020190 <bcache+0x8268>
    80002ebe:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ec2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ec6:	00015497          	auipc	s1,0x15
    80002eca:	07a48493          	addi	s1,s1,122 # 80017f40 <bcache+0x18>
    b->next = bcache.head.next;
    80002ece:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ed0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ed2:	00006a17          	auipc	s4,0x6
    80002ed6:	656a0a13          	addi	s4,s4,1622 # 80009528 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002eda:	2b893783          	ld	a5,696(s2)
    80002ede:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ee0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ee4:	85d2                	mv	a1,s4
    80002ee6:	01048513          	addi	a0,s1,16
    80002eea:	00001097          	auipc	ra,0x1
    80002eee:	496080e7          	jalr	1174(ra) # 80004380 <initsleeplock>
    bcache.head.next->prev = b;
    80002ef2:	2b893783          	ld	a5,696(s2)
    80002ef6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ef8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002efc:	45848493          	addi	s1,s1,1112
    80002f00:	fd349de3          	bne	s1,s3,80002eda <binit+0x54>
  }
}
    80002f04:	70a2                	ld	ra,40(sp)
    80002f06:	7402                	ld	s0,32(sp)
    80002f08:	64e2                	ld	s1,24(sp)
    80002f0a:	6942                	ld	s2,16(sp)
    80002f0c:	69a2                	ld	s3,8(sp)
    80002f0e:	6a02                	ld	s4,0(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret

0000000080002f14 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f14:	7179                	addi	sp,sp,-48
    80002f16:	f406                	sd	ra,40(sp)
    80002f18:	f022                	sd	s0,32(sp)
    80002f1a:	ec26                	sd	s1,24(sp)
    80002f1c:	e84a                	sd	s2,16(sp)
    80002f1e:	e44e                	sd	s3,8(sp)
    80002f20:	1800                	addi	s0,sp,48
    80002f22:	892a                	mv	s2,a0
    80002f24:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f26:	00015517          	auipc	a0,0x15
    80002f2a:	00250513          	addi	a0,a0,2 # 80017f28 <bcache>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	d1a080e7          	jalr	-742(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f36:	0001d497          	auipc	s1,0x1d
    80002f3a:	2aa4b483          	ld	s1,682(s1) # 800201e0 <bcache+0x82b8>
    80002f3e:	0001d797          	auipc	a5,0x1d
    80002f42:	25278793          	addi	a5,a5,594 # 80020190 <bcache+0x8268>
    80002f46:	02f48f63          	beq	s1,a5,80002f84 <bread+0x70>
    80002f4a:	873e                	mv	a4,a5
    80002f4c:	a021                	j	80002f54 <bread+0x40>
    80002f4e:	68a4                	ld	s1,80(s1)
    80002f50:	02e48a63          	beq	s1,a4,80002f84 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f54:	449c                	lw	a5,8(s1)
    80002f56:	ff279ce3          	bne	a5,s2,80002f4e <bread+0x3a>
    80002f5a:	44dc                	lw	a5,12(s1)
    80002f5c:	ff3799e3          	bne	a5,s3,80002f4e <bread+0x3a>
      b->refcnt++;
    80002f60:	40bc                	lw	a5,64(s1)
    80002f62:	2785                	addiw	a5,a5,1
    80002f64:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f66:	00015517          	auipc	a0,0x15
    80002f6a:	fc250513          	addi	a0,a0,-62 # 80017f28 <bcache>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	d8e080e7          	jalr	-626(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002f76:	01048513          	addi	a0,s1,16
    80002f7a:	00001097          	auipc	ra,0x1
    80002f7e:	440080e7          	jalr	1088(ra) # 800043ba <acquiresleep>
      return b;
    80002f82:	a8b9                	j	80002fe0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f84:	0001d497          	auipc	s1,0x1d
    80002f88:	2544b483          	ld	s1,596(s1) # 800201d8 <bcache+0x82b0>
    80002f8c:	0001d797          	auipc	a5,0x1d
    80002f90:	20478793          	addi	a5,a5,516 # 80020190 <bcache+0x8268>
    80002f94:	00f48863          	beq	s1,a5,80002fa4 <bread+0x90>
    80002f98:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f9a:	40bc                	lw	a5,64(s1)
    80002f9c:	cf81                	beqz	a5,80002fb4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f9e:	64a4                	ld	s1,72(s1)
    80002fa0:	fee49de3          	bne	s1,a4,80002f9a <bread+0x86>
  panic("bget: no buffers");
    80002fa4:	00006517          	auipc	a0,0x6
    80002fa8:	58c50513          	addi	a0,a0,1420 # 80009530 <syscalls+0xc0>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	594080e7          	jalr	1428(ra) # 80000540 <panic>
      b->dev = dev;
    80002fb4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fb8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fbc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fc0:	4785                	li	a5,1
    80002fc2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc4:	00015517          	auipc	a0,0x15
    80002fc8:	f6450513          	addi	a0,a0,-156 # 80017f28 <bcache>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	d30080e7          	jalr	-720(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002fd4:	01048513          	addi	a0,s1,16
    80002fd8:	00001097          	auipc	ra,0x1
    80002fdc:	3e2080e7          	jalr	994(ra) # 800043ba <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fe0:	409c                	lw	a5,0(s1)
    80002fe2:	cb89                	beqz	a5,80002ff4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fe4:	8526                	mv	a0,s1
    80002fe6:	70a2                	ld	ra,40(sp)
    80002fe8:	7402                	ld	s0,32(sp)
    80002fea:	64e2                	ld	s1,24(sp)
    80002fec:	6942                	ld	s2,16(sp)
    80002fee:	69a2                	ld	s3,8(sp)
    80002ff0:	6145                	addi	sp,sp,48
    80002ff2:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ff4:	4581                	li	a1,0
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	00003097          	auipc	ra,0x3
    80002ffc:	1ac080e7          	jalr	428(ra) # 800061a4 <virtio_disk_rw>
    b->valid = 1;
    80003000:	4785                	li	a5,1
    80003002:	c09c                	sw	a5,0(s1)
  return b;
    80003004:	b7c5                	j	80002fe4 <bread+0xd0>

0000000080003006 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	e426                	sd	s1,8(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003012:	0541                	addi	a0,a0,16
    80003014:	00001097          	auipc	ra,0x1
    80003018:	440080e7          	jalr	1088(ra) # 80004454 <holdingsleep>
    8000301c:	cd01                	beqz	a0,80003034 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000301e:	4585                	li	a1,1
    80003020:	8526                	mv	a0,s1
    80003022:	00003097          	auipc	ra,0x3
    80003026:	182080e7          	jalr	386(ra) # 800061a4 <virtio_disk_rw>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret
    panic("bwrite");
    80003034:	00006517          	auipc	a0,0x6
    80003038:	51450513          	addi	a0,a0,1300 # 80009548 <syscalls+0xd8>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	504080e7          	jalr	1284(ra) # 80000540 <panic>

0000000080003044 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	e04a                	sd	s2,0(sp)
    8000304e:	1000                	addi	s0,sp,32
    80003050:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003052:	01050913          	addi	s2,a0,16
    80003056:	854a                	mv	a0,s2
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	3fc080e7          	jalr	1020(ra) # 80004454 <holdingsleep>
    80003060:	c925                	beqz	a0,800030d0 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003062:	854a                	mv	a0,s2
    80003064:	00001097          	auipc	ra,0x1
    80003068:	3ac080e7          	jalr	940(ra) # 80004410 <releasesleep>

  acquire(&bcache.lock);
    8000306c:	00015517          	auipc	a0,0x15
    80003070:	ebc50513          	addi	a0,a0,-324 # 80017f28 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	bd4080e7          	jalr	-1068(ra) # 80000c48 <acquire>
  b->refcnt--;
    8000307c:	40bc                	lw	a5,64(s1)
    8000307e:	37fd                	addiw	a5,a5,-1
    80003080:	0007871b          	sext.w	a4,a5
    80003084:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003086:	e71d                	bnez	a4,800030b4 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003088:	68b8                	ld	a4,80(s1)
    8000308a:	64bc                	ld	a5,72(s1)
    8000308c:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000308e:	68b8                	ld	a4,80(s1)
    80003090:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003092:	0001d797          	auipc	a5,0x1d
    80003096:	e9678793          	addi	a5,a5,-362 # 8001ff28 <bcache+0x8000>
    8000309a:	2b87b703          	ld	a4,696(a5)
    8000309e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030a0:	0001d717          	auipc	a4,0x1d
    800030a4:	0f070713          	addi	a4,a4,240 # 80020190 <bcache+0x8268>
    800030a8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030aa:	2b87b703          	ld	a4,696(a5)
    800030ae:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030b0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030b4:	00015517          	auipc	a0,0x15
    800030b8:	e7450513          	addi	a0,a0,-396 # 80017f28 <bcache>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	c40080e7          	jalr	-960(ra) # 80000cfc <release>
}
    800030c4:	60e2                	ld	ra,24(sp)
    800030c6:	6442                	ld	s0,16(sp)
    800030c8:	64a2                	ld	s1,8(sp)
    800030ca:	6902                	ld	s2,0(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret
    panic("brelse");
    800030d0:	00006517          	auipc	a0,0x6
    800030d4:	48050513          	addi	a0,a0,1152 # 80009550 <syscalls+0xe0>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	468080e7          	jalr	1128(ra) # 80000540 <panic>

00000000800030e0 <bpin>:

void
bpin(struct buf *b) {
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	e426                	sd	s1,8(sp)
    800030e8:	1000                	addi	s0,sp,32
    800030ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ec:	00015517          	auipc	a0,0x15
    800030f0:	e3c50513          	addi	a0,a0,-452 # 80017f28 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	b54080e7          	jalr	-1196(ra) # 80000c48 <acquire>
  b->refcnt++;
    800030fc:	40bc                	lw	a5,64(s1)
    800030fe:	2785                	addiw	a5,a5,1
    80003100:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003102:	00015517          	auipc	a0,0x15
    80003106:	e2650513          	addi	a0,a0,-474 # 80017f28 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	bf2080e7          	jalr	-1038(ra) # 80000cfc <release>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	64a2                	ld	s1,8(sp)
    80003118:	6105                	addi	sp,sp,32
    8000311a:	8082                	ret

000000008000311c <bunpin>:

void
bunpin(struct buf *b) {
    8000311c:	1101                	addi	sp,sp,-32
    8000311e:	ec06                	sd	ra,24(sp)
    80003120:	e822                	sd	s0,16(sp)
    80003122:	e426                	sd	s1,8(sp)
    80003124:	1000                	addi	s0,sp,32
    80003126:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003128:	00015517          	auipc	a0,0x15
    8000312c:	e0050513          	addi	a0,a0,-512 # 80017f28 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b18080e7          	jalr	-1256(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003138:	40bc                	lw	a5,64(s1)
    8000313a:	37fd                	addiw	a5,a5,-1
    8000313c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000313e:	00015517          	auipc	a0,0x15
    80003142:	dea50513          	addi	a0,a0,-534 # 80017f28 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	bb6080e7          	jalr	-1098(ra) # 80000cfc <release>
}
    8000314e:	60e2                	ld	ra,24(sp)
    80003150:	6442                	ld	s0,16(sp)
    80003152:	64a2                	ld	s1,8(sp)
    80003154:	6105                	addi	sp,sp,32
    80003156:	8082                	ret

0000000080003158 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	e426                	sd	s1,8(sp)
    80003160:	e04a                	sd	s2,0(sp)
    80003162:	1000                	addi	s0,sp,32
    80003164:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003166:	00d5d59b          	srliw	a1,a1,0xd
    8000316a:	0001d797          	auipc	a5,0x1d
    8000316e:	49a7a783          	lw	a5,1178(a5) # 80020604 <sb+0x1c>
    80003172:	9dbd                	addw	a1,a1,a5
    80003174:	00000097          	auipc	ra,0x0
    80003178:	da0080e7          	jalr	-608(ra) # 80002f14 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000317c:	0074f713          	andi	a4,s1,7
    80003180:	4785                	li	a5,1
    80003182:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003186:	14ce                	slli	s1,s1,0x33
    80003188:	90d9                	srli	s1,s1,0x36
    8000318a:	00950733          	add	a4,a0,s1
    8000318e:	05874703          	lbu	a4,88(a4)
    80003192:	00e7f6b3          	and	a3,a5,a4
    80003196:	c69d                	beqz	a3,800031c4 <bfree+0x6c>
    80003198:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000319a:	94aa                	add	s1,s1,a0
    8000319c:	fff7c793          	not	a5,a5
    800031a0:	8f7d                	and	a4,a4,a5
    800031a2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031a6:	00001097          	auipc	ra,0x1
    800031aa:	0f6080e7          	jalr	246(ra) # 8000429c <log_write>
  brelse(bp);
    800031ae:	854a                	mv	a0,s2
    800031b0:	00000097          	auipc	ra,0x0
    800031b4:	e94080e7          	jalr	-364(ra) # 80003044 <brelse>
}
    800031b8:	60e2                	ld	ra,24(sp)
    800031ba:	6442                	ld	s0,16(sp)
    800031bc:	64a2                	ld	s1,8(sp)
    800031be:	6902                	ld	s2,0(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret
    panic("freeing free block");
    800031c4:	00006517          	auipc	a0,0x6
    800031c8:	39450513          	addi	a0,a0,916 # 80009558 <syscalls+0xe8>
    800031cc:	ffffd097          	auipc	ra,0xffffd
    800031d0:	374080e7          	jalr	884(ra) # 80000540 <panic>

00000000800031d4 <balloc>:
{
    800031d4:	711d                	addi	sp,sp,-96
    800031d6:	ec86                	sd	ra,88(sp)
    800031d8:	e8a2                	sd	s0,80(sp)
    800031da:	e4a6                	sd	s1,72(sp)
    800031dc:	e0ca                	sd	s2,64(sp)
    800031de:	fc4e                	sd	s3,56(sp)
    800031e0:	f852                	sd	s4,48(sp)
    800031e2:	f456                	sd	s5,40(sp)
    800031e4:	f05a                	sd	s6,32(sp)
    800031e6:	ec5e                	sd	s7,24(sp)
    800031e8:	e862                	sd	s8,16(sp)
    800031ea:	e466                	sd	s9,8(sp)
    800031ec:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031ee:	0001d797          	auipc	a5,0x1d
    800031f2:	3fe7a783          	lw	a5,1022(a5) # 800205ec <sb+0x4>
    800031f6:	cff5                	beqz	a5,800032f2 <balloc+0x11e>
    800031f8:	8baa                	mv	s7,a0
    800031fa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031fc:	0001db17          	auipc	s6,0x1d
    80003200:	3ecb0b13          	addi	s6,s6,1004 # 800205e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003204:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003206:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003208:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000320a:	6c89                	lui	s9,0x2
    8000320c:	a061                	j	80003294 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000320e:	97ca                	add	a5,a5,s2
    80003210:	8e55                	or	a2,a2,a3
    80003212:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003216:	854a                	mv	a0,s2
    80003218:	00001097          	auipc	ra,0x1
    8000321c:	084080e7          	jalr	132(ra) # 8000429c <log_write>
        brelse(bp);
    80003220:	854a                	mv	a0,s2
    80003222:	00000097          	auipc	ra,0x0
    80003226:	e22080e7          	jalr	-478(ra) # 80003044 <brelse>
  bp = bread(dev, bno);
    8000322a:	85a6                	mv	a1,s1
    8000322c:	855e                	mv	a0,s7
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	ce6080e7          	jalr	-794(ra) # 80002f14 <bread>
    80003236:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003238:	40000613          	li	a2,1024
    8000323c:	4581                	li	a1,0
    8000323e:	05850513          	addi	a0,a0,88
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	b02080e7          	jalr	-1278(ra) # 80000d44 <memset>
  log_write(bp);
    8000324a:	854a                	mv	a0,s2
    8000324c:	00001097          	auipc	ra,0x1
    80003250:	050080e7          	jalr	80(ra) # 8000429c <log_write>
  brelse(bp);
    80003254:	854a                	mv	a0,s2
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	dee080e7          	jalr	-530(ra) # 80003044 <brelse>
}
    8000325e:	8526                	mv	a0,s1
    80003260:	60e6                	ld	ra,88(sp)
    80003262:	6446                	ld	s0,80(sp)
    80003264:	64a6                	ld	s1,72(sp)
    80003266:	6906                	ld	s2,64(sp)
    80003268:	79e2                	ld	s3,56(sp)
    8000326a:	7a42                	ld	s4,48(sp)
    8000326c:	7aa2                	ld	s5,40(sp)
    8000326e:	7b02                	ld	s6,32(sp)
    80003270:	6be2                	ld	s7,24(sp)
    80003272:	6c42                	ld	s8,16(sp)
    80003274:	6ca2                	ld	s9,8(sp)
    80003276:	6125                	addi	sp,sp,96
    80003278:	8082                	ret
    brelse(bp);
    8000327a:	854a                	mv	a0,s2
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	dc8080e7          	jalr	-568(ra) # 80003044 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003284:	015c87bb          	addw	a5,s9,s5
    80003288:	00078a9b          	sext.w	s5,a5
    8000328c:	004b2703          	lw	a4,4(s6)
    80003290:	06eaf163          	bgeu	s5,a4,800032f2 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003294:	41fad79b          	sraiw	a5,s5,0x1f
    80003298:	0137d79b          	srliw	a5,a5,0x13
    8000329c:	015787bb          	addw	a5,a5,s5
    800032a0:	40d7d79b          	sraiw	a5,a5,0xd
    800032a4:	01cb2583          	lw	a1,28(s6)
    800032a8:	9dbd                	addw	a1,a1,a5
    800032aa:	855e                	mv	a0,s7
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	c68080e7          	jalr	-920(ra) # 80002f14 <bread>
    800032b4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b6:	004b2503          	lw	a0,4(s6)
    800032ba:	000a849b          	sext.w	s1,s5
    800032be:	8762                	mv	a4,s8
    800032c0:	faa4fde3          	bgeu	s1,a0,8000327a <balloc+0xa6>
      m = 1 << (bi % 8);
    800032c4:	00777693          	andi	a3,a4,7
    800032c8:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032cc:	41f7579b          	sraiw	a5,a4,0x1f
    800032d0:	01d7d79b          	srliw	a5,a5,0x1d
    800032d4:	9fb9                	addw	a5,a5,a4
    800032d6:	4037d79b          	sraiw	a5,a5,0x3
    800032da:	00f90633          	add	a2,s2,a5
    800032de:	05864603          	lbu	a2,88(a2)
    800032e2:	00c6f5b3          	and	a1,a3,a2
    800032e6:	d585                	beqz	a1,8000320e <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e8:	2705                	addiw	a4,a4,1
    800032ea:	2485                	addiw	s1,s1,1
    800032ec:	fd471ae3          	bne	a4,s4,800032c0 <balloc+0xec>
    800032f0:	b769                	j	8000327a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032f2:	00006517          	auipc	a0,0x6
    800032f6:	27e50513          	addi	a0,a0,638 # 80009570 <syscalls+0x100>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	290080e7          	jalr	656(ra) # 8000058a <printf>
  return 0;
    80003302:	4481                	li	s1,0
    80003304:	bfa9                	j	8000325e <balloc+0x8a>

0000000080003306 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003306:	7179                	addi	sp,sp,-48
    80003308:	f406                	sd	ra,40(sp)
    8000330a:	f022                	sd	s0,32(sp)
    8000330c:	ec26                	sd	s1,24(sp)
    8000330e:	e84a                	sd	s2,16(sp)
    80003310:	e44e                	sd	s3,8(sp)
    80003312:	e052                	sd	s4,0(sp)
    80003314:	1800                	addi	s0,sp,48
    80003316:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003318:	47ad                	li	a5,11
    8000331a:	02b7e863          	bltu	a5,a1,8000334a <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000331e:	02059793          	slli	a5,a1,0x20
    80003322:	01e7d593          	srli	a1,a5,0x1e
    80003326:	00b504b3          	add	s1,a0,a1
    8000332a:	0504a903          	lw	s2,80(s1)
    8000332e:	06091e63          	bnez	s2,800033aa <bmap+0xa4>
      addr = balloc(ip->dev);
    80003332:	4108                	lw	a0,0(a0)
    80003334:	00000097          	auipc	ra,0x0
    80003338:	ea0080e7          	jalr	-352(ra) # 800031d4 <balloc>
    8000333c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003340:	06090563          	beqz	s2,800033aa <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003344:	0524a823          	sw	s2,80(s1)
    80003348:	a08d                	j	800033aa <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000334a:	ff45849b          	addiw	s1,a1,-12
    8000334e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003352:	0ff00793          	li	a5,255
    80003356:	08e7e563          	bltu	a5,a4,800033e0 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000335a:	08052903          	lw	s2,128(a0)
    8000335e:	00091d63          	bnez	s2,80003378 <bmap+0x72>
      addr = balloc(ip->dev);
    80003362:	4108                	lw	a0,0(a0)
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e70080e7          	jalr	-400(ra) # 800031d4 <balloc>
    8000336c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003370:	02090d63          	beqz	s2,800033aa <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003374:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003378:	85ca                	mv	a1,s2
    8000337a:	0009a503          	lw	a0,0(s3)
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	b96080e7          	jalr	-1130(ra) # 80002f14 <bread>
    80003386:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003388:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000338c:	02049713          	slli	a4,s1,0x20
    80003390:	01e75593          	srli	a1,a4,0x1e
    80003394:	00b784b3          	add	s1,a5,a1
    80003398:	0004a903          	lw	s2,0(s1)
    8000339c:	02090063          	beqz	s2,800033bc <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033a0:	8552                	mv	a0,s4
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	ca2080e7          	jalr	-862(ra) # 80003044 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033aa:	854a                	mv	a0,s2
    800033ac:	70a2                	ld	ra,40(sp)
    800033ae:	7402                	ld	s0,32(sp)
    800033b0:	64e2                	ld	s1,24(sp)
    800033b2:	6942                	ld	s2,16(sp)
    800033b4:	69a2                	ld	s3,8(sp)
    800033b6:	6a02                	ld	s4,0(sp)
    800033b8:	6145                	addi	sp,sp,48
    800033ba:	8082                	ret
      addr = balloc(ip->dev);
    800033bc:	0009a503          	lw	a0,0(s3)
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	e14080e7          	jalr	-492(ra) # 800031d4 <balloc>
    800033c8:	0005091b          	sext.w	s2,a0
      if(addr){
    800033cc:	fc090ae3          	beqz	s2,800033a0 <bmap+0x9a>
        a[bn] = addr;
    800033d0:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033d4:	8552                	mv	a0,s4
    800033d6:	00001097          	auipc	ra,0x1
    800033da:	ec6080e7          	jalr	-314(ra) # 8000429c <log_write>
    800033de:	b7c9                	j	800033a0 <bmap+0x9a>
  panic("bmap: out of range");
    800033e0:	00006517          	auipc	a0,0x6
    800033e4:	1a850513          	addi	a0,a0,424 # 80009588 <syscalls+0x118>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	158080e7          	jalr	344(ra) # 80000540 <panic>

00000000800033f0 <iget>:
{
    800033f0:	7179                	addi	sp,sp,-48
    800033f2:	f406                	sd	ra,40(sp)
    800033f4:	f022                	sd	s0,32(sp)
    800033f6:	ec26                	sd	s1,24(sp)
    800033f8:	e84a                	sd	s2,16(sp)
    800033fa:	e44e                	sd	s3,8(sp)
    800033fc:	e052                	sd	s4,0(sp)
    800033fe:	1800                	addi	s0,sp,48
    80003400:	89aa                	mv	s3,a0
    80003402:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003404:	0001d517          	auipc	a0,0x1d
    80003408:	20450513          	addi	a0,a0,516 # 80020608 <itable>
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	83c080e7          	jalr	-1988(ra) # 80000c48 <acquire>
  empty = 0;
    80003414:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003416:	0001d497          	auipc	s1,0x1d
    8000341a:	20a48493          	addi	s1,s1,522 # 80020620 <itable+0x18>
    8000341e:	0001f697          	auipc	a3,0x1f
    80003422:	c9268693          	addi	a3,a3,-878 # 800220b0 <log>
    80003426:	a039                	j	80003434 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003428:	02090b63          	beqz	s2,8000345e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000342c:	08848493          	addi	s1,s1,136
    80003430:	02d48a63          	beq	s1,a3,80003464 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003434:	449c                	lw	a5,8(s1)
    80003436:	fef059e3          	blez	a5,80003428 <iget+0x38>
    8000343a:	4098                	lw	a4,0(s1)
    8000343c:	ff3716e3          	bne	a4,s3,80003428 <iget+0x38>
    80003440:	40d8                	lw	a4,4(s1)
    80003442:	ff4713e3          	bne	a4,s4,80003428 <iget+0x38>
      ip->ref++;
    80003446:	2785                	addiw	a5,a5,1
    80003448:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000344a:	0001d517          	auipc	a0,0x1d
    8000344e:	1be50513          	addi	a0,a0,446 # 80020608 <itable>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	8aa080e7          	jalr	-1878(ra) # 80000cfc <release>
      return ip;
    8000345a:	8926                	mv	s2,s1
    8000345c:	a03d                	j	8000348a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000345e:	f7f9                	bnez	a5,8000342c <iget+0x3c>
    80003460:	8926                	mv	s2,s1
    80003462:	b7e9                	j	8000342c <iget+0x3c>
  if(empty == 0)
    80003464:	02090c63          	beqz	s2,8000349c <iget+0xac>
  ip->dev = dev;
    80003468:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000346c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003470:	4785                	li	a5,1
    80003472:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003476:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000347a:	0001d517          	auipc	a0,0x1d
    8000347e:	18e50513          	addi	a0,a0,398 # 80020608 <itable>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	87a080e7          	jalr	-1926(ra) # 80000cfc <release>
}
    8000348a:	854a                	mv	a0,s2
    8000348c:	70a2                	ld	ra,40(sp)
    8000348e:	7402                	ld	s0,32(sp)
    80003490:	64e2                	ld	s1,24(sp)
    80003492:	6942                	ld	s2,16(sp)
    80003494:	69a2                	ld	s3,8(sp)
    80003496:	6a02                	ld	s4,0(sp)
    80003498:	6145                	addi	sp,sp,48
    8000349a:	8082                	ret
    panic("iget: no inodes");
    8000349c:	00006517          	auipc	a0,0x6
    800034a0:	10450513          	addi	a0,a0,260 # 800095a0 <syscalls+0x130>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	09c080e7          	jalr	156(ra) # 80000540 <panic>

00000000800034ac <fsinit>:
fsinit(int dev) {
    800034ac:	7179                	addi	sp,sp,-48
    800034ae:	f406                	sd	ra,40(sp)
    800034b0:	f022                	sd	s0,32(sp)
    800034b2:	ec26                	sd	s1,24(sp)
    800034b4:	e84a                	sd	s2,16(sp)
    800034b6:	e44e                	sd	s3,8(sp)
    800034b8:	1800                	addi	s0,sp,48
    800034ba:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034bc:	4585                	li	a1,1
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	a56080e7          	jalr	-1450(ra) # 80002f14 <bread>
    800034c6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034c8:	0001d997          	auipc	s3,0x1d
    800034cc:	12098993          	addi	s3,s3,288 # 800205e8 <sb>
    800034d0:	02000613          	li	a2,32
    800034d4:	05850593          	addi	a1,a0,88
    800034d8:	854e                	mv	a0,s3
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	8c6080e7          	jalr	-1850(ra) # 80000da0 <memmove>
  brelse(bp);
    800034e2:	8526                	mv	a0,s1
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	b60080e7          	jalr	-1184(ra) # 80003044 <brelse>
  if(sb.magic != FSMAGIC)
    800034ec:	0009a703          	lw	a4,0(s3)
    800034f0:	102037b7          	lui	a5,0x10203
    800034f4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034f8:	02f71263          	bne	a4,a5,8000351c <fsinit+0x70>
  initlog(dev, &sb);
    800034fc:	0001d597          	auipc	a1,0x1d
    80003500:	0ec58593          	addi	a1,a1,236 # 800205e8 <sb>
    80003504:	854a                	mv	a0,s2
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	b2c080e7          	jalr	-1236(ra) # 80004032 <initlog>
}
    8000350e:	70a2                	ld	ra,40(sp)
    80003510:	7402                	ld	s0,32(sp)
    80003512:	64e2                	ld	s1,24(sp)
    80003514:	6942                	ld	s2,16(sp)
    80003516:	69a2                	ld	s3,8(sp)
    80003518:	6145                	addi	sp,sp,48
    8000351a:	8082                	ret
    panic("invalid file system");
    8000351c:	00006517          	auipc	a0,0x6
    80003520:	09450513          	addi	a0,a0,148 # 800095b0 <syscalls+0x140>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	01c080e7          	jalr	28(ra) # 80000540 <panic>

000000008000352c <iinit>:
{
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000353a:	00006597          	auipc	a1,0x6
    8000353e:	08e58593          	addi	a1,a1,142 # 800095c8 <syscalls+0x158>
    80003542:	0001d517          	auipc	a0,0x1d
    80003546:	0c650513          	addi	a0,a0,198 # 80020608 <itable>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	66e080e7          	jalr	1646(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003552:	0001d497          	auipc	s1,0x1d
    80003556:	0de48493          	addi	s1,s1,222 # 80020630 <itable+0x28>
    8000355a:	0001f997          	auipc	s3,0x1f
    8000355e:	b6698993          	addi	s3,s3,-1178 # 800220c0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003562:	00006917          	auipc	s2,0x6
    80003566:	06e90913          	addi	s2,s2,110 # 800095d0 <syscalls+0x160>
    8000356a:	85ca                	mv	a1,s2
    8000356c:	8526                	mv	a0,s1
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	e12080e7          	jalr	-494(ra) # 80004380 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003576:	08848493          	addi	s1,s1,136
    8000357a:	ff3498e3          	bne	s1,s3,8000356a <iinit+0x3e>
}
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	69a2                	ld	s3,8(sp)
    80003588:	6145                	addi	sp,sp,48
    8000358a:	8082                	ret

000000008000358c <ialloc>:
{
    8000358c:	7139                	addi	sp,sp,-64
    8000358e:	fc06                	sd	ra,56(sp)
    80003590:	f822                	sd	s0,48(sp)
    80003592:	f426                	sd	s1,40(sp)
    80003594:	f04a                	sd	s2,32(sp)
    80003596:	ec4e                	sd	s3,24(sp)
    80003598:	e852                	sd	s4,16(sp)
    8000359a:	e456                	sd	s5,8(sp)
    8000359c:	e05a                	sd	s6,0(sp)
    8000359e:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a0:	0001d717          	auipc	a4,0x1d
    800035a4:	05472703          	lw	a4,84(a4) # 800205f4 <sb+0xc>
    800035a8:	4785                	li	a5,1
    800035aa:	04e7f863          	bgeu	a5,a4,800035fa <ialloc+0x6e>
    800035ae:	8aaa                	mv	s5,a0
    800035b0:	8b2e                	mv	s6,a1
    800035b2:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035b4:	0001da17          	auipc	s4,0x1d
    800035b8:	034a0a13          	addi	s4,s4,52 # 800205e8 <sb>
    800035bc:	00495593          	srli	a1,s2,0x4
    800035c0:	018a2783          	lw	a5,24(s4)
    800035c4:	9dbd                	addw	a1,a1,a5
    800035c6:	8556                	mv	a0,s5
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	94c080e7          	jalr	-1716(ra) # 80002f14 <bread>
    800035d0:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035d2:	05850993          	addi	s3,a0,88
    800035d6:	00f97793          	andi	a5,s2,15
    800035da:	079a                	slli	a5,a5,0x6
    800035dc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035de:	00099783          	lh	a5,0(s3)
    800035e2:	cf9d                	beqz	a5,80003620 <ialloc+0x94>
    brelse(bp);
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	a60080e7          	jalr	-1440(ra) # 80003044 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ec:	0905                	addi	s2,s2,1
    800035ee:	00ca2703          	lw	a4,12(s4)
    800035f2:	0009079b          	sext.w	a5,s2
    800035f6:	fce7e3e3          	bltu	a5,a4,800035bc <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800035fa:	00006517          	auipc	a0,0x6
    800035fe:	fde50513          	addi	a0,a0,-34 # 800095d8 <syscalls+0x168>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	f88080e7          	jalr	-120(ra) # 8000058a <printf>
  return 0;
    8000360a:	4501                	li	a0,0
}
    8000360c:	70e2                	ld	ra,56(sp)
    8000360e:	7442                	ld	s0,48(sp)
    80003610:	74a2                	ld	s1,40(sp)
    80003612:	7902                	ld	s2,32(sp)
    80003614:	69e2                	ld	s3,24(sp)
    80003616:	6a42                	ld	s4,16(sp)
    80003618:	6aa2                	ld	s5,8(sp)
    8000361a:	6b02                	ld	s6,0(sp)
    8000361c:	6121                	addi	sp,sp,64
    8000361e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003620:	04000613          	li	a2,64
    80003624:	4581                	li	a1,0
    80003626:	854e                	mv	a0,s3
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	71c080e7          	jalr	1820(ra) # 80000d44 <memset>
      dip->type = type;
    80003630:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003634:	8526                	mv	a0,s1
    80003636:	00001097          	auipc	ra,0x1
    8000363a:	c66080e7          	jalr	-922(ra) # 8000429c <log_write>
      brelse(bp);
    8000363e:	8526                	mv	a0,s1
    80003640:	00000097          	auipc	ra,0x0
    80003644:	a04080e7          	jalr	-1532(ra) # 80003044 <brelse>
      return iget(dev, inum);
    80003648:	0009059b          	sext.w	a1,s2
    8000364c:	8556                	mv	a0,s5
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	da2080e7          	jalr	-606(ra) # 800033f0 <iget>
    80003656:	bf5d                	j	8000360c <ialloc+0x80>

0000000080003658 <iupdate>:
{
    80003658:	1101                	addi	sp,sp,-32
    8000365a:	ec06                	sd	ra,24(sp)
    8000365c:	e822                	sd	s0,16(sp)
    8000365e:	e426                	sd	s1,8(sp)
    80003660:	e04a                	sd	s2,0(sp)
    80003662:	1000                	addi	s0,sp,32
    80003664:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003666:	415c                	lw	a5,4(a0)
    80003668:	0047d79b          	srliw	a5,a5,0x4
    8000366c:	0001d597          	auipc	a1,0x1d
    80003670:	f945a583          	lw	a1,-108(a1) # 80020600 <sb+0x18>
    80003674:	9dbd                	addw	a1,a1,a5
    80003676:	4108                	lw	a0,0(a0)
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	89c080e7          	jalr	-1892(ra) # 80002f14 <bread>
    80003680:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003682:	05850793          	addi	a5,a0,88
    80003686:	40d8                	lw	a4,4(s1)
    80003688:	8b3d                	andi	a4,a4,15
    8000368a:	071a                	slli	a4,a4,0x6
    8000368c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000368e:	04449703          	lh	a4,68(s1)
    80003692:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003696:	04649703          	lh	a4,70(s1)
    8000369a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000369e:	04849703          	lh	a4,72(s1)
    800036a2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036a6:	04a49703          	lh	a4,74(s1)
    800036aa:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036ae:	44f8                	lw	a4,76(s1)
    800036b0:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036b2:	03400613          	li	a2,52
    800036b6:	05048593          	addi	a1,s1,80
    800036ba:	00c78513          	addi	a0,a5,12
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	6e2080e7          	jalr	1762(ra) # 80000da0 <memmove>
  log_write(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	bd4080e7          	jalr	-1068(ra) # 8000429c <log_write>
  brelse(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	972080e7          	jalr	-1678(ra) # 80003044 <brelse>
}
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	64a2                	ld	s1,8(sp)
    800036e0:	6902                	ld	s2,0(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret

00000000800036e6 <idup>:
{
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	1000                	addi	s0,sp,32
    800036f0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036f2:	0001d517          	auipc	a0,0x1d
    800036f6:	f1650513          	addi	a0,a0,-234 # 80020608 <itable>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	54e080e7          	jalr	1358(ra) # 80000c48 <acquire>
  ip->ref++;
    80003702:	449c                	lw	a5,8(s1)
    80003704:	2785                	addiw	a5,a5,1
    80003706:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003708:	0001d517          	auipc	a0,0x1d
    8000370c:	f0050513          	addi	a0,a0,-256 # 80020608 <itable>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	5ec080e7          	jalr	1516(ra) # 80000cfc <release>
}
    80003718:	8526                	mv	a0,s1
    8000371a:	60e2                	ld	ra,24(sp)
    8000371c:	6442                	ld	s0,16(sp)
    8000371e:	64a2                	ld	s1,8(sp)
    80003720:	6105                	addi	sp,sp,32
    80003722:	8082                	ret

0000000080003724 <ilock>:
{
    80003724:	1101                	addi	sp,sp,-32
    80003726:	ec06                	sd	ra,24(sp)
    80003728:	e822                	sd	s0,16(sp)
    8000372a:	e426                	sd	s1,8(sp)
    8000372c:	e04a                	sd	s2,0(sp)
    8000372e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003730:	c115                	beqz	a0,80003754 <ilock+0x30>
    80003732:	84aa                	mv	s1,a0
    80003734:	451c                	lw	a5,8(a0)
    80003736:	00f05f63          	blez	a5,80003754 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000373a:	0541                	addi	a0,a0,16
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	c7e080e7          	jalr	-898(ra) # 800043ba <acquiresleep>
  if(ip->valid == 0){
    80003744:	40bc                	lw	a5,64(s1)
    80003746:	cf99                	beqz	a5,80003764 <ilock+0x40>
}
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6902                	ld	s2,0(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret
    panic("ilock");
    80003754:	00006517          	auipc	a0,0x6
    80003758:	e9c50513          	addi	a0,a0,-356 # 800095f0 <syscalls+0x180>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	de4080e7          	jalr	-540(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003764:	40dc                	lw	a5,4(s1)
    80003766:	0047d79b          	srliw	a5,a5,0x4
    8000376a:	0001d597          	auipc	a1,0x1d
    8000376e:	e965a583          	lw	a1,-362(a1) # 80020600 <sb+0x18>
    80003772:	9dbd                	addw	a1,a1,a5
    80003774:	4088                	lw	a0,0(s1)
    80003776:	fffff097          	auipc	ra,0xfffff
    8000377a:	79e080e7          	jalr	1950(ra) # 80002f14 <bread>
    8000377e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003780:	05850593          	addi	a1,a0,88
    80003784:	40dc                	lw	a5,4(s1)
    80003786:	8bbd                	andi	a5,a5,15
    80003788:	079a                	slli	a5,a5,0x6
    8000378a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000378c:	00059783          	lh	a5,0(a1)
    80003790:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003794:	00259783          	lh	a5,2(a1)
    80003798:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000379c:	00459783          	lh	a5,4(a1)
    800037a0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037a4:	00659783          	lh	a5,6(a1)
    800037a8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037ac:	459c                	lw	a5,8(a1)
    800037ae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037b0:	03400613          	li	a2,52
    800037b4:	05b1                	addi	a1,a1,12
    800037b6:	05048513          	addi	a0,s1,80
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	5e6080e7          	jalr	1510(ra) # 80000da0 <memmove>
    brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	880080e7          	jalr	-1920(ra) # 80003044 <brelse>
    ip->valid = 1;
    800037cc:	4785                	li	a5,1
    800037ce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037d0:	04449783          	lh	a5,68(s1)
    800037d4:	fbb5                	bnez	a5,80003748 <ilock+0x24>
      panic("ilock: no type");
    800037d6:	00006517          	auipc	a0,0x6
    800037da:	e2250513          	addi	a0,a0,-478 # 800095f8 <syscalls+0x188>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	d62080e7          	jalr	-670(ra) # 80000540 <panic>

00000000800037e6 <iunlock>:
{
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	e04a                	sd	s2,0(sp)
    800037f0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037f2:	c905                	beqz	a0,80003822 <iunlock+0x3c>
    800037f4:	84aa                	mv	s1,a0
    800037f6:	01050913          	addi	s2,a0,16
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	c58080e7          	jalr	-936(ra) # 80004454 <holdingsleep>
    80003804:	cd19                	beqz	a0,80003822 <iunlock+0x3c>
    80003806:	449c                	lw	a5,8(s1)
    80003808:	00f05d63          	blez	a5,80003822 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	c02080e7          	jalr	-1022(ra) # 80004410 <releasesleep>
}
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	64a2                	ld	s1,8(sp)
    8000381c:	6902                	ld	s2,0(sp)
    8000381e:	6105                	addi	sp,sp,32
    80003820:	8082                	ret
    panic("iunlock");
    80003822:	00006517          	auipc	a0,0x6
    80003826:	de650513          	addi	a0,a0,-538 # 80009608 <syscalls+0x198>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>

0000000080003832 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003832:	7179                	addi	sp,sp,-48
    80003834:	f406                	sd	ra,40(sp)
    80003836:	f022                	sd	s0,32(sp)
    80003838:	ec26                	sd	s1,24(sp)
    8000383a:	e84a                	sd	s2,16(sp)
    8000383c:	e44e                	sd	s3,8(sp)
    8000383e:	e052                	sd	s4,0(sp)
    80003840:	1800                	addi	s0,sp,48
    80003842:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003844:	05050493          	addi	s1,a0,80
    80003848:	08050913          	addi	s2,a0,128
    8000384c:	a021                	j	80003854 <itrunc+0x22>
    8000384e:	0491                	addi	s1,s1,4
    80003850:	01248d63          	beq	s1,s2,8000386a <itrunc+0x38>
    if(ip->addrs[i]){
    80003854:	408c                	lw	a1,0(s1)
    80003856:	dde5                	beqz	a1,8000384e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003858:	0009a503          	lw	a0,0(s3)
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	8fc080e7          	jalr	-1796(ra) # 80003158 <bfree>
      ip->addrs[i] = 0;
    80003864:	0004a023          	sw	zero,0(s1)
    80003868:	b7dd                	j	8000384e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000386a:	0809a583          	lw	a1,128(s3)
    8000386e:	e185                	bnez	a1,8000388e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003870:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003874:	854e                	mv	a0,s3
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	de2080e7          	jalr	-542(ra) # 80003658 <iupdate>
}
    8000387e:	70a2                	ld	ra,40(sp)
    80003880:	7402                	ld	s0,32(sp)
    80003882:	64e2                	ld	s1,24(sp)
    80003884:	6942                	ld	s2,16(sp)
    80003886:	69a2                	ld	s3,8(sp)
    80003888:	6a02                	ld	s4,0(sp)
    8000388a:	6145                	addi	sp,sp,48
    8000388c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000388e:	0009a503          	lw	a0,0(s3)
    80003892:	fffff097          	auipc	ra,0xfffff
    80003896:	682080e7          	jalr	1666(ra) # 80002f14 <bread>
    8000389a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000389c:	05850493          	addi	s1,a0,88
    800038a0:	45850913          	addi	s2,a0,1112
    800038a4:	a021                	j	800038ac <itrunc+0x7a>
    800038a6:	0491                	addi	s1,s1,4
    800038a8:	01248b63          	beq	s1,s2,800038be <itrunc+0x8c>
      if(a[j])
    800038ac:	408c                	lw	a1,0(s1)
    800038ae:	dde5                	beqz	a1,800038a6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038b0:	0009a503          	lw	a0,0(s3)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	8a4080e7          	jalr	-1884(ra) # 80003158 <bfree>
    800038bc:	b7ed                	j	800038a6 <itrunc+0x74>
    brelse(bp);
    800038be:	8552                	mv	a0,s4
    800038c0:	fffff097          	auipc	ra,0xfffff
    800038c4:	784080e7          	jalr	1924(ra) # 80003044 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038c8:	0809a583          	lw	a1,128(s3)
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	888080e7          	jalr	-1912(ra) # 80003158 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038d8:	0809a023          	sw	zero,128(s3)
    800038dc:	bf51                	j	80003870 <itrunc+0x3e>

00000000800038de <iput>:
{
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	e04a                	sd	s2,0(sp)
    800038e8:	1000                	addi	s0,sp,32
    800038ea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ec:	0001d517          	auipc	a0,0x1d
    800038f0:	d1c50513          	addi	a0,a0,-740 # 80020608 <itable>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	354080e7          	jalr	852(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fc:	4498                	lw	a4,8(s1)
    800038fe:	4785                	li	a5,1
    80003900:	02f70363          	beq	a4,a5,80003926 <iput+0x48>
  ip->ref--;
    80003904:	449c                	lw	a5,8(s1)
    80003906:	37fd                	addiw	a5,a5,-1
    80003908:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000390a:	0001d517          	auipc	a0,0x1d
    8000390e:	cfe50513          	addi	a0,a0,-770 # 80020608 <itable>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	3ea080e7          	jalr	1002(ra) # 80000cfc <release>
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6902                	ld	s2,0(sp)
    80003922:	6105                	addi	sp,sp,32
    80003924:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003926:	40bc                	lw	a5,64(s1)
    80003928:	dff1                	beqz	a5,80003904 <iput+0x26>
    8000392a:	04a49783          	lh	a5,74(s1)
    8000392e:	fbf9                	bnez	a5,80003904 <iput+0x26>
    acquiresleep(&ip->lock);
    80003930:	01048913          	addi	s2,s1,16
    80003934:	854a                	mv	a0,s2
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	a84080e7          	jalr	-1404(ra) # 800043ba <acquiresleep>
    release(&itable.lock);
    8000393e:	0001d517          	auipc	a0,0x1d
    80003942:	cca50513          	addi	a0,a0,-822 # 80020608 <itable>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	3b6080e7          	jalr	950(ra) # 80000cfc <release>
    itrunc(ip);
    8000394e:	8526                	mv	a0,s1
    80003950:	00000097          	auipc	ra,0x0
    80003954:	ee2080e7          	jalr	-286(ra) # 80003832 <itrunc>
    ip->type = 0;
    80003958:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000395c:	8526                	mv	a0,s1
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	cfa080e7          	jalr	-774(ra) # 80003658 <iupdate>
    ip->valid = 0;
    80003966:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000396a:	854a                	mv	a0,s2
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	aa4080e7          	jalr	-1372(ra) # 80004410 <releasesleep>
    acquire(&itable.lock);
    80003974:	0001d517          	auipc	a0,0x1d
    80003978:	c9450513          	addi	a0,a0,-876 # 80020608 <itable>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	2cc080e7          	jalr	716(ra) # 80000c48 <acquire>
    80003984:	b741                	j	80003904 <iput+0x26>

0000000080003986 <iunlockput>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	1000                	addi	s0,sp,32
    80003990:	84aa                	mv	s1,a0
  iunlock(ip);
    80003992:	00000097          	auipc	ra,0x0
    80003996:	e54080e7          	jalr	-428(ra) # 800037e6 <iunlock>
  iput(ip);
    8000399a:	8526                	mv	a0,s1
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	f42080e7          	jalr	-190(ra) # 800038de <iput>
}
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret

00000000800039ae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039ae:	1141                	addi	sp,sp,-16
    800039b0:	e422                	sd	s0,8(sp)
    800039b2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039b4:	411c                	lw	a5,0(a0)
    800039b6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039b8:	415c                	lw	a5,4(a0)
    800039ba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039bc:	04451783          	lh	a5,68(a0)
    800039c0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039c4:	04a51783          	lh	a5,74(a0)
    800039c8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039cc:	04c56783          	lwu	a5,76(a0)
    800039d0:	e99c                	sd	a5,16(a1)
}
    800039d2:	6422                	ld	s0,8(sp)
    800039d4:	0141                	addi	sp,sp,16
    800039d6:	8082                	ret

00000000800039d8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039d8:	457c                	lw	a5,76(a0)
    800039da:	0ed7e963          	bltu	a5,a3,80003acc <readi+0xf4>
{
    800039de:	7159                	addi	sp,sp,-112
    800039e0:	f486                	sd	ra,104(sp)
    800039e2:	f0a2                	sd	s0,96(sp)
    800039e4:	eca6                	sd	s1,88(sp)
    800039e6:	e8ca                	sd	s2,80(sp)
    800039e8:	e4ce                	sd	s3,72(sp)
    800039ea:	e0d2                	sd	s4,64(sp)
    800039ec:	fc56                	sd	s5,56(sp)
    800039ee:	f85a                	sd	s6,48(sp)
    800039f0:	f45e                	sd	s7,40(sp)
    800039f2:	f062                	sd	s8,32(sp)
    800039f4:	ec66                	sd	s9,24(sp)
    800039f6:	e86a                	sd	s10,16(sp)
    800039f8:	e46e                	sd	s11,8(sp)
    800039fa:	1880                	addi	s0,sp,112
    800039fc:	8b2a                	mv	s6,a0
    800039fe:	8bae                	mv	s7,a1
    80003a00:	8a32                	mv	s4,a2
    80003a02:	84b6                	mv	s1,a3
    80003a04:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a06:	9f35                	addw	a4,a4,a3
    return 0;
    80003a08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a0a:	0ad76063          	bltu	a4,a3,80003aaa <readi+0xd2>
  if(off + n > ip->size)
    80003a0e:	00e7f463          	bgeu	a5,a4,80003a16 <readi+0x3e>
    n = ip->size - off;
    80003a12:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a16:	0a0a8963          	beqz	s5,80003ac8 <readi+0xf0>
    80003a1a:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a20:	5c7d                	li	s8,-1
    80003a22:	a82d                	j	80003a5c <readi+0x84>
    80003a24:	020d1d93          	slli	s11,s10,0x20
    80003a28:	020ddd93          	srli	s11,s11,0x20
    80003a2c:	05890613          	addi	a2,s2,88
    80003a30:	86ee                	mv	a3,s11
    80003a32:	963a                	add	a2,a2,a4
    80003a34:	85d2                	mv	a1,s4
    80003a36:	855e                	mv	a0,s7
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	aca080e7          	jalr	-1334(ra) # 80002502 <either_copyout>
    80003a40:	05850d63          	beq	a0,s8,80003a9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a44:	854a                	mv	a0,s2
    80003a46:	fffff097          	auipc	ra,0xfffff
    80003a4a:	5fe080e7          	jalr	1534(ra) # 80003044 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	013d09bb          	addw	s3,s10,s3
    80003a52:	009d04bb          	addw	s1,s10,s1
    80003a56:	9a6e                	add	s4,s4,s11
    80003a58:	0559f763          	bgeu	s3,s5,80003aa6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a5c:	00a4d59b          	srliw	a1,s1,0xa
    80003a60:	855a                	mv	a0,s6
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	8a4080e7          	jalr	-1884(ra) # 80003306 <bmap>
    80003a6a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a6e:	cd85                	beqz	a1,80003aa6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a70:	000b2503          	lw	a0,0(s6)
    80003a74:	fffff097          	auipc	ra,0xfffff
    80003a78:	4a0080e7          	jalr	1184(ra) # 80002f14 <bread>
    80003a7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7e:	3ff4f713          	andi	a4,s1,1023
    80003a82:	40ec87bb          	subw	a5,s9,a4
    80003a86:	413a86bb          	subw	a3,s5,s3
    80003a8a:	8d3e                	mv	s10,a5
    80003a8c:	2781                	sext.w	a5,a5
    80003a8e:	0006861b          	sext.w	a2,a3
    80003a92:	f8f679e3          	bgeu	a2,a5,80003a24 <readi+0x4c>
    80003a96:	8d36                	mv	s10,a3
    80003a98:	b771                	j	80003a24 <readi+0x4c>
      brelse(bp);
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	5a8080e7          	jalr	1448(ra) # 80003044 <brelse>
      tot = -1;
    80003aa4:	59fd                	li	s3,-1
  }
  return tot;
    80003aa6:	0009851b          	sext.w	a0,s3
}
    80003aaa:	70a6                	ld	ra,104(sp)
    80003aac:	7406                	ld	s0,96(sp)
    80003aae:	64e6                	ld	s1,88(sp)
    80003ab0:	6946                	ld	s2,80(sp)
    80003ab2:	69a6                	ld	s3,72(sp)
    80003ab4:	6a06                	ld	s4,64(sp)
    80003ab6:	7ae2                	ld	s5,56(sp)
    80003ab8:	7b42                	ld	s6,48(sp)
    80003aba:	7ba2                	ld	s7,40(sp)
    80003abc:	7c02                	ld	s8,32(sp)
    80003abe:	6ce2                	ld	s9,24(sp)
    80003ac0:	6d42                	ld	s10,16(sp)
    80003ac2:	6da2                	ld	s11,8(sp)
    80003ac4:	6165                	addi	sp,sp,112
    80003ac6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac8:	89d6                	mv	s3,s5
    80003aca:	bff1                	j	80003aa6 <readi+0xce>
    return 0;
    80003acc:	4501                	li	a0,0
}
    80003ace:	8082                	ret

0000000080003ad0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad0:	457c                	lw	a5,76(a0)
    80003ad2:	10d7e863          	bltu	a5,a3,80003be2 <writei+0x112>
{
    80003ad6:	7159                	addi	sp,sp,-112
    80003ad8:	f486                	sd	ra,104(sp)
    80003ada:	f0a2                	sd	s0,96(sp)
    80003adc:	eca6                	sd	s1,88(sp)
    80003ade:	e8ca                	sd	s2,80(sp)
    80003ae0:	e4ce                	sd	s3,72(sp)
    80003ae2:	e0d2                	sd	s4,64(sp)
    80003ae4:	fc56                	sd	s5,56(sp)
    80003ae6:	f85a                	sd	s6,48(sp)
    80003ae8:	f45e                	sd	s7,40(sp)
    80003aea:	f062                	sd	s8,32(sp)
    80003aec:	ec66                	sd	s9,24(sp)
    80003aee:	e86a                	sd	s10,16(sp)
    80003af0:	e46e                	sd	s11,8(sp)
    80003af2:	1880                	addi	s0,sp,112
    80003af4:	8aaa                	mv	s5,a0
    80003af6:	8bae                	mv	s7,a1
    80003af8:	8a32                	mv	s4,a2
    80003afa:	8936                	mv	s2,a3
    80003afc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003afe:	00e687bb          	addw	a5,a3,a4
    80003b02:	0ed7e263          	bltu	a5,a3,80003be6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b06:	00043737          	lui	a4,0x43
    80003b0a:	0ef76063          	bltu	a4,a5,80003bea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b0e:	0c0b0863          	beqz	s6,80003bde <writei+0x10e>
    80003b12:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b14:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b18:	5c7d                	li	s8,-1
    80003b1a:	a091                	j	80003b5e <writei+0x8e>
    80003b1c:	020d1d93          	slli	s11,s10,0x20
    80003b20:	020ddd93          	srli	s11,s11,0x20
    80003b24:	05848513          	addi	a0,s1,88
    80003b28:	86ee                	mv	a3,s11
    80003b2a:	8652                	mv	a2,s4
    80003b2c:	85de                	mv	a1,s7
    80003b2e:	953a                	add	a0,a0,a4
    80003b30:	fffff097          	auipc	ra,0xfffff
    80003b34:	a28080e7          	jalr	-1496(ra) # 80002558 <either_copyin>
    80003b38:	07850263          	beq	a0,s8,80003b9c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b3c:	8526                	mv	a0,s1
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	75e080e7          	jalr	1886(ra) # 8000429c <log_write>
    brelse(bp);
    80003b46:	8526                	mv	a0,s1
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	4fc080e7          	jalr	1276(ra) # 80003044 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b50:	013d09bb          	addw	s3,s10,s3
    80003b54:	012d093b          	addw	s2,s10,s2
    80003b58:	9a6e                	add	s4,s4,s11
    80003b5a:	0569f663          	bgeu	s3,s6,80003ba6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b5e:	00a9559b          	srliw	a1,s2,0xa
    80003b62:	8556                	mv	a0,s5
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	7a2080e7          	jalr	1954(ra) # 80003306 <bmap>
    80003b6c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b70:	c99d                	beqz	a1,80003ba6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b72:	000aa503          	lw	a0,0(s5)
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	39e080e7          	jalr	926(ra) # 80002f14 <bread>
    80003b7e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b80:	3ff97713          	andi	a4,s2,1023
    80003b84:	40ec87bb          	subw	a5,s9,a4
    80003b88:	413b06bb          	subw	a3,s6,s3
    80003b8c:	8d3e                	mv	s10,a5
    80003b8e:	2781                	sext.w	a5,a5
    80003b90:	0006861b          	sext.w	a2,a3
    80003b94:	f8f674e3          	bgeu	a2,a5,80003b1c <writei+0x4c>
    80003b98:	8d36                	mv	s10,a3
    80003b9a:	b749                	j	80003b1c <writei+0x4c>
      brelse(bp);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	4a6080e7          	jalr	1190(ra) # 80003044 <brelse>
  }

  if(off > ip->size)
    80003ba6:	04caa783          	lw	a5,76(s5)
    80003baa:	0127f463          	bgeu	a5,s2,80003bb2 <writei+0xe2>
    ip->size = off;
    80003bae:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bb2:	8556                	mv	a0,s5
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	aa4080e7          	jalr	-1372(ra) # 80003658 <iupdate>

  return tot;
    80003bbc:	0009851b          	sext.w	a0,s3
}
    80003bc0:	70a6                	ld	ra,104(sp)
    80003bc2:	7406                	ld	s0,96(sp)
    80003bc4:	64e6                	ld	s1,88(sp)
    80003bc6:	6946                	ld	s2,80(sp)
    80003bc8:	69a6                	ld	s3,72(sp)
    80003bca:	6a06                	ld	s4,64(sp)
    80003bcc:	7ae2                	ld	s5,56(sp)
    80003bce:	7b42                	ld	s6,48(sp)
    80003bd0:	7ba2                	ld	s7,40(sp)
    80003bd2:	7c02                	ld	s8,32(sp)
    80003bd4:	6ce2                	ld	s9,24(sp)
    80003bd6:	6d42                	ld	s10,16(sp)
    80003bd8:	6da2                	ld	s11,8(sp)
    80003bda:	6165                	addi	sp,sp,112
    80003bdc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bde:	89da                	mv	s3,s6
    80003be0:	bfc9                	j	80003bb2 <writei+0xe2>
    return -1;
    80003be2:	557d                	li	a0,-1
}
    80003be4:	8082                	ret
    return -1;
    80003be6:	557d                	li	a0,-1
    80003be8:	bfe1                	j	80003bc0 <writei+0xf0>
    return -1;
    80003bea:	557d                	li	a0,-1
    80003bec:	bfd1                	j	80003bc0 <writei+0xf0>

0000000080003bee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bee:	1141                	addi	sp,sp,-16
    80003bf0:	e406                	sd	ra,8(sp)
    80003bf2:	e022                	sd	s0,0(sp)
    80003bf4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bf6:	4639                	li	a2,14
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	21c080e7          	jalr	540(ra) # 80000e14 <strncmp>
}
    80003c00:	60a2                	ld	ra,8(sp)
    80003c02:	6402                	ld	s0,0(sp)
    80003c04:	0141                	addi	sp,sp,16
    80003c06:	8082                	ret

0000000080003c08 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c08:	7139                	addi	sp,sp,-64
    80003c0a:	fc06                	sd	ra,56(sp)
    80003c0c:	f822                	sd	s0,48(sp)
    80003c0e:	f426                	sd	s1,40(sp)
    80003c10:	f04a                	sd	s2,32(sp)
    80003c12:	ec4e                	sd	s3,24(sp)
    80003c14:	e852                	sd	s4,16(sp)
    80003c16:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c18:	04451703          	lh	a4,68(a0)
    80003c1c:	4785                	li	a5,1
    80003c1e:	00f71a63          	bne	a4,a5,80003c32 <dirlookup+0x2a>
    80003c22:	892a                	mv	s2,a0
    80003c24:	89ae                	mv	s3,a1
    80003c26:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c28:	457c                	lw	a5,76(a0)
    80003c2a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c2c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2e:	e79d                	bnez	a5,80003c5c <dirlookup+0x54>
    80003c30:	a8a5                	j	80003ca8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c32:	00006517          	auipc	a0,0x6
    80003c36:	9de50513          	addi	a0,a0,-1570 # 80009610 <syscalls+0x1a0>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	906080e7          	jalr	-1786(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c42:	00006517          	auipc	a0,0x6
    80003c46:	9e650513          	addi	a0,a0,-1562 # 80009628 <syscalls+0x1b8>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8f6080e7          	jalr	-1802(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c52:	24c1                	addiw	s1,s1,16
    80003c54:	04c92783          	lw	a5,76(s2)
    80003c58:	04f4f763          	bgeu	s1,a5,80003ca6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c5c:	4741                	li	a4,16
    80003c5e:	86a6                	mv	a3,s1
    80003c60:	fc040613          	addi	a2,s0,-64
    80003c64:	4581                	li	a1,0
    80003c66:	854a                	mv	a0,s2
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	d70080e7          	jalr	-656(ra) # 800039d8 <readi>
    80003c70:	47c1                	li	a5,16
    80003c72:	fcf518e3          	bne	a0,a5,80003c42 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c76:	fc045783          	lhu	a5,-64(s0)
    80003c7a:	dfe1                	beqz	a5,80003c52 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c7c:	fc240593          	addi	a1,s0,-62
    80003c80:	854e                	mv	a0,s3
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	f6c080e7          	jalr	-148(ra) # 80003bee <namecmp>
    80003c8a:	f561                	bnez	a0,80003c52 <dirlookup+0x4a>
      if(poff)
    80003c8c:	000a0463          	beqz	s4,80003c94 <dirlookup+0x8c>
        *poff = off;
    80003c90:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c94:	fc045583          	lhu	a1,-64(s0)
    80003c98:	00092503          	lw	a0,0(s2)
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	754080e7          	jalr	1876(ra) # 800033f0 <iget>
    80003ca4:	a011                	j	80003ca8 <dirlookup+0xa0>
  return 0;
    80003ca6:	4501                	li	a0,0
}
    80003ca8:	70e2                	ld	ra,56(sp)
    80003caa:	7442                	ld	s0,48(sp)
    80003cac:	74a2                	ld	s1,40(sp)
    80003cae:	7902                	ld	s2,32(sp)
    80003cb0:	69e2                	ld	s3,24(sp)
    80003cb2:	6a42                	ld	s4,16(sp)
    80003cb4:	6121                	addi	sp,sp,64
    80003cb6:	8082                	ret

0000000080003cb8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cb8:	711d                	addi	sp,sp,-96
    80003cba:	ec86                	sd	ra,88(sp)
    80003cbc:	e8a2                	sd	s0,80(sp)
    80003cbe:	e4a6                	sd	s1,72(sp)
    80003cc0:	e0ca                	sd	s2,64(sp)
    80003cc2:	fc4e                	sd	s3,56(sp)
    80003cc4:	f852                	sd	s4,48(sp)
    80003cc6:	f456                	sd	s5,40(sp)
    80003cc8:	f05a                	sd	s6,32(sp)
    80003cca:	ec5e                	sd	s7,24(sp)
    80003ccc:	e862                	sd	s8,16(sp)
    80003cce:	e466                	sd	s9,8(sp)
    80003cd0:	1080                	addi	s0,sp,96
    80003cd2:	84aa                	mv	s1,a0
    80003cd4:	8b2e                	mv	s6,a1
    80003cd6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cd8:	00054703          	lbu	a4,0(a0)
    80003cdc:	02f00793          	li	a5,47
    80003ce0:	02f70263          	beq	a4,a5,80003d04 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ce4:	ffffe097          	auipc	ra,0xffffe
    80003ce8:	d40080e7          	jalr	-704(ra) # 80001a24 <myproc>
    80003cec:	15053503          	ld	a0,336(a0)
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	9f6080e7          	jalr	-1546(ra) # 800036e6 <idup>
    80003cf8:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cfa:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cfe:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d00:	4b85                	li	s7,1
    80003d02:	a875                	j	80003dbe <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d04:	4585                	li	a1,1
    80003d06:	4505                	li	a0,1
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	6e8080e7          	jalr	1768(ra) # 800033f0 <iget>
    80003d10:	8a2a                	mv	s4,a0
    80003d12:	b7e5                	j	80003cfa <namex+0x42>
      iunlockput(ip);
    80003d14:	8552                	mv	a0,s4
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	c70080e7          	jalr	-912(ra) # 80003986 <iunlockput>
      return 0;
    80003d1e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d20:	8552                	mv	a0,s4
    80003d22:	60e6                	ld	ra,88(sp)
    80003d24:	6446                	ld	s0,80(sp)
    80003d26:	64a6                	ld	s1,72(sp)
    80003d28:	6906                	ld	s2,64(sp)
    80003d2a:	79e2                	ld	s3,56(sp)
    80003d2c:	7a42                	ld	s4,48(sp)
    80003d2e:	7aa2                	ld	s5,40(sp)
    80003d30:	7b02                	ld	s6,32(sp)
    80003d32:	6be2                	ld	s7,24(sp)
    80003d34:	6c42                	ld	s8,16(sp)
    80003d36:	6ca2                	ld	s9,8(sp)
    80003d38:	6125                	addi	sp,sp,96
    80003d3a:	8082                	ret
      iunlock(ip);
    80003d3c:	8552                	mv	a0,s4
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	aa8080e7          	jalr	-1368(ra) # 800037e6 <iunlock>
      return ip;
    80003d46:	bfe9                	j	80003d20 <namex+0x68>
      iunlockput(ip);
    80003d48:	8552                	mv	a0,s4
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	c3c080e7          	jalr	-964(ra) # 80003986 <iunlockput>
      return 0;
    80003d52:	8a4e                	mv	s4,s3
    80003d54:	b7f1                	j	80003d20 <namex+0x68>
  len = path - s;
    80003d56:	40998633          	sub	a2,s3,s1
    80003d5a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d5e:	099c5863          	bge	s8,s9,80003dee <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d62:	4639                	li	a2,14
    80003d64:	85a6                	mv	a1,s1
    80003d66:	8556                	mv	a0,s5
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	038080e7          	jalr	56(ra) # 80000da0 <memmove>
    80003d70:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d72:	0004c783          	lbu	a5,0(s1)
    80003d76:	01279763          	bne	a5,s2,80003d84 <namex+0xcc>
    path++;
    80003d7a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d7c:	0004c783          	lbu	a5,0(s1)
    80003d80:	ff278de3          	beq	a5,s2,80003d7a <namex+0xc2>
    ilock(ip);
    80003d84:	8552                	mv	a0,s4
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	99e080e7          	jalr	-1634(ra) # 80003724 <ilock>
    if(ip->type != T_DIR){
    80003d8e:	044a1783          	lh	a5,68(s4)
    80003d92:	f97791e3          	bne	a5,s7,80003d14 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003d96:	000b0563          	beqz	s6,80003da0 <namex+0xe8>
    80003d9a:	0004c783          	lbu	a5,0(s1)
    80003d9e:	dfd9                	beqz	a5,80003d3c <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003da0:	4601                	li	a2,0
    80003da2:	85d6                	mv	a1,s5
    80003da4:	8552                	mv	a0,s4
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	e62080e7          	jalr	-414(ra) # 80003c08 <dirlookup>
    80003dae:	89aa                	mv	s3,a0
    80003db0:	dd41                	beqz	a0,80003d48 <namex+0x90>
    iunlockput(ip);
    80003db2:	8552                	mv	a0,s4
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	bd2080e7          	jalr	-1070(ra) # 80003986 <iunlockput>
    ip = next;
    80003dbc:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dbe:	0004c783          	lbu	a5,0(s1)
    80003dc2:	01279763          	bne	a5,s2,80003dd0 <namex+0x118>
    path++;
    80003dc6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc8:	0004c783          	lbu	a5,0(s1)
    80003dcc:	ff278de3          	beq	a5,s2,80003dc6 <namex+0x10e>
  if(*path == 0)
    80003dd0:	cb9d                	beqz	a5,80003e06 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	89a6                	mv	s3,s1
  len = path - s;
    80003dd8:	4c81                	li	s9,0
    80003dda:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003ddc:	01278963          	beq	a5,s2,80003dee <namex+0x136>
    80003de0:	dbbd                	beqz	a5,80003d56 <namex+0x9e>
    path++;
    80003de2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003de4:	0009c783          	lbu	a5,0(s3)
    80003de8:	ff279ce3          	bne	a5,s2,80003de0 <namex+0x128>
    80003dec:	b7ad                	j	80003d56 <namex+0x9e>
    memmove(name, s, len);
    80003dee:	2601                	sext.w	a2,a2
    80003df0:	85a6                	mv	a1,s1
    80003df2:	8556                	mv	a0,s5
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	fac080e7          	jalr	-84(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003dfc:	9cd6                	add	s9,s9,s5
    80003dfe:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e02:	84ce                	mv	s1,s3
    80003e04:	b7bd                	j	80003d72 <namex+0xba>
  if(nameiparent){
    80003e06:	f00b0de3          	beqz	s6,80003d20 <namex+0x68>
    iput(ip);
    80003e0a:	8552                	mv	a0,s4
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	ad2080e7          	jalr	-1326(ra) # 800038de <iput>
    return 0;
    80003e14:	4a01                	li	s4,0
    80003e16:	b729                	j	80003d20 <namex+0x68>

0000000080003e18 <dirlink>:
{
    80003e18:	7139                	addi	sp,sp,-64
    80003e1a:	fc06                	sd	ra,56(sp)
    80003e1c:	f822                	sd	s0,48(sp)
    80003e1e:	f426                	sd	s1,40(sp)
    80003e20:	f04a                	sd	s2,32(sp)
    80003e22:	ec4e                	sd	s3,24(sp)
    80003e24:	e852                	sd	s4,16(sp)
    80003e26:	0080                	addi	s0,sp,64
    80003e28:	892a                	mv	s2,a0
    80003e2a:	8a2e                	mv	s4,a1
    80003e2c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e2e:	4601                	li	a2,0
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	dd8080e7          	jalr	-552(ra) # 80003c08 <dirlookup>
    80003e38:	e93d                	bnez	a0,80003eae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3a:	04c92483          	lw	s1,76(s2)
    80003e3e:	c49d                	beqz	s1,80003e6c <dirlink+0x54>
    80003e40:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e42:	4741                	li	a4,16
    80003e44:	86a6                	mv	a3,s1
    80003e46:	fc040613          	addi	a2,s0,-64
    80003e4a:	4581                	li	a1,0
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	b8a080e7          	jalr	-1142(ra) # 800039d8 <readi>
    80003e56:	47c1                	li	a5,16
    80003e58:	06f51163          	bne	a0,a5,80003eba <dirlink+0xa2>
    if(de.inum == 0)
    80003e5c:	fc045783          	lhu	a5,-64(s0)
    80003e60:	c791                	beqz	a5,80003e6c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e62:	24c1                	addiw	s1,s1,16
    80003e64:	04c92783          	lw	a5,76(s2)
    80003e68:	fcf4ede3          	bltu	s1,a5,80003e42 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e6c:	4639                	li	a2,14
    80003e6e:	85d2                	mv	a1,s4
    80003e70:	fc240513          	addi	a0,s0,-62
    80003e74:	ffffd097          	auipc	ra,0xffffd
    80003e78:	fdc080e7          	jalr	-36(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003e7c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e80:	4741                	li	a4,16
    80003e82:	86a6                	mv	a3,s1
    80003e84:	fc040613          	addi	a2,s0,-64
    80003e88:	4581                	li	a1,0
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	c44080e7          	jalr	-956(ra) # 80003ad0 <writei>
    80003e94:	1541                	addi	a0,a0,-16
    80003e96:	00a03533          	snez	a0,a0
    80003e9a:	40a00533          	neg	a0,a0
}
    80003e9e:	70e2                	ld	ra,56(sp)
    80003ea0:	7442                	ld	s0,48(sp)
    80003ea2:	74a2                	ld	s1,40(sp)
    80003ea4:	7902                	ld	s2,32(sp)
    80003ea6:	69e2                	ld	s3,24(sp)
    80003ea8:	6a42                	ld	s4,16(sp)
    80003eaa:	6121                	addi	sp,sp,64
    80003eac:	8082                	ret
    iput(ip);
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	a30080e7          	jalr	-1488(ra) # 800038de <iput>
    return -1;
    80003eb6:	557d                	li	a0,-1
    80003eb8:	b7dd                	j	80003e9e <dirlink+0x86>
      panic("dirlink read");
    80003eba:	00005517          	auipc	a0,0x5
    80003ebe:	77e50513          	addi	a0,a0,1918 # 80009638 <syscalls+0x1c8>
    80003ec2:	ffffc097          	auipc	ra,0xffffc
    80003ec6:	67e080e7          	jalr	1662(ra) # 80000540 <panic>

0000000080003eca <namei>:

struct inode*
namei(char *path)
{
    80003eca:	1101                	addi	sp,sp,-32
    80003ecc:	ec06                	sd	ra,24(sp)
    80003ece:	e822                	sd	s0,16(sp)
    80003ed0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ed2:	fe040613          	addi	a2,s0,-32
    80003ed6:	4581                	li	a1,0
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	de0080e7          	jalr	-544(ra) # 80003cb8 <namex>
}
    80003ee0:	60e2                	ld	ra,24(sp)
    80003ee2:	6442                	ld	s0,16(sp)
    80003ee4:	6105                	addi	sp,sp,32
    80003ee6:	8082                	ret

0000000080003ee8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ee8:	1141                	addi	sp,sp,-16
    80003eea:	e406                	sd	ra,8(sp)
    80003eec:	e022                	sd	s0,0(sp)
    80003eee:	0800                	addi	s0,sp,16
    80003ef0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ef2:	4585                	li	a1,1
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	dc4080e7          	jalr	-572(ra) # 80003cb8 <namex>
}
    80003efc:	60a2                	ld	ra,8(sp)
    80003efe:	6402                	ld	s0,0(sp)
    80003f00:	0141                	addi	sp,sp,16
    80003f02:	8082                	ret

0000000080003f04 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f04:	1101                	addi	sp,sp,-32
    80003f06:	ec06                	sd	ra,24(sp)
    80003f08:	e822                	sd	s0,16(sp)
    80003f0a:	e426                	sd	s1,8(sp)
    80003f0c:	e04a                	sd	s2,0(sp)
    80003f0e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f10:	0001e917          	auipc	s2,0x1e
    80003f14:	1a090913          	addi	s2,s2,416 # 800220b0 <log>
    80003f18:	01892583          	lw	a1,24(s2)
    80003f1c:	02892503          	lw	a0,40(s2)
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	ff4080e7          	jalr	-12(ra) # 80002f14 <bread>
    80003f28:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f2a:	02c92603          	lw	a2,44(s2)
    80003f2e:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f30:	00c05f63          	blez	a2,80003f4e <write_head+0x4a>
    80003f34:	0001e717          	auipc	a4,0x1e
    80003f38:	1ac70713          	addi	a4,a4,428 # 800220e0 <log+0x30>
    80003f3c:	87aa                	mv	a5,a0
    80003f3e:	060a                	slli	a2,a2,0x2
    80003f40:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f42:	4314                	lw	a3,0(a4)
    80003f44:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f46:	0711                	addi	a4,a4,4
    80003f48:	0791                	addi	a5,a5,4
    80003f4a:	fec79ce3          	bne	a5,a2,80003f42 <write_head+0x3e>
  }
  bwrite(buf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	0b6080e7          	jalr	182(ra) # 80003006 <bwrite>
  brelse(buf);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	0ea080e7          	jalr	234(ra) # 80003044 <brelse>
}
    80003f62:	60e2                	ld	ra,24(sp)
    80003f64:	6442                	ld	s0,16(sp)
    80003f66:	64a2                	ld	s1,8(sp)
    80003f68:	6902                	ld	s2,0(sp)
    80003f6a:	6105                	addi	sp,sp,32
    80003f6c:	8082                	ret

0000000080003f6e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f6e:	0001e797          	auipc	a5,0x1e
    80003f72:	16e7a783          	lw	a5,366(a5) # 800220dc <log+0x2c>
    80003f76:	0af05d63          	blez	a5,80004030 <install_trans+0xc2>
{
    80003f7a:	7139                	addi	sp,sp,-64
    80003f7c:	fc06                	sd	ra,56(sp)
    80003f7e:	f822                	sd	s0,48(sp)
    80003f80:	f426                	sd	s1,40(sp)
    80003f82:	f04a                	sd	s2,32(sp)
    80003f84:	ec4e                	sd	s3,24(sp)
    80003f86:	e852                	sd	s4,16(sp)
    80003f88:	e456                	sd	s5,8(sp)
    80003f8a:	e05a                	sd	s6,0(sp)
    80003f8c:	0080                	addi	s0,sp,64
    80003f8e:	8b2a                	mv	s6,a0
    80003f90:	0001ea97          	auipc	s5,0x1e
    80003f94:	150a8a93          	addi	s5,s5,336 # 800220e0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f98:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f9a:	0001e997          	auipc	s3,0x1e
    80003f9e:	11698993          	addi	s3,s3,278 # 800220b0 <log>
    80003fa2:	a00d                	j	80003fc4 <install_trans+0x56>
    brelse(lbuf);
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	09e080e7          	jalr	158(ra) # 80003044 <brelse>
    brelse(dbuf);
    80003fae:	8526                	mv	a0,s1
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	094080e7          	jalr	148(ra) # 80003044 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb8:	2a05                	addiw	s4,s4,1
    80003fba:	0a91                	addi	s5,s5,4
    80003fbc:	02c9a783          	lw	a5,44(s3)
    80003fc0:	04fa5e63          	bge	s4,a5,8000401c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fc4:	0189a583          	lw	a1,24(s3)
    80003fc8:	014585bb          	addw	a1,a1,s4
    80003fcc:	2585                	addiw	a1,a1,1
    80003fce:	0289a503          	lw	a0,40(s3)
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	f42080e7          	jalr	-190(ra) # 80002f14 <bread>
    80003fda:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fdc:	000aa583          	lw	a1,0(s5)
    80003fe0:	0289a503          	lw	a0,40(s3)
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	f30080e7          	jalr	-208(ra) # 80002f14 <bread>
    80003fec:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fee:	40000613          	li	a2,1024
    80003ff2:	05890593          	addi	a1,s2,88
    80003ff6:	05850513          	addi	a0,a0,88
    80003ffa:	ffffd097          	auipc	ra,0xffffd
    80003ffe:	da6080e7          	jalr	-602(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004002:	8526                	mv	a0,s1
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	002080e7          	jalr	2(ra) # 80003006 <bwrite>
    if(recovering == 0)
    8000400c:	f80b1ce3          	bnez	s6,80003fa4 <install_trans+0x36>
      bunpin(dbuf);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	10a080e7          	jalr	266(ra) # 8000311c <bunpin>
    8000401a:	b769                	j	80003fa4 <install_trans+0x36>
}
    8000401c:	70e2                	ld	ra,56(sp)
    8000401e:	7442                	ld	s0,48(sp)
    80004020:	74a2                	ld	s1,40(sp)
    80004022:	7902                	ld	s2,32(sp)
    80004024:	69e2                	ld	s3,24(sp)
    80004026:	6a42                	ld	s4,16(sp)
    80004028:	6aa2                	ld	s5,8(sp)
    8000402a:	6b02                	ld	s6,0(sp)
    8000402c:	6121                	addi	sp,sp,64
    8000402e:	8082                	ret
    80004030:	8082                	ret

0000000080004032 <initlog>:
{
    80004032:	7179                	addi	sp,sp,-48
    80004034:	f406                	sd	ra,40(sp)
    80004036:	f022                	sd	s0,32(sp)
    80004038:	ec26                	sd	s1,24(sp)
    8000403a:	e84a                	sd	s2,16(sp)
    8000403c:	e44e                	sd	s3,8(sp)
    8000403e:	1800                	addi	s0,sp,48
    80004040:	892a                	mv	s2,a0
    80004042:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004044:	0001e497          	auipc	s1,0x1e
    80004048:	06c48493          	addi	s1,s1,108 # 800220b0 <log>
    8000404c:	00005597          	auipc	a1,0x5
    80004050:	5fc58593          	addi	a1,a1,1532 # 80009648 <syscalls+0x1d8>
    80004054:	8526                	mv	a0,s1
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	b62080e7          	jalr	-1182(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    8000405e:	0149a583          	lw	a1,20(s3)
    80004062:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004064:	0109a783          	lw	a5,16(s3)
    80004068:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000406a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000406e:	854a                	mv	a0,s2
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	ea4080e7          	jalr	-348(ra) # 80002f14 <bread>
  log.lh.n = lh->n;
    80004078:	4d30                	lw	a2,88(a0)
    8000407a:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000407c:	00c05f63          	blez	a2,8000409a <initlog+0x68>
    80004080:	87aa                	mv	a5,a0
    80004082:	0001e717          	auipc	a4,0x1e
    80004086:	05e70713          	addi	a4,a4,94 # 800220e0 <log+0x30>
    8000408a:	060a                	slli	a2,a2,0x2
    8000408c:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000408e:	4ff4                	lw	a3,92(a5)
    80004090:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004092:	0791                	addi	a5,a5,4
    80004094:	0711                	addi	a4,a4,4
    80004096:	fec79ce3          	bne	a5,a2,8000408e <initlog+0x5c>
  brelse(buf);
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	faa080e7          	jalr	-86(ra) # 80003044 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040a2:	4505                	li	a0,1
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	eca080e7          	jalr	-310(ra) # 80003f6e <install_trans>
  log.lh.n = 0;
    800040ac:	0001e797          	auipc	a5,0x1e
    800040b0:	0207a823          	sw	zero,48(a5) # 800220dc <log+0x2c>
  write_head(); // clear the log
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	e50080e7          	jalr	-432(ra) # 80003f04 <write_head>
}
    800040bc:	70a2                	ld	ra,40(sp)
    800040be:	7402                	ld	s0,32(sp)
    800040c0:	64e2                	ld	s1,24(sp)
    800040c2:	6942                	ld	s2,16(sp)
    800040c4:	69a2                	ld	s3,8(sp)
    800040c6:	6145                	addi	sp,sp,48
    800040c8:	8082                	ret

00000000800040ca <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040ca:	1101                	addi	sp,sp,-32
    800040cc:	ec06                	sd	ra,24(sp)
    800040ce:	e822                	sd	s0,16(sp)
    800040d0:	e426                	sd	s1,8(sp)
    800040d2:	e04a                	sd	s2,0(sp)
    800040d4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040d6:	0001e517          	auipc	a0,0x1e
    800040da:	fda50513          	addi	a0,a0,-38 # 800220b0 <log>
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	b6a080e7          	jalr	-1174(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    800040e6:	0001e497          	auipc	s1,0x1e
    800040ea:	fca48493          	addi	s1,s1,-54 # 800220b0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ee:	4979                	li	s2,30
    800040f0:	a039                	j	800040fe <begin_op+0x34>
      sleep(&log, &log.lock);
    800040f2:	85a6                	mv	a1,s1
    800040f4:	8526                	mv	a0,s1
    800040f6:	ffffe097          	auipc	ra,0xffffe
    800040fa:	004080e7          	jalr	4(ra) # 800020fa <sleep>
    if(log.committing){
    800040fe:	50dc                	lw	a5,36(s1)
    80004100:	fbed                	bnez	a5,800040f2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004102:	5098                	lw	a4,32(s1)
    80004104:	2705                	addiw	a4,a4,1
    80004106:	0027179b          	slliw	a5,a4,0x2
    8000410a:	9fb9                	addw	a5,a5,a4
    8000410c:	0017979b          	slliw	a5,a5,0x1
    80004110:	54d4                	lw	a3,44(s1)
    80004112:	9fb5                	addw	a5,a5,a3
    80004114:	00f95963          	bge	s2,a5,80004126 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004118:	85a6                	mv	a1,s1
    8000411a:	8526                	mv	a0,s1
    8000411c:	ffffe097          	auipc	ra,0xffffe
    80004120:	fde080e7          	jalr	-34(ra) # 800020fa <sleep>
    80004124:	bfe9                	j	800040fe <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004126:	0001e517          	auipc	a0,0x1e
    8000412a:	f8a50513          	addi	a0,a0,-118 # 800220b0 <log>
    8000412e:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	bcc080e7          	jalr	-1076(ra) # 80000cfc <release>
      break;
    }
  }
}
    80004138:	60e2                	ld	ra,24(sp)
    8000413a:	6442                	ld	s0,16(sp)
    8000413c:	64a2                	ld	s1,8(sp)
    8000413e:	6902                	ld	s2,0(sp)
    80004140:	6105                	addi	sp,sp,32
    80004142:	8082                	ret

0000000080004144 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004144:	7139                	addi	sp,sp,-64
    80004146:	fc06                	sd	ra,56(sp)
    80004148:	f822                	sd	s0,48(sp)
    8000414a:	f426                	sd	s1,40(sp)
    8000414c:	f04a                	sd	s2,32(sp)
    8000414e:	ec4e                	sd	s3,24(sp)
    80004150:	e852                	sd	s4,16(sp)
    80004152:	e456                	sd	s5,8(sp)
    80004154:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004156:	0001e497          	auipc	s1,0x1e
    8000415a:	f5a48493          	addi	s1,s1,-166 # 800220b0 <log>
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	ae8080e7          	jalr	-1304(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    80004168:	509c                	lw	a5,32(s1)
    8000416a:	37fd                	addiw	a5,a5,-1
    8000416c:	0007891b          	sext.w	s2,a5
    80004170:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004172:	50dc                	lw	a5,36(s1)
    80004174:	e7b9                	bnez	a5,800041c2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004176:	04091e63          	bnez	s2,800041d2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000417a:	0001e497          	auipc	s1,0x1e
    8000417e:	f3648493          	addi	s1,s1,-202 # 800220b0 <log>
    80004182:	4785                	li	a5,1
    80004184:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004186:	8526                	mv	a0,s1
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	b74080e7          	jalr	-1164(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004190:	54dc                	lw	a5,44(s1)
    80004192:	06f04763          	bgtz	a5,80004200 <end_op+0xbc>
    acquire(&log.lock);
    80004196:	0001e497          	auipc	s1,0x1e
    8000419a:	f1a48493          	addi	s1,s1,-230 # 800220b0 <log>
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	aa8080e7          	jalr	-1368(ra) # 80000c48 <acquire>
    log.committing = 0;
    800041a8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ac:	8526                	mv	a0,s1
    800041ae:	ffffe097          	auipc	ra,0xffffe
    800041b2:	fb0080e7          	jalr	-80(ra) # 8000215e <wakeup>
    release(&log.lock);
    800041b6:	8526                	mv	a0,s1
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	b44080e7          	jalr	-1212(ra) # 80000cfc <release>
}
    800041c0:	a03d                	j	800041ee <end_op+0xaa>
    panic("log.committing");
    800041c2:	00005517          	auipc	a0,0x5
    800041c6:	48e50513          	addi	a0,a0,1166 # 80009650 <syscalls+0x1e0>
    800041ca:	ffffc097          	auipc	ra,0xffffc
    800041ce:	376080e7          	jalr	886(ra) # 80000540 <panic>
    wakeup(&log);
    800041d2:	0001e497          	auipc	s1,0x1e
    800041d6:	ede48493          	addi	s1,s1,-290 # 800220b0 <log>
    800041da:	8526                	mv	a0,s1
    800041dc:	ffffe097          	auipc	ra,0xffffe
    800041e0:	f82080e7          	jalr	-126(ra) # 8000215e <wakeup>
  release(&log.lock);
    800041e4:	8526                	mv	a0,s1
    800041e6:	ffffd097          	auipc	ra,0xffffd
    800041ea:	b16080e7          	jalr	-1258(ra) # 80000cfc <release>
}
    800041ee:	70e2                	ld	ra,56(sp)
    800041f0:	7442                	ld	s0,48(sp)
    800041f2:	74a2                	ld	s1,40(sp)
    800041f4:	7902                	ld	s2,32(sp)
    800041f6:	69e2                	ld	s3,24(sp)
    800041f8:	6a42                	ld	s4,16(sp)
    800041fa:	6aa2                	ld	s5,8(sp)
    800041fc:	6121                	addi	sp,sp,64
    800041fe:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004200:	0001ea97          	auipc	s5,0x1e
    80004204:	ee0a8a93          	addi	s5,s5,-288 # 800220e0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004208:	0001ea17          	auipc	s4,0x1e
    8000420c:	ea8a0a13          	addi	s4,s4,-344 # 800220b0 <log>
    80004210:	018a2583          	lw	a1,24(s4)
    80004214:	012585bb          	addw	a1,a1,s2
    80004218:	2585                	addiw	a1,a1,1
    8000421a:	028a2503          	lw	a0,40(s4)
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	cf6080e7          	jalr	-778(ra) # 80002f14 <bread>
    80004226:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004228:	000aa583          	lw	a1,0(s5)
    8000422c:	028a2503          	lw	a0,40(s4)
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	ce4080e7          	jalr	-796(ra) # 80002f14 <bread>
    80004238:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000423a:	40000613          	li	a2,1024
    8000423e:	05850593          	addi	a1,a0,88
    80004242:	05848513          	addi	a0,s1,88
    80004246:	ffffd097          	auipc	ra,0xffffd
    8000424a:	b5a080e7          	jalr	-1190(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    8000424e:	8526                	mv	a0,s1
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	db6080e7          	jalr	-586(ra) # 80003006 <bwrite>
    brelse(from);
    80004258:	854e                	mv	a0,s3
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	dea080e7          	jalr	-534(ra) # 80003044 <brelse>
    brelse(to);
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	de0080e7          	jalr	-544(ra) # 80003044 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426c:	2905                	addiw	s2,s2,1
    8000426e:	0a91                	addi	s5,s5,4
    80004270:	02ca2783          	lw	a5,44(s4)
    80004274:	f8f94ee3          	blt	s2,a5,80004210 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	c8c080e7          	jalr	-884(ra) # 80003f04 <write_head>
    install_trans(0); // Now install writes to home locations
    80004280:	4501                	li	a0,0
    80004282:	00000097          	auipc	ra,0x0
    80004286:	cec080e7          	jalr	-788(ra) # 80003f6e <install_trans>
    log.lh.n = 0;
    8000428a:	0001e797          	auipc	a5,0x1e
    8000428e:	e407a923          	sw	zero,-430(a5) # 800220dc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004292:	00000097          	auipc	ra,0x0
    80004296:	c72080e7          	jalr	-910(ra) # 80003f04 <write_head>
    8000429a:	bdf5                	j	80004196 <end_op+0x52>

000000008000429c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	e426                	sd	s1,8(sp)
    800042a4:	e04a                	sd	s2,0(sp)
    800042a6:	1000                	addi	s0,sp,32
    800042a8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042aa:	0001e917          	auipc	s2,0x1e
    800042ae:	e0690913          	addi	s2,s2,-506 # 800220b0 <log>
    800042b2:	854a                	mv	a0,s2
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	994080e7          	jalr	-1644(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042bc:	02c92603          	lw	a2,44(s2)
    800042c0:	47f5                	li	a5,29
    800042c2:	06c7c563          	blt	a5,a2,8000432c <log_write+0x90>
    800042c6:	0001e797          	auipc	a5,0x1e
    800042ca:	e067a783          	lw	a5,-506(a5) # 800220cc <log+0x1c>
    800042ce:	37fd                	addiw	a5,a5,-1
    800042d0:	04f65e63          	bge	a2,a5,8000432c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042d4:	0001e797          	auipc	a5,0x1e
    800042d8:	dfc7a783          	lw	a5,-516(a5) # 800220d0 <log+0x20>
    800042dc:	06f05063          	blez	a5,8000433c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042e0:	4781                	li	a5,0
    800042e2:	06c05563          	blez	a2,8000434c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042e6:	44cc                	lw	a1,12(s1)
    800042e8:	0001e717          	auipc	a4,0x1e
    800042ec:	df870713          	addi	a4,a4,-520 # 800220e0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042f0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f2:	4314                	lw	a3,0(a4)
    800042f4:	04b68c63          	beq	a3,a1,8000434c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042f8:	2785                	addiw	a5,a5,1
    800042fa:	0711                	addi	a4,a4,4
    800042fc:	fef61be3          	bne	a2,a5,800042f2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004300:	0621                	addi	a2,a2,8
    80004302:	060a                	slli	a2,a2,0x2
    80004304:	0001e797          	auipc	a5,0x1e
    80004308:	dac78793          	addi	a5,a5,-596 # 800220b0 <log>
    8000430c:	97b2                	add	a5,a5,a2
    8000430e:	44d8                	lw	a4,12(s1)
    80004310:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004312:	8526                	mv	a0,s1
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	dcc080e7          	jalr	-564(ra) # 800030e0 <bpin>
    log.lh.n++;
    8000431c:	0001e717          	auipc	a4,0x1e
    80004320:	d9470713          	addi	a4,a4,-620 # 800220b0 <log>
    80004324:	575c                	lw	a5,44(a4)
    80004326:	2785                	addiw	a5,a5,1
    80004328:	d75c                	sw	a5,44(a4)
    8000432a:	a82d                	j	80004364 <log_write+0xc8>
    panic("too big a transaction");
    8000432c:	00005517          	auipc	a0,0x5
    80004330:	33450513          	addi	a0,a0,820 # 80009660 <syscalls+0x1f0>
    80004334:	ffffc097          	auipc	ra,0xffffc
    80004338:	20c080e7          	jalr	524(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000433c:	00005517          	auipc	a0,0x5
    80004340:	33c50513          	addi	a0,a0,828 # 80009678 <syscalls+0x208>
    80004344:	ffffc097          	auipc	ra,0xffffc
    80004348:	1fc080e7          	jalr	508(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000434c:	00878693          	addi	a3,a5,8
    80004350:	068a                	slli	a3,a3,0x2
    80004352:	0001e717          	auipc	a4,0x1e
    80004356:	d5e70713          	addi	a4,a4,-674 # 800220b0 <log>
    8000435a:	9736                	add	a4,a4,a3
    8000435c:	44d4                	lw	a3,12(s1)
    8000435e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004360:	faf609e3          	beq	a2,a5,80004312 <log_write+0x76>
  }
  release(&log.lock);
    80004364:	0001e517          	auipc	a0,0x1e
    80004368:	d4c50513          	addi	a0,a0,-692 # 800220b0 <log>
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	990080e7          	jalr	-1648(ra) # 80000cfc <release>
}
    80004374:	60e2                	ld	ra,24(sp)
    80004376:	6442                	ld	s0,16(sp)
    80004378:	64a2                	ld	s1,8(sp)
    8000437a:	6902                	ld	s2,0(sp)
    8000437c:	6105                	addi	sp,sp,32
    8000437e:	8082                	ret

0000000080004380 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	e04a                	sd	s2,0(sp)
    8000438a:	1000                	addi	s0,sp,32
    8000438c:	84aa                	mv	s1,a0
    8000438e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004390:	00005597          	auipc	a1,0x5
    80004394:	30858593          	addi	a1,a1,776 # 80009698 <syscalls+0x228>
    80004398:	0521                	addi	a0,a0,8
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	81e080e7          	jalr	-2018(ra) # 80000bb8 <initlock>
  lk->name = name;
    800043a2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043aa:	0204a423          	sw	zero,40(s1)
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c8:	00850913          	addi	s2,a0,8
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	87a080e7          	jalr	-1926(ra) # 80000c48 <acquire>
  while (lk->locked) {
    800043d6:	409c                	lw	a5,0(s1)
    800043d8:	cb89                	beqz	a5,800043ea <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043da:	85ca                	mv	a1,s2
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffe097          	auipc	ra,0xffffe
    800043e2:	d1c080e7          	jalr	-740(ra) # 800020fa <sleep>
  while (lk->locked) {
    800043e6:	409c                	lw	a5,0(s1)
    800043e8:	fbed                	bnez	a5,800043da <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043ea:	4785                	li	a5,1
    800043ec:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800043f6:	591c                	lw	a5,48(a0)
    800043f8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043fa:	854a                	mv	a0,s2
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	900080e7          	jalr	-1792(ra) # 80000cfc <release>
}
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	64a2                	ld	s1,8(sp)
    8000440a:	6902                	ld	s2,0(sp)
    8000440c:	6105                	addi	sp,sp,32
    8000440e:	8082                	ret

0000000080004410 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004410:	1101                	addi	sp,sp,-32
    80004412:	ec06                	sd	ra,24(sp)
    80004414:	e822                	sd	s0,16(sp)
    80004416:	e426                	sd	s1,8(sp)
    80004418:	e04a                	sd	s2,0(sp)
    8000441a:	1000                	addi	s0,sp,32
    8000441c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000441e:	00850913          	addi	s2,a0,8
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	824080e7          	jalr	-2012(ra) # 80000c48 <acquire>
  lk->locked = 0;
    8000442c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004430:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	d28080e7          	jalr	-728(ra) # 8000215e <wakeup>
  release(&lk->lk);
    8000443e:	854a                	mv	a0,s2
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	8bc080e7          	jalr	-1860(ra) # 80000cfc <release>
}
    80004448:	60e2                	ld	ra,24(sp)
    8000444a:	6442                	ld	s0,16(sp)
    8000444c:	64a2                	ld	s1,8(sp)
    8000444e:	6902                	ld	s2,0(sp)
    80004450:	6105                	addi	sp,sp,32
    80004452:	8082                	ret

0000000080004454 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004454:	7179                	addi	sp,sp,-48
    80004456:	f406                	sd	ra,40(sp)
    80004458:	f022                	sd	s0,32(sp)
    8000445a:	ec26                	sd	s1,24(sp)
    8000445c:	e84a                	sd	s2,16(sp)
    8000445e:	e44e                	sd	s3,8(sp)
    80004460:	1800                	addi	s0,sp,48
    80004462:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004464:	00850913          	addi	s2,a0,8
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	7de080e7          	jalr	2014(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004472:	409c                	lw	a5,0(s1)
    80004474:	ef99                	bnez	a5,80004492 <holdingsleep+0x3e>
    80004476:	4481                	li	s1,0
  release(&lk->lk);
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	882080e7          	jalr	-1918(ra) # 80000cfc <release>
  return r;
}
    80004482:	8526                	mv	a0,s1
    80004484:	70a2                	ld	ra,40(sp)
    80004486:	7402                	ld	s0,32(sp)
    80004488:	64e2                	ld	s1,24(sp)
    8000448a:	6942                	ld	s2,16(sp)
    8000448c:	69a2                	ld	s3,8(sp)
    8000448e:	6145                	addi	sp,sp,48
    80004490:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004492:	0284a983          	lw	s3,40(s1)
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	58e080e7          	jalr	1422(ra) # 80001a24 <myproc>
    8000449e:	5904                	lw	s1,48(a0)
    800044a0:	413484b3          	sub	s1,s1,s3
    800044a4:	0014b493          	seqz	s1,s1
    800044a8:	bfc1                	j	80004478 <holdingsleep+0x24>

00000000800044aa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044aa:	1141                	addi	sp,sp,-16
    800044ac:	e406                	sd	ra,8(sp)
    800044ae:	e022                	sd	s0,0(sp)
    800044b0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044b2:	00005597          	auipc	a1,0x5
    800044b6:	1f658593          	addi	a1,a1,502 # 800096a8 <syscalls+0x238>
    800044ba:	0001e517          	auipc	a0,0x1e
    800044be:	d3e50513          	addi	a0,a0,-706 # 800221f8 <ftable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	6f6080e7          	jalr	1782(ra) # 80000bb8 <initlock>
}
    800044ca:	60a2                	ld	ra,8(sp)
    800044cc:	6402                	ld	s0,0(sp)
    800044ce:	0141                	addi	sp,sp,16
    800044d0:	8082                	ret

00000000800044d2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044dc:	0001e517          	auipc	a0,0x1e
    800044e0:	d1c50513          	addi	a0,a0,-740 # 800221f8 <ftable>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	764080e7          	jalr	1892(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ec:	0001e497          	auipc	s1,0x1e
    800044f0:	d2448493          	addi	s1,s1,-732 # 80022210 <ftable+0x18>
    800044f4:	0001f717          	auipc	a4,0x1f
    800044f8:	cbc70713          	addi	a4,a4,-836 # 800231b0 <disk>
    if(f->ref == 0){
    800044fc:	40dc                	lw	a5,4(s1)
    800044fe:	cf99                	beqz	a5,8000451c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004500:	02848493          	addi	s1,s1,40
    80004504:	fee49ce3          	bne	s1,a4,800044fc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004508:	0001e517          	auipc	a0,0x1e
    8000450c:	cf050513          	addi	a0,a0,-784 # 800221f8 <ftable>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	7ec080e7          	jalr	2028(ra) # 80000cfc <release>
  return 0;
    80004518:	4481                	li	s1,0
    8000451a:	a819                	j	80004530 <filealloc+0x5e>
      f->ref = 1;
    8000451c:	4785                	li	a5,1
    8000451e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004520:	0001e517          	auipc	a0,0x1e
    80004524:	cd850513          	addi	a0,a0,-808 # 800221f8 <ftable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	7d4080e7          	jalr	2004(ra) # 80000cfc <release>
}
    80004530:	8526                	mv	a0,s1
    80004532:	60e2                	ld	ra,24(sp)
    80004534:	6442                	ld	s0,16(sp)
    80004536:	64a2                	ld	s1,8(sp)
    80004538:	6105                	addi	sp,sp,32
    8000453a:	8082                	ret

000000008000453c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000453c:	1101                	addi	sp,sp,-32
    8000453e:	ec06                	sd	ra,24(sp)
    80004540:	e822                	sd	s0,16(sp)
    80004542:	e426                	sd	s1,8(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004548:	0001e517          	auipc	a0,0x1e
    8000454c:	cb050513          	addi	a0,a0,-848 # 800221f8 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	6f8080e7          	jalr	1784(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    80004558:	40dc                	lw	a5,4(s1)
    8000455a:	02f05263          	blez	a5,8000457e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000455e:	2785                	addiw	a5,a5,1
    80004560:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004562:	0001e517          	auipc	a0,0x1e
    80004566:	c9650513          	addi	a0,a0,-874 # 800221f8 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	792080e7          	jalr	1938(ra) # 80000cfc <release>
  return f;
}
    80004572:	8526                	mv	a0,s1
    80004574:	60e2                	ld	ra,24(sp)
    80004576:	6442                	ld	s0,16(sp)
    80004578:	64a2                	ld	s1,8(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret
    panic("filedup");
    8000457e:	00005517          	auipc	a0,0x5
    80004582:	13250513          	addi	a0,a0,306 # 800096b0 <syscalls+0x240>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fba080e7          	jalr	-70(ra) # 80000540 <panic>

000000008000458e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000458e:	7139                	addi	sp,sp,-64
    80004590:	fc06                	sd	ra,56(sp)
    80004592:	f822                	sd	s0,48(sp)
    80004594:	f426                	sd	s1,40(sp)
    80004596:	f04a                	sd	s2,32(sp)
    80004598:	ec4e                	sd	s3,24(sp)
    8000459a:	e852                	sd	s4,16(sp)
    8000459c:	e456                	sd	s5,8(sp)
    8000459e:	0080                	addi	s0,sp,64
    800045a0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045a2:	0001e517          	auipc	a0,0x1e
    800045a6:	c5650513          	addi	a0,a0,-938 # 800221f8 <ftable>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	69e080e7          	jalr	1694(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045b2:	40dc                	lw	a5,4(s1)
    800045b4:	06f05163          	blez	a5,80004616 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045b8:	37fd                	addiw	a5,a5,-1
    800045ba:	0007871b          	sext.w	a4,a5
    800045be:	c0dc                	sw	a5,4(s1)
    800045c0:	06e04363          	bgtz	a4,80004626 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045c4:	0004a903          	lw	s2,0(s1)
    800045c8:	0094ca83          	lbu	s5,9(s1)
    800045cc:	0104ba03          	ld	s4,16(s1)
    800045d0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045d4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045d8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045dc:	0001e517          	auipc	a0,0x1e
    800045e0:	c1c50513          	addi	a0,a0,-996 # 800221f8 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	718080e7          	jalr	1816(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    800045ec:	4785                	li	a5,1
    800045ee:	04f90d63          	beq	s2,a5,80004648 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045f2:	3979                	addiw	s2,s2,-2
    800045f4:	4785                	li	a5,1
    800045f6:	0527e063          	bltu	a5,s2,80004636 <fileclose+0xa8>
    begin_op();
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	ad0080e7          	jalr	-1328(ra) # 800040ca <begin_op>
    iput(ff.ip);
    80004602:	854e                	mv	a0,s3
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	2da080e7          	jalr	730(ra) # 800038de <iput>
    end_op();
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	b38080e7          	jalr	-1224(ra) # 80004144 <end_op>
    80004614:	a00d                	j	80004636 <fileclose+0xa8>
    panic("fileclose");
    80004616:	00005517          	auipc	a0,0x5
    8000461a:	0a250513          	addi	a0,a0,162 # 800096b8 <syscalls+0x248>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f22080e7          	jalr	-222(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004626:	0001e517          	auipc	a0,0x1e
    8000462a:	bd250513          	addi	a0,a0,-1070 # 800221f8 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	6ce080e7          	jalr	1742(ra) # 80000cfc <release>
  }
}
    80004636:	70e2                	ld	ra,56(sp)
    80004638:	7442                	ld	s0,48(sp)
    8000463a:	74a2                	ld	s1,40(sp)
    8000463c:	7902                	ld	s2,32(sp)
    8000463e:	69e2                	ld	s3,24(sp)
    80004640:	6a42                	ld	s4,16(sp)
    80004642:	6aa2                	ld	s5,8(sp)
    80004644:	6121                	addi	sp,sp,64
    80004646:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004648:	85d6                	mv	a1,s5
    8000464a:	8552                	mv	a0,s4
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	348080e7          	jalr	840(ra) # 80004994 <pipeclose>
    80004654:	b7cd                	j	80004636 <fileclose+0xa8>

0000000080004656 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004656:	715d                	addi	sp,sp,-80
    80004658:	e486                	sd	ra,72(sp)
    8000465a:	e0a2                	sd	s0,64(sp)
    8000465c:	fc26                	sd	s1,56(sp)
    8000465e:	f84a                	sd	s2,48(sp)
    80004660:	f44e                	sd	s3,40(sp)
    80004662:	0880                	addi	s0,sp,80
    80004664:	84aa                	mv	s1,a0
    80004666:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	3bc080e7          	jalr	956(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004670:	409c                	lw	a5,0(s1)
    80004672:	37f9                	addiw	a5,a5,-2
    80004674:	4705                	li	a4,1
    80004676:	04f76763          	bltu	a4,a5,800046c4 <filestat+0x6e>
    8000467a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000467c:	6c88                	ld	a0,24(s1)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	0a6080e7          	jalr	166(ra) # 80003724 <ilock>
    stati(f->ip, &st);
    80004686:	fb840593          	addi	a1,s0,-72
    8000468a:	6c88                	ld	a0,24(s1)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	322080e7          	jalr	802(ra) # 800039ae <stati>
    iunlock(f->ip);
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	150080e7          	jalr	336(ra) # 800037e6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000469e:	46e1                	li	a3,24
    800046a0:	fb840613          	addi	a2,s0,-72
    800046a4:	85ce                	mv	a1,s3
    800046a6:	05093503          	ld	a0,80(s2)
    800046aa:	ffffd097          	auipc	ra,0xffffd
    800046ae:	03a080e7          	jalr	58(ra) # 800016e4 <copyout>
    800046b2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046b6:	60a6                	ld	ra,72(sp)
    800046b8:	6406                	ld	s0,64(sp)
    800046ba:	74e2                	ld	s1,56(sp)
    800046bc:	7942                	ld	s2,48(sp)
    800046be:	79a2                	ld	s3,40(sp)
    800046c0:	6161                	addi	sp,sp,80
    800046c2:	8082                	ret
  return -1;
    800046c4:	557d                	li	a0,-1
    800046c6:	bfc5                	j	800046b6 <filestat+0x60>

00000000800046c8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046c8:	7179                	addi	sp,sp,-48
    800046ca:	f406                	sd	ra,40(sp)
    800046cc:	f022                	sd	s0,32(sp)
    800046ce:	ec26                	sd	s1,24(sp)
    800046d0:	e84a                	sd	s2,16(sp)
    800046d2:	e44e                	sd	s3,8(sp)
    800046d4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046d6:	00854783          	lbu	a5,8(a0)
    800046da:	c3d5                	beqz	a5,8000477e <fileread+0xb6>
    800046dc:	84aa                	mv	s1,a0
    800046de:	89ae                	mv	s3,a1
    800046e0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046e2:	411c                	lw	a5,0(a0)
    800046e4:	4705                	li	a4,1
    800046e6:	04e78963          	beq	a5,a4,80004738 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046ea:	470d                	li	a4,3
    800046ec:	04e78d63          	beq	a5,a4,80004746 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046f0:	4709                	li	a4,2
    800046f2:	06e79e63          	bne	a5,a4,8000476e <fileread+0xa6>
    ilock(f->ip);
    800046f6:	6d08                	ld	a0,24(a0)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	02c080e7          	jalr	44(ra) # 80003724 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004700:	874a                	mv	a4,s2
    80004702:	5094                	lw	a3,32(s1)
    80004704:	864e                	mv	a2,s3
    80004706:	4585                	li	a1,1
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	2ce080e7          	jalr	718(ra) # 800039d8 <readi>
    80004712:	892a                	mv	s2,a0
    80004714:	00a05563          	blez	a0,8000471e <fileread+0x56>
      f->off += r;
    80004718:	509c                	lw	a5,32(s1)
    8000471a:	9fa9                	addw	a5,a5,a0
    8000471c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000471e:	6c88                	ld	a0,24(s1)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	0c6080e7          	jalr	198(ra) # 800037e6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004728:	854a                	mv	a0,s2
    8000472a:	70a2                	ld	ra,40(sp)
    8000472c:	7402                	ld	s0,32(sp)
    8000472e:	64e2                	ld	s1,24(sp)
    80004730:	6942                	ld	s2,16(sp)
    80004732:	69a2                	ld	s3,8(sp)
    80004734:	6145                	addi	sp,sp,48
    80004736:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004738:	6908                	ld	a0,16(a0)
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	3c2080e7          	jalr	962(ra) # 80004afc <piperead>
    80004742:	892a                	mv	s2,a0
    80004744:	b7d5                	j	80004728 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004746:	02451783          	lh	a5,36(a0)
    8000474a:	03079693          	slli	a3,a5,0x30
    8000474e:	92c1                	srli	a3,a3,0x30
    80004750:	4725                	li	a4,9
    80004752:	02d76863          	bltu	a4,a3,80004782 <fileread+0xba>
    80004756:	0792                	slli	a5,a5,0x4
    80004758:	0001e717          	auipc	a4,0x1e
    8000475c:	a0070713          	addi	a4,a4,-1536 # 80022158 <devsw>
    80004760:	97ba                	add	a5,a5,a4
    80004762:	639c                	ld	a5,0(a5)
    80004764:	c38d                	beqz	a5,80004786 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004766:	4505                	li	a0,1
    80004768:	9782                	jalr	a5
    8000476a:	892a                	mv	s2,a0
    8000476c:	bf75                	j	80004728 <fileread+0x60>
    panic("fileread");
    8000476e:	00005517          	auipc	a0,0x5
    80004772:	f5a50513          	addi	a0,a0,-166 # 800096c8 <syscalls+0x258>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	dca080e7          	jalr	-566(ra) # 80000540 <panic>
    return -1;
    8000477e:	597d                	li	s2,-1
    80004780:	b765                	j	80004728 <fileread+0x60>
      return -1;
    80004782:	597d                	li	s2,-1
    80004784:	b755                	j	80004728 <fileread+0x60>
    80004786:	597d                	li	s2,-1
    80004788:	b745                	j	80004728 <fileread+0x60>

000000008000478a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000478a:	00954783          	lbu	a5,9(a0)
    8000478e:	10078e63          	beqz	a5,800048aa <filewrite+0x120>
{
    80004792:	715d                	addi	sp,sp,-80
    80004794:	e486                	sd	ra,72(sp)
    80004796:	e0a2                	sd	s0,64(sp)
    80004798:	fc26                	sd	s1,56(sp)
    8000479a:	f84a                	sd	s2,48(sp)
    8000479c:	f44e                	sd	s3,40(sp)
    8000479e:	f052                	sd	s4,32(sp)
    800047a0:	ec56                	sd	s5,24(sp)
    800047a2:	e85a                	sd	s6,16(sp)
    800047a4:	e45e                	sd	s7,8(sp)
    800047a6:	e062                	sd	s8,0(sp)
    800047a8:	0880                	addi	s0,sp,80
    800047aa:	892a                	mv	s2,a0
    800047ac:	8b2e                	mv	s6,a1
    800047ae:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b0:	411c                	lw	a5,0(a0)
    800047b2:	4705                	li	a4,1
    800047b4:	02e78263          	beq	a5,a4,800047d8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b8:	470d                	li	a4,3
    800047ba:	02e78563          	beq	a5,a4,800047e4 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047be:	4709                	li	a4,2
    800047c0:	0ce79d63          	bne	a5,a4,8000489a <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047c4:	0ac05b63          	blez	a2,8000487a <filewrite+0xf0>
    int i = 0;
    800047c8:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047ca:	6b85                	lui	s7,0x1
    800047cc:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047d0:	6c05                	lui	s8,0x1
    800047d2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047d6:	a851                	j	8000486a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047d8:	6908                	ld	a0,16(a0)
    800047da:	00000097          	auipc	ra,0x0
    800047de:	22a080e7          	jalr	554(ra) # 80004a04 <pipewrite>
    800047e2:	a045                	j	80004882 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047e4:	02451783          	lh	a5,36(a0)
    800047e8:	03079693          	slli	a3,a5,0x30
    800047ec:	92c1                	srli	a3,a3,0x30
    800047ee:	4725                	li	a4,9
    800047f0:	0ad76f63          	bltu	a4,a3,800048ae <filewrite+0x124>
    800047f4:	0792                	slli	a5,a5,0x4
    800047f6:	0001e717          	auipc	a4,0x1e
    800047fa:	96270713          	addi	a4,a4,-1694 # 80022158 <devsw>
    800047fe:	97ba                	add	a5,a5,a4
    80004800:	679c                	ld	a5,8(a5)
    80004802:	cbc5                	beqz	a5,800048b2 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004804:	4505                	li	a0,1
    80004806:	9782                	jalr	a5
    80004808:	a8ad                	j	80004882 <filewrite+0xf8>
      if(n1 > max)
    8000480a:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	8bc080e7          	jalr	-1860(ra) # 800040ca <begin_op>
      ilock(f->ip);
    80004816:	01893503          	ld	a0,24(s2)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	f0a080e7          	jalr	-246(ra) # 80003724 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004822:	8756                	mv	a4,s5
    80004824:	02092683          	lw	a3,32(s2)
    80004828:	01698633          	add	a2,s3,s6
    8000482c:	4585                	li	a1,1
    8000482e:	01893503          	ld	a0,24(s2)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	29e080e7          	jalr	670(ra) # 80003ad0 <writei>
    8000483a:	84aa                	mv	s1,a0
    8000483c:	00a05763          	blez	a0,8000484a <filewrite+0xc0>
        f->off += r;
    80004840:	02092783          	lw	a5,32(s2)
    80004844:	9fa9                	addw	a5,a5,a0
    80004846:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000484a:	01893503          	ld	a0,24(s2)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	f98080e7          	jalr	-104(ra) # 800037e6 <iunlock>
      end_op();
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	8ee080e7          	jalr	-1810(ra) # 80004144 <end_op>

      if(r != n1){
    8000485e:	009a9f63          	bne	s5,s1,8000487c <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004862:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004866:	0149db63          	bge	s3,s4,8000487c <filewrite+0xf2>
      int n1 = n - i;
    8000486a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000486e:	0004879b          	sext.w	a5,s1
    80004872:	f8fbdce3          	bge	s7,a5,8000480a <filewrite+0x80>
    80004876:	84e2                	mv	s1,s8
    80004878:	bf49                	j	8000480a <filewrite+0x80>
    int i = 0;
    8000487a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000487c:	033a1d63          	bne	s4,s3,800048b6 <filewrite+0x12c>
    80004880:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004882:	60a6                	ld	ra,72(sp)
    80004884:	6406                	ld	s0,64(sp)
    80004886:	74e2                	ld	s1,56(sp)
    80004888:	7942                	ld	s2,48(sp)
    8000488a:	79a2                	ld	s3,40(sp)
    8000488c:	7a02                	ld	s4,32(sp)
    8000488e:	6ae2                	ld	s5,24(sp)
    80004890:	6b42                	ld	s6,16(sp)
    80004892:	6ba2                	ld	s7,8(sp)
    80004894:	6c02                	ld	s8,0(sp)
    80004896:	6161                	addi	sp,sp,80
    80004898:	8082                	ret
    panic("filewrite");
    8000489a:	00005517          	auipc	a0,0x5
    8000489e:	e3e50513          	addi	a0,a0,-450 # 800096d8 <syscalls+0x268>
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	c9e080e7          	jalr	-866(ra) # 80000540 <panic>
    return -1;
    800048aa:	557d                	li	a0,-1
}
    800048ac:	8082                	ret
      return -1;
    800048ae:	557d                	li	a0,-1
    800048b0:	bfc9                	j	80004882 <filewrite+0xf8>
    800048b2:	557d                	li	a0,-1
    800048b4:	b7f9                	j	80004882 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048b6:	557d                	li	a0,-1
    800048b8:	b7e9                	j	80004882 <filewrite+0xf8>

00000000800048ba <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048ba:	7179                	addi	sp,sp,-48
    800048bc:	f406                	sd	ra,40(sp)
    800048be:	f022                	sd	s0,32(sp)
    800048c0:	ec26                	sd	s1,24(sp)
    800048c2:	e84a                	sd	s2,16(sp)
    800048c4:	e44e                	sd	s3,8(sp)
    800048c6:	e052                	sd	s4,0(sp)
    800048c8:	1800                	addi	s0,sp,48
    800048ca:	84aa                	mv	s1,a0
    800048cc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048ce:	0005b023          	sd	zero,0(a1)
    800048d2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	bfc080e7          	jalr	-1028(ra) # 800044d2 <filealloc>
    800048de:	e088                	sd	a0,0(s1)
    800048e0:	c551                	beqz	a0,8000496c <pipealloc+0xb2>
    800048e2:	00000097          	auipc	ra,0x0
    800048e6:	bf0080e7          	jalr	-1040(ra) # 800044d2 <filealloc>
    800048ea:	00aa3023          	sd	a0,0(s4)
    800048ee:	c92d                	beqz	a0,80004960 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	268080e7          	jalr	616(ra) # 80000b58 <kalloc>
    800048f8:	892a                	mv	s2,a0
    800048fa:	c125                	beqz	a0,8000495a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048fc:	4985                	li	s3,1
    800048fe:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004902:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004906:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000490a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000490e:	00005597          	auipc	a1,0x5
    80004912:	dda58593          	addi	a1,a1,-550 # 800096e8 <syscalls+0x278>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2a2080e7          	jalr	674(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    8000491e:	609c                	ld	a5,0(s1)
    80004920:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004924:	609c                	ld	a5,0(s1)
    80004926:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000492a:	609c                	ld	a5,0(s1)
    8000492c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004930:	609c                	ld	a5,0(s1)
    80004932:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004936:	000a3783          	ld	a5,0(s4)
    8000493a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000493e:	000a3783          	ld	a5,0(s4)
    80004942:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004946:	000a3783          	ld	a5,0(s4)
    8000494a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000494e:	000a3783          	ld	a5,0(s4)
    80004952:	0127b823          	sd	s2,16(a5)
  return 0;
    80004956:	4501                	li	a0,0
    80004958:	a025                	j	80004980 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000495a:	6088                	ld	a0,0(s1)
    8000495c:	e501                	bnez	a0,80004964 <pipealloc+0xaa>
    8000495e:	a039                	j	8000496c <pipealloc+0xb2>
    80004960:	6088                	ld	a0,0(s1)
    80004962:	c51d                	beqz	a0,80004990 <pipealloc+0xd6>
    fileclose(*f0);
    80004964:	00000097          	auipc	ra,0x0
    80004968:	c2a080e7          	jalr	-982(ra) # 8000458e <fileclose>
  if(*f1)
    8000496c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004970:	557d                	li	a0,-1
  if(*f1)
    80004972:	c799                	beqz	a5,80004980 <pipealloc+0xc6>
    fileclose(*f1);
    80004974:	853e                	mv	a0,a5
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	c18080e7          	jalr	-1000(ra) # 8000458e <fileclose>
  return -1;
    8000497e:	557d                	li	a0,-1
}
    80004980:	70a2                	ld	ra,40(sp)
    80004982:	7402                	ld	s0,32(sp)
    80004984:	64e2                	ld	s1,24(sp)
    80004986:	6942                	ld	s2,16(sp)
    80004988:	69a2                	ld	s3,8(sp)
    8000498a:	6a02                	ld	s4,0(sp)
    8000498c:	6145                	addi	sp,sp,48
    8000498e:	8082                	ret
  return -1;
    80004990:	557d                	li	a0,-1
    80004992:	b7fd                	j	80004980 <pipealloc+0xc6>

0000000080004994 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004994:	1101                	addi	sp,sp,-32
    80004996:	ec06                	sd	ra,24(sp)
    80004998:	e822                	sd	s0,16(sp)
    8000499a:	e426                	sd	s1,8(sp)
    8000499c:	e04a                	sd	s2,0(sp)
    8000499e:	1000                	addi	s0,sp,32
    800049a0:	84aa                	mv	s1,a0
    800049a2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	2a4080e7          	jalr	676(ra) # 80000c48 <acquire>
  if(writable){
    800049ac:	02090d63          	beqz	s2,800049e6 <pipeclose+0x52>
    pi->writeopen = 0;
    800049b0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049b4:	21848513          	addi	a0,s1,536
    800049b8:	ffffd097          	auipc	ra,0xffffd
    800049bc:	7a6080e7          	jalr	1958(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049c0:	2204b783          	ld	a5,544(s1)
    800049c4:	eb95                	bnez	a5,800049f8 <pipeclose+0x64>
    release(&pi->lock);
    800049c6:	8526                	mv	a0,s1
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	334080e7          	jalr	820(ra) # 80000cfc <release>
    kfree((char*)pi);
    800049d0:	8526                	mv	a0,s1
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	088080e7          	jalr	136(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    800049da:	60e2                	ld	ra,24(sp)
    800049dc:	6442                	ld	s0,16(sp)
    800049de:	64a2                	ld	s1,8(sp)
    800049e0:	6902                	ld	s2,0(sp)
    800049e2:	6105                	addi	sp,sp,32
    800049e4:	8082                	ret
    pi->readopen = 0;
    800049e6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049ea:	21c48513          	addi	a0,s1,540
    800049ee:	ffffd097          	auipc	ra,0xffffd
    800049f2:	770080e7          	jalr	1904(ra) # 8000215e <wakeup>
    800049f6:	b7e9                	j	800049c0 <pipeclose+0x2c>
    release(&pi->lock);
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	302080e7          	jalr	770(ra) # 80000cfc <release>
}
    80004a02:	bfe1                	j	800049da <pipeclose+0x46>

0000000080004a04 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a04:	711d                	addi	sp,sp,-96
    80004a06:	ec86                	sd	ra,88(sp)
    80004a08:	e8a2                	sd	s0,80(sp)
    80004a0a:	e4a6                	sd	s1,72(sp)
    80004a0c:	e0ca                	sd	s2,64(sp)
    80004a0e:	fc4e                	sd	s3,56(sp)
    80004a10:	f852                	sd	s4,48(sp)
    80004a12:	f456                	sd	s5,40(sp)
    80004a14:	f05a                	sd	s6,32(sp)
    80004a16:	ec5e                	sd	s7,24(sp)
    80004a18:	e862                	sd	s8,16(sp)
    80004a1a:	1080                	addi	s0,sp,96
    80004a1c:	84aa                	mv	s1,a0
    80004a1e:	8aae                	mv	s5,a1
    80004a20:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	002080e7          	jalr	2(ra) # 80001a24 <myproc>
    80004a2a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	21a080e7          	jalr	538(ra) # 80000c48 <acquire>
  while(i < n){
    80004a36:	0b405663          	blez	s4,80004ae2 <pipewrite+0xde>
  int i = 0;
    80004a3a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a3c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a3e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a42:	21c48b93          	addi	s7,s1,540
    80004a46:	a089                	j	80004a88 <pipewrite+0x84>
      release(&pi->lock);
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	2b2080e7          	jalr	690(ra) # 80000cfc <release>
      return -1;
    80004a52:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a54:	854a                	mv	a0,s2
    80004a56:	60e6                	ld	ra,88(sp)
    80004a58:	6446                	ld	s0,80(sp)
    80004a5a:	64a6                	ld	s1,72(sp)
    80004a5c:	6906                	ld	s2,64(sp)
    80004a5e:	79e2                	ld	s3,56(sp)
    80004a60:	7a42                	ld	s4,48(sp)
    80004a62:	7aa2                	ld	s5,40(sp)
    80004a64:	7b02                	ld	s6,32(sp)
    80004a66:	6be2                	ld	s7,24(sp)
    80004a68:	6c42                	ld	s8,16(sp)
    80004a6a:	6125                	addi	sp,sp,96
    80004a6c:	8082                	ret
      wakeup(&pi->nread);
    80004a6e:	8562                	mv	a0,s8
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	6ee080e7          	jalr	1774(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a78:	85a6                	mv	a1,s1
    80004a7a:	855e                	mv	a0,s7
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	67e080e7          	jalr	1662(ra) # 800020fa <sleep>
  while(i < n){
    80004a84:	07495063          	bge	s2,s4,80004ae4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a88:	2204a783          	lw	a5,544(s1)
    80004a8c:	dfd5                	beqz	a5,80004a48 <pipewrite+0x44>
    80004a8e:	854e                	mv	a0,s3
    80004a90:	ffffe097          	auipc	ra,0xffffe
    80004a94:	912080e7          	jalr	-1774(ra) # 800023a2 <killed>
    80004a98:	f945                	bnez	a0,80004a48 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a9a:	2184a783          	lw	a5,536(s1)
    80004a9e:	21c4a703          	lw	a4,540(s1)
    80004aa2:	2007879b          	addiw	a5,a5,512
    80004aa6:	fcf704e3          	beq	a4,a5,80004a6e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aaa:	4685                	li	a3,1
    80004aac:	01590633          	add	a2,s2,s5
    80004ab0:	faf40593          	addi	a1,s0,-81
    80004ab4:	0509b503          	ld	a0,80(s3)
    80004ab8:	ffffd097          	auipc	ra,0xffffd
    80004abc:	cb8080e7          	jalr	-840(ra) # 80001770 <copyin>
    80004ac0:	03650263          	beq	a0,s6,80004ae4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ac4:	21c4a783          	lw	a5,540(s1)
    80004ac8:	0017871b          	addiw	a4,a5,1
    80004acc:	20e4ae23          	sw	a4,540(s1)
    80004ad0:	1ff7f793          	andi	a5,a5,511
    80004ad4:	97a6                	add	a5,a5,s1
    80004ad6:	faf44703          	lbu	a4,-81(s0)
    80004ada:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ade:	2905                	addiw	s2,s2,1
    80004ae0:	b755                	j	80004a84 <pipewrite+0x80>
  int i = 0;
    80004ae2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ae4:	21848513          	addi	a0,s1,536
    80004ae8:	ffffd097          	auipc	ra,0xffffd
    80004aec:	676080e7          	jalr	1654(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	20a080e7          	jalr	522(ra) # 80000cfc <release>
  return i;
    80004afa:	bfa9                	j	80004a54 <pipewrite+0x50>

0000000080004afc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004afc:	715d                	addi	sp,sp,-80
    80004afe:	e486                	sd	ra,72(sp)
    80004b00:	e0a2                	sd	s0,64(sp)
    80004b02:	fc26                	sd	s1,56(sp)
    80004b04:	f84a                	sd	s2,48(sp)
    80004b06:	f44e                	sd	s3,40(sp)
    80004b08:	f052                	sd	s4,32(sp)
    80004b0a:	ec56                	sd	s5,24(sp)
    80004b0c:	e85a                	sd	s6,16(sp)
    80004b0e:	0880                	addi	s0,sp,80
    80004b10:	84aa                	mv	s1,a0
    80004b12:	892e                	mv	s2,a1
    80004b14:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b16:	ffffd097          	auipc	ra,0xffffd
    80004b1a:	f0e080e7          	jalr	-242(ra) # 80001a24 <myproc>
    80004b1e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	126080e7          	jalr	294(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b2a:	2184a703          	lw	a4,536(s1)
    80004b2e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b32:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b36:	02f71763          	bne	a4,a5,80004b64 <piperead+0x68>
    80004b3a:	2244a783          	lw	a5,548(s1)
    80004b3e:	c39d                	beqz	a5,80004b64 <piperead+0x68>
    if(killed(pr)){
    80004b40:	8552                	mv	a0,s4
    80004b42:	ffffe097          	auipc	ra,0xffffe
    80004b46:	860080e7          	jalr	-1952(ra) # 800023a2 <killed>
    80004b4a:	e949                	bnez	a0,80004bdc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b4c:	85a6                	mv	a1,s1
    80004b4e:	854e                	mv	a0,s3
    80004b50:	ffffd097          	auipc	ra,0xffffd
    80004b54:	5aa080e7          	jalr	1450(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b58:	2184a703          	lw	a4,536(s1)
    80004b5c:	21c4a783          	lw	a5,540(s1)
    80004b60:	fcf70de3          	beq	a4,a5,80004b3a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b64:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b66:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b68:	05505463          	blez	s5,80004bb0 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b6c:	2184a783          	lw	a5,536(s1)
    80004b70:	21c4a703          	lw	a4,540(s1)
    80004b74:	02f70e63          	beq	a4,a5,80004bb0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b78:	0017871b          	addiw	a4,a5,1
    80004b7c:	20e4ac23          	sw	a4,536(s1)
    80004b80:	1ff7f793          	andi	a5,a5,511
    80004b84:	97a6                	add	a5,a5,s1
    80004b86:	0187c783          	lbu	a5,24(a5)
    80004b8a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b8e:	4685                	li	a3,1
    80004b90:	fbf40613          	addi	a2,s0,-65
    80004b94:	85ca                	mv	a1,s2
    80004b96:	050a3503          	ld	a0,80(s4)
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	b4a080e7          	jalr	-1206(ra) # 800016e4 <copyout>
    80004ba2:	01650763          	beq	a0,s6,80004bb0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba6:	2985                	addiw	s3,s3,1
    80004ba8:	0905                	addi	s2,s2,1
    80004baa:	fd3a91e3          	bne	s5,s3,80004b6c <piperead+0x70>
    80004bae:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bb0:	21c48513          	addi	a0,s1,540
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	5aa080e7          	jalr	1450(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	13e080e7          	jalr	318(ra) # 80000cfc <release>
  return i;
}
    80004bc6:	854e                	mv	a0,s3
    80004bc8:	60a6                	ld	ra,72(sp)
    80004bca:	6406                	ld	s0,64(sp)
    80004bcc:	74e2                	ld	s1,56(sp)
    80004bce:	7942                	ld	s2,48(sp)
    80004bd0:	79a2                	ld	s3,40(sp)
    80004bd2:	7a02                	ld	s4,32(sp)
    80004bd4:	6ae2                	ld	s5,24(sp)
    80004bd6:	6b42                	ld	s6,16(sp)
    80004bd8:	6161                	addi	sp,sp,80
    80004bda:	8082                	ret
      release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	11e080e7          	jalr	286(ra) # 80000cfc <release>
      return -1;
    80004be6:	59fd                	li	s3,-1
    80004be8:	bff9                	j	80004bc6 <piperead+0xca>

0000000080004bea <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bea:	1141                	addi	sp,sp,-16
    80004bec:	e422                	sd	s0,8(sp)
    80004bee:	0800                	addi	s0,sp,16
    80004bf0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bf2:	8905                	andi	a0,a0,1
    80004bf4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004bf6:	8b89                	andi	a5,a5,2
    80004bf8:	c399                	beqz	a5,80004bfe <flags2perm+0x14>
      perm |= PTE_W;
    80004bfa:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bfe:	6422                	ld	s0,8(sp)
    80004c00:	0141                	addi	sp,sp,16
    80004c02:	8082                	ret

0000000080004c04 <exec>:

int
exec(char *path, char **argv)
{
    80004c04:	df010113          	addi	sp,sp,-528
    80004c08:	20113423          	sd	ra,520(sp)
    80004c0c:	20813023          	sd	s0,512(sp)
    80004c10:	ffa6                	sd	s1,504(sp)
    80004c12:	fbca                	sd	s2,496(sp)
    80004c14:	f7ce                	sd	s3,488(sp)
    80004c16:	f3d2                	sd	s4,480(sp)
    80004c18:	efd6                	sd	s5,472(sp)
    80004c1a:	ebda                	sd	s6,464(sp)
    80004c1c:	e7de                	sd	s7,456(sp)
    80004c1e:	e3e2                	sd	s8,448(sp)
    80004c20:	ff66                	sd	s9,440(sp)
    80004c22:	fb6a                	sd	s10,432(sp)
    80004c24:	f76e                	sd	s11,424(sp)
    80004c26:	0c00                	addi	s0,sp,528
    80004c28:	892a                	mv	s2,a0
    80004c2a:	e0a43423          	sd	a0,-504(s0)
    80004c2e:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	df2080e7          	jalr	-526(ra) # 80001a24 <myproc>
    80004c3a:	84aa                	mv	s1,a0

  //Check if the process is a vm
  //printf("Checking for vm funciton");
  if(strncmp(path, "vm-", 3)==0)
    80004c3c:	460d                	li	a2,3
    80004c3e:	00004597          	auipc	a1,0x4
    80004c42:	5c258593          	addi	a1,a1,1474 # 80009200 <digits+0x1c0>
    80004c46:	854a                	mv	a0,s2
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	1cc080e7          	jalr	460(ra) # 80000e14 <strncmp>
    80004c50:	e501                	bnez	a0,80004c58 <exec+0x54>
  {
    p->vmprocess = true;
    80004c52:	4785                	li	a5,1
    80004c54:	16f48623          	sb	a5,364(s1)
  }
  //printf("This is good");

  begin_op();
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	472080e7          	jalr	1138(ra) # 800040ca <begin_op>

  if((ip = namei(path)) == 0){
    80004c60:	e0843503          	ld	a0,-504(s0)
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	266080e7          	jalr	614(ra) # 80003eca <namei>
    80004c6c:	8a2a                	mv	s4,a0
    80004c6e:	c925                	beqz	a0,80004cde <exec+0xda>
    end_op();
    return -1;
  }
  ilock(ip);
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	ab4080e7          	jalr	-1356(ra) # 80003724 <ilock>
//printf("Checking the elf header");
  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c78:	04000713          	li	a4,64
    80004c7c:	4681                	li	a3,0
    80004c7e:	e5040613          	addi	a2,s0,-432
    80004c82:	4581                	li	a1,0
    80004c84:	8552                	mv	a0,s4
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	d52080e7          	jalr	-686(ra) # 800039d8 <readi>
    80004c8e:	04000793          	li	a5,64
    80004c92:	00f51a63          	bne	a0,a5,80004ca6 <exec+0xa2>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c96:	e5042703          	lw	a4,-432(s0)
    80004c9a:	464c47b7          	lui	a5,0x464c4
    80004c9e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ca2:	04f70463          	beq	a4,a5,80004cea <exec+0xe6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ca6:	8552                	mv	a0,s4
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	cde080e7          	jalr	-802(ra) # 80003986 <iunlockput>
    end_op();
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	494080e7          	jalr	1172(ra) # 80004144 <end_op>
  }
  return -1;
    80004cb8:	557d                	li	a0,-1
}
    80004cba:	20813083          	ld	ra,520(sp)
    80004cbe:	20013403          	ld	s0,512(sp)
    80004cc2:	74fe                	ld	s1,504(sp)
    80004cc4:	795e                	ld	s2,496(sp)
    80004cc6:	79be                	ld	s3,488(sp)
    80004cc8:	7a1e                	ld	s4,480(sp)
    80004cca:	6afe                	ld	s5,472(sp)
    80004ccc:	6b5e                	ld	s6,464(sp)
    80004cce:	6bbe                	ld	s7,456(sp)
    80004cd0:	6c1e                	ld	s8,448(sp)
    80004cd2:	7cfa                	ld	s9,440(sp)
    80004cd4:	7d5a                	ld	s10,432(sp)
    80004cd6:	7dba                	ld	s11,424(sp)
    80004cd8:	21010113          	addi	sp,sp,528
    80004cdc:	8082                	ret
    end_op();
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	466080e7          	jalr	1126(ra) # 80004144 <end_op>
    return -1;
    80004ce6:	557d                	li	a0,-1
    80004ce8:	bfc9                	j	80004cba <exec+0xb6>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	dfc080e7          	jalr	-516(ra) # 80001ae8 <proc_pagetable>
    80004cf4:	8b2a                	mv	s6,a0
    80004cf6:	d945                	beqz	a0,80004ca6 <exec+0xa2>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf8:	e7042d03          	lw	s10,-400(s0)
    80004cfc:	e8845783          	lhu	a5,-376(s0)
    80004d00:	10078463          	beqz	a5,80004e08 <exec+0x204>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d04:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d06:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004d08:	6c85                	lui	s9,0x1
    80004d0a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d0e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004d12:	6a85                	lui	s5,0x1
    80004d14:	a0b5                	j	80004d80 <exec+0x17c>
      panic("loadseg: address should exist");
    80004d16:	00005517          	auipc	a0,0x5
    80004d1a:	9da50513          	addi	a0,a0,-1574 # 800096f0 <syscalls+0x280>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	822080e7          	jalr	-2014(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004d26:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d28:	8726                	mv	a4,s1
    80004d2a:	012c06bb          	addw	a3,s8,s2
    80004d2e:	4581                	li	a1,0
    80004d30:	8552                	mv	a0,s4
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	ca6080e7          	jalr	-858(ra) # 800039d8 <readi>
    80004d3a:	2501                	sext.w	a0,a0
    80004d3c:	2aa49963          	bne	s1,a0,80004fee <exec+0x3ea>
  for(i = 0; i < sz; i += PGSIZE){
    80004d40:	012a893b          	addw	s2,s5,s2
    80004d44:	03397563          	bgeu	s2,s3,80004d6e <exec+0x16a>
    pa = walkaddr(pagetable, va + i);
    80004d48:	02091593          	slli	a1,s2,0x20
    80004d4c:	9181                	srli	a1,a1,0x20
    80004d4e:	95de                	add	a1,a1,s7
    80004d50:	855a                	mv	a0,s6
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	382080e7          	jalr	898(ra) # 800010d4 <walkaddr>
    80004d5a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d5c:	dd4d                	beqz	a0,80004d16 <exec+0x112>
    if(sz - i < PGSIZE)
    80004d5e:	412984bb          	subw	s1,s3,s2
    80004d62:	0004879b          	sext.w	a5,s1
    80004d66:	fcfcf0e3          	bgeu	s9,a5,80004d26 <exec+0x122>
    80004d6a:	84d6                	mv	s1,s5
    80004d6c:	bf6d                	j	80004d26 <exec+0x122>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d6e:	e0043903          	ld	s2,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d72:	2d85                	addiw	s11,s11,1
    80004d74:	038d0d1b          	addiw	s10,s10,56
    80004d78:	e8845783          	lhu	a5,-376(s0)
    80004d7c:	08fdd763          	bge	s11,a5,80004e0a <exec+0x206>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d80:	2d01                	sext.w	s10,s10
    80004d82:	03800713          	li	a4,56
    80004d86:	86ea                	mv	a3,s10
    80004d88:	e1840613          	addi	a2,s0,-488
    80004d8c:	4581                	li	a1,0
    80004d8e:	8552                	mv	a0,s4
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	c48080e7          	jalr	-952(ra) # 800039d8 <readi>
    80004d98:	03800793          	li	a5,56
    80004d9c:	24f51763          	bne	a0,a5,80004fea <exec+0x3e6>
    if(ph.type != ELF_PROG_LOAD)
    80004da0:	e1842783          	lw	a5,-488(s0)
    80004da4:	4705                	li	a4,1
    80004da6:	fce796e3          	bne	a5,a4,80004d72 <exec+0x16e>
    if(ph.memsz < ph.filesz)
    80004daa:	e4043483          	ld	s1,-448(s0)
    80004dae:	e3843783          	ld	a5,-456(s0)
    80004db2:	24f4e963          	bltu	s1,a5,80005004 <exec+0x400>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004db6:	e2843783          	ld	a5,-472(s0)
    80004dba:	94be                	add	s1,s1,a5
    80004dbc:	24f4e763          	bltu	s1,a5,8000500a <exec+0x406>
    if(ph.vaddr % PGSIZE != 0)
    80004dc0:	df043703          	ld	a4,-528(s0)
    80004dc4:	8ff9                	and	a5,a5,a4
    80004dc6:	24079563          	bnez	a5,80005010 <exec+0x40c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dca:	e1c42503          	lw	a0,-484(s0)
    80004dce:	00000097          	auipc	ra,0x0
    80004dd2:	e1c080e7          	jalr	-484(ra) # 80004bea <flags2perm>
    80004dd6:	86aa                	mv	a3,a0
    80004dd8:	8626                	mv	a2,s1
    80004dda:	85ca                	mv	a1,s2
    80004ddc:	855a                	mv	a0,s6
    80004dde:	ffffc097          	auipc	ra,0xffffc
    80004de2:	6aa080e7          	jalr	1706(ra) # 80001488 <uvmalloc>
    80004de6:	e0a43023          	sd	a0,-512(s0)
    80004dea:	22050663          	beqz	a0,80005016 <exec+0x412>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004dee:	e2843b83          	ld	s7,-472(s0)
    80004df2:	e2042c03          	lw	s8,-480(s0)
    80004df6:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004dfa:	00098463          	beqz	s3,80004e02 <exec+0x1fe>
    80004dfe:	4901                	li	s2,0
    80004e00:	b7a1                	j	80004d48 <exec+0x144>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e02:	e0043903          	ld	s2,-512(s0)
    80004e06:	b7b5                	j	80004d72 <exec+0x16e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e08:	4901                	li	s2,0
  iunlockput(ip);
    80004e0a:	8552                	mv	a0,s4
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	b7a080e7          	jalr	-1158(ra) # 80003986 <iunlockput>
  end_op();
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	330080e7          	jalr	816(ra) # 80004144 <end_op>
  p = myproc();
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	c08080e7          	jalr	-1016(ra) # 80001a24 <myproc>
    80004e24:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e26:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e2a:	6985                	lui	s3,0x1
    80004e2c:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e2e:	99ca                	add	s3,s3,s2
    80004e30:	77fd                	lui	a5,0xfffff
    80004e32:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e36:	4691                	li	a3,4
    80004e38:	6609                	lui	a2,0x2
    80004e3a:	964e                	add	a2,a2,s3
    80004e3c:	85ce                	mv	a1,s3
    80004e3e:	855a                	mv	a0,s6
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	648080e7          	jalr	1608(ra) # 80001488 <uvmalloc>
    80004e48:	892a                	mv	s2,a0
    80004e4a:	e0a43023          	sd	a0,-512(s0)
    80004e4e:	e509                	bnez	a0,80004e58 <exec+0x254>
  if(pagetable)
    80004e50:	e1343023          	sd	s3,-512(s0)
    80004e54:	4a01                	li	s4,0
    80004e56:	aa61                	j	80004fee <exec+0x3ea>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e58:	75f9                	lui	a1,0xffffe
    80004e5a:	95aa                	add	a1,a1,a0
    80004e5c:	855a                	mv	a0,s6
    80004e5e:	ffffd097          	auipc	ra,0xffffd
    80004e62:	854080e7          	jalr	-1964(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e66:	7bfd                	lui	s7,0xfffff
    80004e68:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e6a:	df843783          	ld	a5,-520(s0)
    80004e6e:	6388                	ld	a0,0(a5)
    80004e70:	c52d                	beqz	a0,80004eda <exec+0x2d6>
    80004e72:	e9040993          	addi	s3,s0,-368
    80004e76:	f9040c13          	addi	s8,s0,-112
    80004e7a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	042080e7          	jalr	66(ra) # 80000ebe <strlen>
    80004e84:	0015079b          	addiw	a5,a0,1
    80004e88:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e90:	19796663          	bltu	s2,s7,8000501c <exec+0x418>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e94:	df843d03          	ld	s10,-520(s0)
    80004e98:	000d3a03          	ld	s4,0(s10)
    80004e9c:	8552                	mv	a0,s4
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	020080e7          	jalr	32(ra) # 80000ebe <strlen>
    80004ea6:	0015069b          	addiw	a3,a0,1
    80004eaa:	8652                	mv	a2,s4
    80004eac:	85ca                	mv	a1,s2
    80004eae:	855a                	mv	a0,s6
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	834080e7          	jalr	-1996(ra) # 800016e4 <copyout>
    80004eb8:	16054463          	bltz	a0,80005020 <exec+0x41c>
    ustack[argc] = sp;
    80004ebc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec0:	0485                	addi	s1,s1,1
    80004ec2:	008d0793          	addi	a5,s10,8
    80004ec6:	def43c23          	sd	a5,-520(s0)
    80004eca:	008d3503          	ld	a0,8(s10)
    80004ece:	c909                	beqz	a0,80004ee0 <exec+0x2dc>
    if(argc >= MAXARG)
    80004ed0:	09a1                	addi	s3,s3,8
    80004ed2:	fb8995e3          	bne	s3,s8,80004e7c <exec+0x278>
  ip = 0;
    80004ed6:	4a01                	li	s4,0
    80004ed8:	aa19                	j	80004fee <exec+0x3ea>
  sp = sz;
    80004eda:	e0043903          	ld	s2,-512(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ede:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee0:	00349793          	slli	a5,s1,0x3
    80004ee4:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdb870>
    80004ee8:	97a2                	add	a5,a5,s0
    80004eea:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eee:	00148693          	addi	a3,s1,1
    80004ef2:	068e                	slli	a3,a3,0x3
    80004ef4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ef8:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004efc:	e0043983          	ld	s3,-512(s0)
  if(sp < stackbase)
    80004f00:	f57968e3          	bltu	s2,s7,80004e50 <exec+0x24c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f04:	e9040613          	addi	a2,s0,-368
    80004f08:	85ca                	mv	a1,s2
    80004f0a:	855a                	mv	a0,s6
    80004f0c:	ffffc097          	auipc	ra,0xffffc
    80004f10:	7d8080e7          	jalr	2008(ra) # 800016e4 <copyout>
    80004f14:	10054863          	bltz	a0,80005024 <exec+0x420>
  p->trapframe->a1 = sp;
    80004f18:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f1c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f20:	e0843783          	ld	a5,-504(s0)
    80004f24:	0007c703          	lbu	a4,0(a5)
    80004f28:	cf11                	beqz	a4,80004f44 <exec+0x340>
    80004f2a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f2c:	02f00693          	li	a3,47
    80004f30:	a039                	j	80004f3e <exec+0x33a>
      last = s+1;
    80004f32:	e0f43423          	sd	a5,-504(s0)
  for(last=s=path; *s; s++)
    80004f36:	0785                	addi	a5,a5,1
    80004f38:	fff7c703          	lbu	a4,-1(a5)
    80004f3c:	c701                	beqz	a4,80004f44 <exec+0x340>
    if(*s == '/')
    80004f3e:	fed71ce3          	bne	a4,a3,80004f36 <exec+0x332>
    80004f42:	bfc5                	j	80004f32 <exec+0x32e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f44:	158a8993          	addi	s3,s5,344
    80004f48:	4641                	li	a2,16
    80004f4a:	e0843583          	ld	a1,-504(s0)
    80004f4e:	854e                	mv	a0,s3
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	f3c080e7          	jalr	-196(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f58:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f5c:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f60:	e0043783          	ld	a5,-512(s0)
    80004f64:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f68:	058ab783          	ld	a5,88(s5)
    80004f6c:	e6843703          	ld	a4,-408(s0)
    80004f70:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f7a:	85e6                	mv	a1,s9
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	c08080e7          	jalr	-1016(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004f84:	460d                	li	a2,3
    80004f86:	00004597          	auipc	a1,0x4
    80004f8a:	27a58593          	addi	a1,a1,634 # 80009200 <digits+0x1c0>
    80004f8e:	854e                	mv	a0,s3
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	e84080e7          	jalr	-380(ra) # 80000e14 <strncmp>
    80004f98:	c501                	beqz	a0,80004fa0 <exec+0x39c>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f9a:	0004851b          	sext.w	a0,s1
    80004f9e:	bb31                	j	80004cba <exec+0xb6>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004fa0:	4691                	li	a3,4
    80004fa2:	20100613          	li	a2,513
    80004fa6:	065a                	slli	a2,a2,0x16
    80004fa8:	4585                	li	a1,1
    80004faa:	05fe                	slli	a1,a1,0x1f
    80004fac:	855a                	mv	a0,s6
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	4da080e7          	jalr	1242(ra) # 80001488 <uvmalloc>
    80004fb6:	cd19                	beqz	a0,80004fd4 <exec+0x3d0>
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004fb8:	20100613          	li	a2,513
    80004fbc:	065a                	slli	a2,a2,0x16
    80004fbe:	4585                	li	a1,1
    80004fc0:	05fe                	slli	a1,a1,0x1f
    80004fc2:	00004517          	auipc	a0,0x4
    80004fc6:	78650513          	addi	a0,a0,1926 # 80009748 <syscalls+0x2d8>
    80004fca:	ffffb097          	auipc	ra,0xffffb
    80004fce:	5c0080e7          	jalr	1472(ra) # 8000058a <printf>
    80004fd2:	b7e1                	j	80004f9a <exec+0x396>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004fd4:	00004517          	auipc	a0,0x4
    80004fd8:	73c50513          	addi	a0,a0,1852 # 80009710 <syscalls+0x2a0>
    80004fdc:	ffffb097          	auipc	ra,0xffffb
    80004fe0:	5ae080e7          	jalr	1454(ra) # 8000058a <printf>
  sz = sz1;
    80004fe4:	e0043983          	ld	s3,-512(s0)
      goto bad;
    80004fe8:	b5a5                	j	80004e50 <exec+0x24c>
    80004fea:	e1243023          	sd	s2,-512(s0)
    proc_freepagetable(pagetable, sz);
    80004fee:	e0043583          	ld	a1,-512(s0)
    80004ff2:	855a                	mv	a0,s6
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	b90080e7          	jalr	-1136(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80004ffc:	557d                	li	a0,-1
  if(ip){
    80004ffe:	ca0a0ee3          	beqz	s4,80004cba <exec+0xb6>
    80005002:	b155                	j	80004ca6 <exec+0xa2>
    80005004:	e1243023          	sd	s2,-512(s0)
    80005008:	b7dd                	j	80004fee <exec+0x3ea>
    8000500a:	e1243023          	sd	s2,-512(s0)
    8000500e:	b7c5                	j	80004fee <exec+0x3ea>
    80005010:	e1243023          	sd	s2,-512(s0)
    80005014:	bfe9                	j	80004fee <exec+0x3ea>
    80005016:	e1243023          	sd	s2,-512(s0)
    8000501a:	bfd1                	j	80004fee <exec+0x3ea>
  ip = 0;
    8000501c:	4a01                	li	s4,0
    8000501e:	bfc1                	j	80004fee <exec+0x3ea>
    80005020:	4a01                	li	s4,0
  if(pagetable)
    80005022:	b7f1                	j	80004fee <exec+0x3ea>
  sz = sz1;
    80005024:	e0043983          	ld	s3,-512(s0)
    80005028:	b525                	j	80004e50 <exec+0x24c>

000000008000502a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000502a:	7179                	addi	sp,sp,-48
    8000502c:	f406                	sd	ra,40(sp)
    8000502e:	f022                	sd	s0,32(sp)
    80005030:	ec26                	sd	s1,24(sp)
    80005032:	e84a                	sd	s2,16(sp)
    80005034:	1800                	addi	s0,sp,48
    80005036:	892e                	mv	s2,a1
    80005038:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000503a:	fdc40593          	addi	a1,s0,-36
    8000503e:	ffffe097          	auipc	ra,0xffffe
    80005042:	b84080e7          	jalr	-1148(ra) # 80002bc2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005046:	fdc42703          	lw	a4,-36(s0)
    8000504a:	47bd                	li	a5,15
    8000504c:	02e7eb63          	bltu	a5,a4,80005082 <argfd+0x58>
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	9d4080e7          	jalr	-1580(ra) # 80001a24 <myproc>
    80005058:	fdc42703          	lw	a4,-36(s0)
    8000505c:	01a70793          	addi	a5,a4,26
    80005060:	078e                	slli	a5,a5,0x3
    80005062:	953e                	add	a0,a0,a5
    80005064:	611c                	ld	a5,0(a0)
    80005066:	c385                	beqz	a5,80005086 <argfd+0x5c>
    return -1;
  if(pfd)
    80005068:	00090463          	beqz	s2,80005070 <argfd+0x46>
    *pfd = fd;
    8000506c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005070:	4501                	li	a0,0
  if(pf)
    80005072:	c091                	beqz	s1,80005076 <argfd+0x4c>
    *pf = f;
    80005074:	e09c                	sd	a5,0(s1)
}
    80005076:	70a2                	ld	ra,40(sp)
    80005078:	7402                	ld	s0,32(sp)
    8000507a:	64e2                	ld	s1,24(sp)
    8000507c:	6942                	ld	s2,16(sp)
    8000507e:	6145                	addi	sp,sp,48
    80005080:	8082                	ret
    return -1;
    80005082:	557d                	li	a0,-1
    80005084:	bfcd                	j	80005076 <argfd+0x4c>
    80005086:	557d                	li	a0,-1
    80005088:	b7fd                	j	80005076 <argfd+0x4c>

000000008000508a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000508a:	1101                	addi	sp,sp,-32
    8000508c:	ec06                	sd	ra,24(sp)
    8000508e:	e822                	sd	s0,16(sp)
    80005090:	e426                	sd	s1,8(sp)
    80005092:	1000                	addi	s0,sp,32
    80005094:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	98e080e7          	jalr	-1650(ra) # 80001a24 <myproc>
    8000509e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050a0:	0d050793          	addi	a5,a0,208
    800050a4:	4501                	li	a0,0
    800050a6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050a8:	6398                	ld	a4,0(a5)
    800050aa:	cb19                	beqz	a4,800050c0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050ac:	2505                	addiw	a0,a0,1
    800050ae:	07a1                	addi	a5,a5,8
    800050b0:	fed51ce3          	bne	a0,a3,800050a8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050b4:	557d                	li	a0,-1
}
    800050b6:	60e2                	ld	ra,24(sp)
    800050b8:	6442                	ld	s0,16(sp)
    800050ba:	64a2                	ld	s1,8(sp)
    800050bc:	6105                	addi	sp,sp,32
    800050be:	8082                	ret
      p->ofile[fd] = f;
    800050c0:	01a50793          	addi	a5,a0,26
    800050c4:	078e                	slli	a5,a5,0x3
    800050c6:	963e                	add	a2,a2,a5
    800050c8:	e204                	sd	s1,0(a2)
      return fd;
    800050ca:	b7f5                	j	800050b6 <fdalloc+0x2c>

00000000800050cc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050cc:	715d                	addi	sp,sp,-80
    800050ce:	e486                	sd	ra,72(sp)
    800050d0:	e0a2                	sd	s0,64(sp)
    800050d2:	fc26                	sd	s1,56(sp)
    800050d4:	f84a                	sd	s2,48(sp)
    800050d6:	f44e                	sd	s3,40(sp)
    800050d8:	f052                	sd	s4,32(sp)
    800050da:	ec56                	sd	s5,24(sp)
    800050dc:	e85a                	sd	s6,16(sp)
    800050de:	0880                	addi	s0,sp,80
    800050e0:	8b2e                	mv	s6,a1
    800050e2:	89b2                	mv	s3,a2
    800050e4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050e6:	fb040593          	addi	a1,s0,-80
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	dfe080e7          	jalr	-514(ra) # 80003ee8 <nameiparent>
    800050f2:	84aa                	mv	s1,a0
    800050f4:	14050b63          	beqz	a0,8000524a <create+0x17e>
    return 0;

  ilock(dp);
    800050f8:	ffffe097          	auipc	ra,0xffffe
    800050fc:	62c080e7          	jalr	1580(ra) # 80003724 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005100:	4601                	li	a2,0
    80005102:	fb040593          	addi	a1,s0,-80
    80005106:	8526                	mv	a0,s1
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	b00080e7          	jalr	-1280(ra) # 80003c08 <dirlookup>
    80005110:	8aaa                	mv	s5,a0
    80005112:	c921                	beqz	a0,80005162 <create+0x96>
    iunlockput(dp);
    80005114:	8526                	mv	a0,s1
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	870080e7          	jalr	-1936(ra) # 80003986 <iunlockput>
    ilock(ip);
    8000511e:	8556                	mv	a0,s5
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	604080e7          	jalr	1540(ra) # 80003724 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005128:	4789                	li	a5,2
    8000512a:	02fb1563          	bne	s6,a5,80005154 <create+0x88>
    8000512e:	044ad783          	lhu	a5,68(s5)
    80005132:	37f9                	addiw	a5,a5,-2
    80005134:	17c2                	slli	a5,a5,0x30
    80005136:	93c1                	srli	a5,a5,0x30
    80005138:	4705                	li	a4,1
    8000513a:	00f76d63          	bltu	a4,a5,80005154 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000513e:	8556                	mv	a0,s5
    80005140:	60a6                	ld	ra,72(sp)
    80005142:	6406                	ld	s0,64(sp)
    80005144:	74e2                	ld	s1,56(sp)
    80005146:	7942                	ld	s2,48(sp)
    80005148:	79a2                	ld	s3,40(sp)
    8000514a:	7a02                	ld	s4,32(sp)
    8000514c:	6ae2                	ld	s5,24(sp)
    8000514e:	6b42                	ld	s6,16(sp)
    80005150:	6161                	addi	sp,sp,80
    80005152:	8082                	ret
    iunlockput(ip);
    80005154:	8556                	mv	a0,s5
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	830080e7          	jalr	-2000(ra) # 80003986 <iunlockput>
    return 0;
    8000515e:	4a81                	li	s5,0
    80005160:	bff9                	j	8000513e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005162:	85da                	mv	a1,s6
    80005164:	4088                	lw	a0,0(s1)
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	426080e7          	jalr	1062(ra) # 8000358c <ialloc>
    8000516e:	8a2a                	mv	s4,a0
    80005170:	c529                	beqz	a0,800051ba <create+0xee>
  ilock(ip);
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	5b2080e7          	jalr	1458(ra) # 80003724 <ilock>
  ip->major = major;
    8000517a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000517e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005182:	4905                	li	s2,1
    80005184:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005188:	8552                	mv	a0,s4
    8000518a:	ffffe097          	auipc	ra,0xffffe
    8000518e:	4ce080e7          	jalr	1230(ra) # 80003658 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005192:	032b0b63          	beq	s6,s2,800051c8 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005196:	004a2603          	lw	a2,4(s4)
    8000519a:	fb040593          	addi	a1,s0,-80
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	c78080e7          	jalr	-904(ra) # 80003e18 <dirlink>
    800051a8:	06054f63          	bltz	a0,80005226 <create+0x15a>
  iunlockput(dp);
    800051ac:	8526                	mv	a0,s1
    800051ae:	ffffe097          	auipc	ra,0xffffe
    800051b2:	7d8080e7          	jalr	2008(ra) # 80003986 <iunlockput>
  return ip;
    800051b6:	8ad2                	mv	s5,s4
    800051b8:	b759                	j	8000513e <create+0x72>
    iunlockput(dp);
    800051ba:	8526                	mv	a0,s1
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	7ca080e7          	jalr	1994(ra) # 80003986 <iunlockput>
    return 0;
    800051c4:	8ad2                	mv	s5,s4
    800051c6:	bfa5                	j	8000513e <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c8:	004a2603          	lw	a2,4(s4)
    800051cc:	00004597          	auipc	a1,0x4
    800051d0:	5bc58593          	addi	a1,a1,1468 # 80009788 <syscalls+0x318>
    800051d4:	8552                	mv	a0,s4
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	c42080e7          	jalr	-958(ra) # 80003e18 <dirlink>
    800051de:	04054463          	bltz	a0,80005226 <create+0x15a>
    800051e2:	40d0                	lw	a2,4(s1)
    800051e4:	00004597          	auipc	a1,0x4
    800051e8:	5ac58593          	addi	a1,a1,1452 # 80009790 <syscalls+0x320>
    800051ec:	8552                	mv	a0,s4
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	c2a080e7          	jalr	-982(ra) # 80003e18 <dirlink>
    800051f6:	02054863          	bltz	a0,80005226 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051fa:	004a2603          	lw	a2,4(s4)
    800051fe:	fb040593          	addi	a1,s0,-80
    80005202:	8526                	mv	a0,s1
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	c14080e7          	jalr	-1004(ra) # 80003e18 <dirlink>
    8000520c:	00054d63          	bltz	a0,80005226 <create+0x15a>
    dp->nlink++;  // for ".."
    80005210:	04a4d783          	lhu	a5,74(s1)
    80005214:	2785                	addiw	a5,a5,1
    80005216:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	43c080e7          	jalr	1084(ra) # 80003658 <iupdate>
    80005224:	b761                	j	800051ac <create+0xe0>
  ip->nlink = 0;
    80005226:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000522a:	8552                	mv	a0,s4
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	42c080e7          	jalr	1068(ra) # 80003658 <iupdate>
  iunlockput(ip);
    80005234:	8552                	mv	a0,s4
    80005236:	ffffe097          	auipc	ra,0xffffe
    8000523a:	750080e7          	jalr	1872(ra) # 80003986 <iunlockput>
  iunlockput(dp);
    8000523e:	8526                	mv	a0,s1
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	746080e7          	jalr	1862(ra) # 80003986 <iunlockput>
  return 0;
    80005248:	bddd                	j	8000513e <create+0x72>
    return 0;
    8000524a:	8aaa                	mv	s5,a0
    8000524c:	bdcd                	j	8000513e <create+0x72>

000000008000524e <sys_dup>:
{
    8000524e:	7179                	addi	sp,sp,-48
    80005250:	f406                	sd	ra,40(sp)
    80005252:	f022                	sd	s0,32(sp)
    80005254:	ec26                	sd	s1,24(sp)
    80005256:	e84a                	sd	s2,16(sp)
    80005258:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000525a:	fd840613          	addi	a2,s0,-40
    8000525e:	4581                	li	a1,0
    80005260:	4501                	li	a0,0
    80005262:	00000097          	auipc	ra,0x0
    80005266:	dc8080e7          	jalr	-568(ra) # 8000502a <argfd>
    return -1;
    8000526a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000526c:	02054363          	bltz	a0,80005292 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005270:	fd843903          	ld	s2,-40(s0)
    80005274:	854a                	mv	a0,s2
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	e14080e7          	jalr	-492(ra) # 8000508a <fdalloc>
    8000527e:	84aa                	mv	s1,a0
    return -1;
    80005280:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005282:	00054863          	bltz	a0,80005292 <sys_dup+0x44>
  filedup(f);
    80005286:	854a                	mv	a0,s2
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	2b4080e7          	jalr	692(ra) # 8000453c <filedup>
  return fd;
    80005290:	87a6                	mv	a5,s1
}
    80005292:	853e                	mv	a0,a5
    80005294:	70a2                	ld	ra,40(sp)
    80005296:	7402                	ld	s0,32(sp)
    80005298:	64e2                	ld	s1,24(sp)
    8000529a:	6942                	ld	s2,16(sp)
    8000529c:	6145                	addi	sp,sp,48
    8000529e:	8082                	ret

00000000800052a0 <sys_read>:
{
    800052a0:	7179                	addi	sp,sp,-48
    800052a2:	f406                	sd	ra,40(sp)
    800052a4:	f022                	sd	s0,32(sp)
    800052a6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052a8:	fd840593          	addi	a1,s0,-40
    800052ac:	4505                	li	a0,1
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	934080e7          	jalr	-1740(ra) # 80002be2 <argaddr>
  argint(2, &n);
    800052b6:	fe440593          	addi	a1,s0,-28
    800052ba:	4509                	li	a0,2
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	906080e7          	jalr	-1786(ra) # 80002bc2 <argint>
  if(argfd(0, 0, &f) < 0)
    800052c4:	fe840613          	addi	a2,s0,-24
    800052c8:	4581                	li	a1,0
    800052ca:	4501                	li	a0,0
    800052cc:	00000097          	auipc	ra,0x0
    800052d0:	d5e080e7          	jalr	-674(ra) # 8000502a <argfd>
    800052d4:	87aa                	mv	a5,a0
    return -1;
    800052d6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052d8:	0007cc63          	bltz	a5,800052f0 <sys_read+0x50>
  return fileread(f, p, n);
    800052dc:	fe442603          	lw	a2,-28(s0)
    800052e0:	fd843583          	ld	a1,-40(s0)
    800052e4:	fe843503          	ld	a0,-24(s0)
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	3e0080e7          	jalr	992(ra) # 800046c8 <fileread>
}
    800052f0:	70a2                	ld	ra,40(sp)
    800052f2:	7402                	ld	s0,32(sp)
    800052f4:	6145                	addi	sp,sp,48
    800052f6:	8082                	ret

00000000800052f8 <sys_write>:
{
    800052f8:	7179                	addi	sp,sp,-48
    800052fa:	f406                	sd	ra,40(sp)
    800052fc:	f022                	sd	s0,32(sp)
    800052fe:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005300:	fd840593          	addi	a1,s0,-40
    80005304:	4505                	li	a0,1
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	8dc080e7          	jalr	-1828(ra) # 80002be2 <argaddr>
  argint(2, &n);
    8000530e:	fe440593          	addi	a1,s0,-28
    80005312:	4509                	li	a0,2
    80005314:	ffffe097          	auipc	ra,0xffffe
    80005318:	8ae080e7          	jalr	-1874(ra) # 80002bc2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000531c:	fe840613          	addi	a2,s0,-24
    80005320:	4581                	li	a1,0
    80005322:	4501                	li	a0,0
    80005324:	00000097          	auipc	ra,0x0
    80005328:	d06080e7          	jalr	-762(ra) # 8000502a <argfd>
    8000532c:	87aa                	mv	a5,a0
    return -1;
    8000532e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005330:	0007cc63          	bltz	a5,80005348 <sys_write+0x50>
  return filewrite(f, p, n);
    80005334:	fe442603          	lw	a2,-28(s0)
    80005338:	fd843583          	ld	a1,-40(s0)
    8000533c:	fe843503          	ld	a0,-24(s0)
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	44a080e7          	jalr	1098(ra) # 8000478a <filewrite>
}
    80005348:	70a2                	ld	ra,40(sp)
    8000534a:	7402                	ld	s0,32(sp)
    8000534c:	6145                	addi	sp,sp,48
    8000534e:	8082                	ret

0000000080005350 <sys_close>:
{
    80005350:	1101                	addi	sp,sp,-32
    80005352:	ec06                	sd	ra,24(sp)
    80005354:	e822                	sd	s0,16(sp)
    80005356:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005358:	fe040613          	addi	a2,s0,-32
    8000535c:	fec40593          	addi	a1,s0,-20
    80005360:	4501                	li	a0,0
    80005362:	00000097          	auipc	ra,0x0
    80005366:	cc8080e7          	jalr	-824(ra) # 8000502a <argfd>
    return -1;
    8000536a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000536c:	02054463          	bltz	a0,80005394 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005370:	ffffc097          	auipc	ra,0xffffc
    80005374:	6b4080e7          	jalr	1716(ra) # 80001a24 <myproc>
    80005378:	fec42783          	lw	a5,-20(s0)
    8000537c:	07e9                	addi	a5,a5,26
    8000537e:	078e                	slli	a5,a5,0x3
    80005380:	953e                	add	a0,a0,a5
    80005382:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005386:	fe043503          	ld	a0,-32(s0)
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	204080e7          	jalr	516(ra) # 8000458e <fileclose>
  return 0;
    80005392:	4781                	li	a5,0
}
    80005394:	853e                	mv	a0,a5
    80005396:	60e2                	ld	ra,24(sp)
    80005398:	6442                	ld	s0,16(sp)
    8000539a:	6105                	addi	sp,sp,32
    8000539c:	8082                	ret

000000008000539e <sys_fstat>:
{
    8000539e:	1101                	addi	sp,sp,-32
    800053a0:	ec06                	sd	ra,24(sp)
    800053a2:	e822                	sd	s0,16(sp)
    800053a4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053a6:	fe040593          	addi	a1,s0,-32
    800053aa:	4505                	li	a0,1
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	836080e7          	jalr	-1994(ra) # 80002be2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053b4:	fe840613          	addi	a2,s0,-24
    800053b8:	4581                	li	a1,0
    800053ba:	4501                	li	a0,0
    800053bc:	00000097          	auipc	ra,0x0
    800053c0:	c6e080e7          	jalr	-914(ra) # 8000502a <argfd>
    800053c4:	87aa                	mv	a5,a0
    return -1;
    800053c6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053c8:	0007ca63          	bltz	a5,800053dc <sys_fstat+0x3e>
  return filestat(f, st);
    800053cc:	fe043583          	ld	a1,-32(s0)
    800053d0:	fe843503          	ld	a0,-24(s0)
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	282080e7          	jalr	642(ra) # 80004656 <filestat>
}
    800053dc:	60e2                	ld	ra,24(sp)
    800053de:	6442                	ld	s0,16(sp)
    800053e0:	6105                	addi	sp,sp,32
    800053e2:	8082                	ret

00000000800053e4 <sys_link>:
{
    800053e4:	7169                	addi	sp,sp,-304
    800053e6:	f606                	sd	ra,296(sp)
    800053e8:	f222                	sd	s0,288(sp)
    800053ea:	ee26                	sd	s1,280(sp)
    800053ec:	ea4a                	sd	s2,272(sp)
    800053ee:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f0:	08000613          	li	a2,128
    800053f4:	ed040593          	addi	a1,s0,-304
    800053f8:	4501                	li	a0,0
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	808080e7          	jalr	-2040(ra) # 80002c02 <argstr>
    return -1;
    80005402:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005404:	10054e63          	bltz	a0,80005520 <sys_link+0x13c>
    80005408:	08000613          	li	a2,128
    8000540c:	f5040593          	addi	a1,s0,-176
    80005410:	4505                	li	a0,1
    80005412:	ffffd097          	auipc	ra,0xffffd
    80005416:	7f0080e7          	jalr	2032(ra) # 80002c02 <argstr>
    return -1;
    8000541a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541c:	10054263          	bltz	a0,80005520 <sys_link+0x13c>
  begin_op();
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	caa080e7          	jalr	-854(ra) # 800040ca <begin_op>
  if((ip = namei(old)) == 0){
    80005428:	ed040513          	addi	a0,s0,-304
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	a9e080e7          	jalr	-1378(ra) # 80003eca <namei>
    80005434:	84aa                	mv	s1,a0
    80005436:	c551                	beqz	a0,800054c2 <sys_link+0xde>
  ilock(ip);
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	2ec080e7          	jalr	748(ra) # 80003724 <ilock>
  if(ip->type == T_DIR){
    80005440:	04449703          	lh	a4,68(s1)
    80005444:	4785                	li	a5,1
    80005446:	08f70463          	beq	a4,a5,800054ce <sys_link+0xea>
  ip->nlink++;
    8000544a:	04a4d783          	lhu	a5,74(s1)
    8000544e:	2785                	addiw	a5,a5,1
    80005450:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	202080e7          	jalr	514(ra) # 80003658 <iupdate>
  iunlock(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	386080e7          	jalr	902(ra) # 800037e6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005468:	fd040593          	addi	a1,s0,-48
    8000546c:	f5040513          	addi	a0,s0,-176
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	a78080e7          	jalr	-1416(ra) # 80003ee8 <nameiparent>
    80005478:	892a                	mv	s2,a0
    8000547a:	c935                	beqz	a0,800054ee <sys_link+0x10a>
  ilock(dp);
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	2a8080e7          	jalr	680(ra) # 80003724 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005484:	00092703          	lw	a4,0(s2)
    80005488:	409c                	lw	a5,0(s1)
    8000548a:	04f71d63          	bne	a4,a5,800054e4 <sys_link+0x100>
    8000548e:	40d0                	lw	a2,4(s1)
    80005490:	fd040593          	addi	a1,s0,-48
    80005494:	854a                	mv	a0,s2
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	982080e7          	jalr	-1662(ra) # 80003e18 <dirlink>
    8000549e:	04054363          	bltz	a0,800054e4 <sys_link+0x100>
  iunlockput(dp);
    800054a2:	854a                	mv	a0,s2
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	4e2080e7          	jalr	1250(ra) # 80003986 <iunlockput>
  iput(ip);
    800054ac:	8526                	mv	a0,s1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	430080e7          	jalr	1072(ra) # 800038de <iput>
  end_op();
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	c8e080e7          	jalr	-882(ra) # 80004144 <end_op>
  return 0;
    800054be:	4781                	li	a5,0
    800054c0:	a085                	j	80005520 <sys_link+0x13c>
    end_op();
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	c82080e7          	jalr	-894(ra) # 80004144 <end_op>
    return -1;
    800054ca:	57fd                	li	a5,-1
    800054cc:	a891                	j	80005520 <sys_link+0x13c>
    iunlockput(ip);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	4b6080e7          	jalr	1206(ra) # 80003986 <iunlockput>
    end_op();
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	c6c080e7          	jalr	-916(ra) # 80004144 <end_op>
    return -1;
    800054e0:	57fd                	li	a5,-1
    800054e2:	a83d                	j	80005520 <sys_link+0x13c>
    iunlockput(dp);
    800054e4:	854a                	mv	a0,s2
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	4a0080e7          	jalr	1184(ra) # 80003986 <iunlockput>
  ilock(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	234080e7          	jalr	564(ra) # 80003724 <ilock>
  ip->nlink--;
    800054f8:	04a4d783          	lhu	a5,74(s1)
    800054fc:	37fd                	addiw	a5,a5,-1
    800054fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	154080e7          	jalr	340(ra) # 80003658 <iupdate>
  iunlockput(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	478080e7          	jalr	1144(ra) # 80003986 <iunlockput>
  end_op();
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	c2e080e7          	jalr	-978(ra) # 80004144 <end_op>
  return -1;
    8000551e:	57fd                	li	a5,-1
}
    80005520:	853e                	mv	a0,a5
    80005522:	70b2                	ld	ra,296(sp)
    80005524:	7412                	ld	s0,288(sp)
    80005526:	64f2                	ld	s1,280(sp)
    80005528:	6952                	ld	s2,272(sp)
    8000552a:	6155                	addi	sp,sp,304
    8000552c:	8082                	ret

000000008000552e <sys_unlink>:
{
    8000552e:	7151                	addi	sp,sp,-240
    80005530:	f586                	sd	ra,232(sp)
    80005532:	f1a2                	sd	s0,224(sp)
    80005534:	eda6                	sd	s1,216(sp)
    80005536:	e9ca                	sd	s2,208(sp)
    80005538:	e5ce                	sd	s3,200(sp)
    8000553a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000553c:	08000613          	li	a2,128
    80005540:	f3040593          	addi	a1,s0,-208
    80005544:	4501                	li	a0,0
    80005546:	ffffd097          	auipc	ra,0xffffd
    8000554a:	6bc080e7          	jalr	1724(ra) # 80002c02 <argstr>
    8000554e:	18054163          	bltz	a0,800056d0 <sys_unlink+0x1a2>
  begin_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	b78080e7          	jalr	-1160(ra) # 800040ca <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000555a:	fb040593          	addi	a1,s0,-80
    8000555e:	f3040513          	addi	a0,s0,-208
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	986080e7          	jalr	-1658(ra) # 80003ee8 <nameiparent>
    8000556a:	84aa                	mv	s1,a0
    8000556c:	c979                	beqz	a0,80005642 <sys_unlink+0x114>
  ilock(dp);
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	1b6080e7          	jalr	438(ra) # 80003724 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005576:	00004597          	auipc	a1,0x4
    8000557a:	21258593          	addi	a1,a1,530 # 80009788 <syscalls+0x318>
    8000557e:	fb040513          	addi	a0,s0,-80
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	66c080e7          	jalr	1644(ra) # 80003bee <namecmp>
    8000558a:	14050a63          	beqz	a0,800056de <sys_unlink+0x1b0>
    8000558e:	00004597          	auipc	a1,0x4
    80005592:	20258593          	addi	a1,a1,514 # 80009790 <syscalls+0x320>
    80005596:	fb040513          	addi	a0,s0,-80
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	654080e7          	jalr	1620(ra) # 80003bee <namecmp>
    800055a2:	12050e63          	beqz	a0,800056de <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a6:	f2c40613          	addi	a2,s0,-212
    800055aa:	fb040593          	addi	a1,s0,-80
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	658080e7          	jalr	1624(ra) # 80003c08 <dirlookup>
    800055b8:	892a                	mv	s2,a0
    800055ba:	12050263          	beqz	a0,800056de <sys_unlink+0x1b0>
  ilock(ip);
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	166080e7          	jalr	358(ra) # 80003724 <ilock>
  if(ip->nlink < 1)
    800055c6:	04a91783          	lh	a5,74(s2)
    800055ca:	08f05263          	blez	a5,8000564e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ce:	04491703          	lh	a4,68(s2)
    800055d2:	4785                	li	a5,1
    800055d4:	08f70563          	beq	a4,a5,8000565e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d8:	4641                	li	a2,16
    800055da:	4581                	li	a1,0
    800055dc:	fc040513          	addi	a0,s0,-64
    800055e0:	ffffb097          	auipc	ra,0xffffb
    800055e4:	764080e7          	jalr	1892(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e8:	4741                	li	a4,16
    800055ea:	f2c42683          	lw	a3,-212(s0)
    800055ee:	fc040613          	addi	a2,s0,-64
    800055f2:	4581                	li	a1,0
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	4da080e7          	jalr	1242(ra) # 80003ad0 <writei>
    800055fe:	47c1                	li	a5,16
    80005600:	0af51563          	bne	a0,a5,800056aa <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005604:	04491703          	lh	a4,68(s2)
    80005608:	4785                	li	a5,1
    8000560a:	0af70863          	beq	a4,a5,800056ba <sys_unlink+0x18c>
  iunlockput(dp);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	376080e7          	jalr	886(ra) # 80003986 <iunlockput>
  ip->nlink--;
    80005618:	04a95783          	lhu	a5,74(s2)
    8000561c:	37fd                	addiw	a5,a5,-1
    8000561e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005622:	854a                	mv	a0,s2
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	034080e7          	jalr	52(ra) # 80003658 <iupdate>
  iunlockput(ip);
    8000562c:	854a                	mv	a0,s2
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	358080e7          	jalr	856(ra) # 80003986 <iunlockput>
  end_op();
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	b0e080e7          	jalr	-1266(ra) # 80004144 <end_op>
  return 0;
    8000563e:	4501                	li	a0,0
    80005640:	a84d                	j	800056f2 <sys_unlink+0x1c4>
    end_op();
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	b02080e7          	jalr	-1278(ra) # 80004144 <end_op>
    return -1;
    8000564a:	557d                	li	a0,-1
    8000564c:	a05d                	j	800056f2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000564e:	00004517          	auipc	a0,0x4
    80005652:	14a50513          	addi	a0,a0,330 # 80009798 <syscalls+0x328>
    80005656:	ffffb097          	auipc	ra,0xffffb
    8000565a:	eea080e7          	jalr	-278(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565e:	04c92703          	lw	a4,76(s2)
    80005662:	02000793          	li	a5,32
    80005666:	f6e7f9e3          	bgeu	a5,a4,800055d8 <sys_unlink+0xaa>
    8000566a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566e:	4741                	li	a4,16
    80005670:	86ce                	mv	a3,s3
    80005672:	f1840613          	addi	a2,s0,-232
    80005676:	4581                	li	a1,0
    80005678:	854a                	mv	a0,s2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	35e080e7          	jalr	862(ra) # 800039d8 <readi>
    80005682:	47c1                	li	a5,16
    80005684:	00f51b63          	bne	a0,a5,8000569a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005688:	f1845783          	lhu	a5,-232(s0)
    8000568c:	e7a1                	bnez	a5,800056d4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568e:	29c1                	addiw	s3,s3,16
    80005690:	04c92783          	lw	a5,76(s2)
    80005694:	fcf9ede3          	bltu	s3,a5,8000566e <sys_unlink+0x140>
    80005698:	b781                	j	800055d8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000569a:	00004517          	auipc	a0,0x4
    8000569e:	11650513          	addi	a0,a0,278 # 800097b0 <syscalls+0x340>
    800056a2:	ffffb097          	auipc	ra,0xffffb
    800056a6:	e9e080e7          	jalr	-354(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056aa:	00004517          	auipc	a0,0x4
    800056ae:	11e50513          	addi	a0,a0,286 # 800097c8 <syscalls+0x358>
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	e8e080e7          	jalr	-370(ra) # 80000540 <panic>
    dp->nlink--;
    800056ba:	04a4d783          	lhu	a5,74(s1)
    800056be:	37fd                	addiw	a5,a5,-1
    800056c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	f92080e7          	jalr	-110(ra) # 80003658 <iupdate>
    800056ce:	b781                	j	8000560e <sys_unlink+0xe0>
    return -1;
    800056d0:	557d                	li	a0,-1
    800056d2:	a005                	j	800056f2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d4:	854a                	mv	a0,s2
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	2b0080e7          	jalr	688(ra) # 80003986 <iunlockput>
  iunlockput(dp);
    800056de:	8526                	mv	a0,s1
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	2a6080e7          	jalr	678(ra) # 80003986 <iunlockput>
  end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	a5c080e7          	jalr	-1444(ra) # 80004144 <end_op>
  return -1;
    800056f0:	557d                	li	a0,-1
}
    800056f2:	70ae                	ld	ra,232(sp)
    800056f4:	740e                	ld	s0,224(sp)
    800056f6:	64ee                	ld	s1,216(sp)
    800056f8:	694e                	ld	s2,208(sp)
    800056fa:	69ae                	ld	s3,200(sp)
    800056fc:	616d                	addi	sp,sp,240
    800056fe:	8082                	ret

0000000080005700 <sys_open>:

uint64
sys_open(void)
{
    80005700:	7131                	addi	sp,sp,-192
    80005702:	fd06                	sd	ra,184(sp)
    80005704:	f922                	sd	s0,176(sp)
    80005706:	f526                	sd	s1,168(sp)
    80005708:	f14a                	sd	s2,160(sp)
    8000570a:	ed4e                	sd	s3,152(sp)
    8000570c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000570e:	f4c40593          	addi	a1,s0,-180
    80005712:	4505                	li	a0,1
    80005714:	ffffd097          	auipc	ra,0xffffd
    80005718:	4ae080e7          	jalr	1198(ra) # 80002bc2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000571c:	08000613          	li	a2,128
    80005720:	f5040593          	addi	a1,s0,-176
    80005724:	4501                	li	a0,0
    80005726:	ffffd097          	auipc	ra,0xffffd
    8000572a:	4dc080e7          	jalr	1244(ra) # 80002c02 <argstr>
    8000572e:	87aa                	mv	a5,a0
    return -1;
    80005730:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005732:	0a07c863          	bltz	a5,800057e2 <sys_open+0xe2>

  begin_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	994080e7          	jalr	-1644(ra) # 800040ca <begin_op>

  if(omode & O_CREATE){
    8000573e:	f4c42783          	lw	a5,-180(s0)
    80005742:	2007f793          	andi	a5,a5,512
    80005746:	cbdd                	beqz	a5,800057fc <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005748:	4681                	li	a3,0
    8000574a:	4601                	li	a2,0
    8000574c:	4589                	li	a1,2
    8000574e:	f5040513          	addi	a0,s0,-176
    80005752:	00000097          	auipc	ra,0x0
    80005756:	97a080e7          	jalr	-1670(ra) # 800050cc <create>
    8000575a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000575c:	c951                	beqz	a0,800057f0 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000575e:	04449703          	lh	a4,68(s1)
    80005762:	478d                	li	a5,3
    80005764:	00f71763          	bne	a4,a5,80005772 <sys_open+0x72>
    80005768:	0464d703          	lhu	a4,70(s1)
    8000576c:	47a5                	li	a5,9
    8000576e:	0ce7ec63          	bltu	a5,a4,80005846 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	d60080e7          	jalr	-672(ra) # 800044d2 <filealloc>
    8000577a:	892a                	mv	s2,a0
    8000577c:	c56d                	beqz	a0,80005866 <sys_open+0x166>
    8000577e:	00000097          	auipc	ra,0x0
    80005782:	90c080e7          	jalr	-1780(ra) # 8000508a <fdalloc>
    80005786:	89aa                	mv	s3,a0
    80005788:	0c054a63          	bltz	a0,8000585c <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000578c:	04449703          	lh	a4,68(s1)
    80005790:	478d                	li	a5,3
    80005792:	0ef70563          	beq	a4,a5,8000587c <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005796:	4789                	li	a5,2
    80005798:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000579c:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800057a0:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800057a4:	f4c42783          	lw	a5,-180(s0)
    800057a8:	0017c713          	xori	a4,a5,1
    800057ac:	8b05                	andi	a4,a4,1
    800057ae:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b2:	0037f713          	andi	a4,a5,3
    800057b6:	00e03733          	snez	a4,a4
    800057ba:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057be:	4007f793          	andi	a5,a5,1024
    800057c2:	c791                	beqz	a5,800057ce <sys_open+0xce>
    800057c4:	04449703          	lh	a4,68(s1)
    800057c8:	4789                	li	a5,2
    800057ca:	0cf70063          	beq	a4,a5,8000588a <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	016080e7          	jalr	22(ra) # 800037e6 <iunlock>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	96c080e7          	jalr	-1684(ra) # 80004144 <end_op>

  return fd;
    800057e0:	854e                	mv	a0,s3
}
    800057e2:	70ea                	ld	ra,184(sp)
    800057e4:	744a                	ld	s0,176(sp)
    800057e6:	74aa                	ld	s1,168(sp)
    800057e8:	790a                	ld	s2,160(sp)
    800057ea:	69ea                	ld	s3,152(sp)
    800057ec:	6129                	addi	sp,sp,192
    800057ee:	8082                	ret
      end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	954080e7          	jalr	-1708(ra) # 80004144 <end_op>
      return -1;
    800057f8:	557d                	li	a0,-1
    800057fa:	b7e5                	j	800057e2 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057fc:	f5040513          	addi	a0,s0,-176
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	6ca080e7          	jalr	1738(ra) # 80003eca <namei>
    80005808:	84aa                	mv	s1,a0
    8000580a:	c905                	beqz	a0,8000583a <sys_open+0x13a>
    ilock(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	f18080e7          	jalr	-232(ra) # 80003724 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005814:	04449703          	lh	a4,68(s1)
    80005818:	4785                	li	a5,1
    8000581a:	f4f712e3          	bne	a4,a5,8000575e <sys_open+0x5e>
    8000581e:	f4c42783          	lw	a5,-180(s0)
    80005822:	dba1                	beqz	a5,80005772 <sys_open+0x72>
      iunlockput(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	160080e7          	jalr	352(ra) # 80003986 <iunlockput>
      end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	916080e7          	jalr	-1770(ra) # 80004144 <end_op>
      return -1;
    80005836:	557d                	li	a0,-1
    80005838:	b76d                	j	800057e2 <sys_open+0xe2>
      end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	90a080e7          	jalr	-1782(ra) # 80004144 <end_op>
      return -1;
    80005842:	557d                	li	a0,-1
    80005844:	bf79                	j	800057e2 <sys_open+0xe2>
    iunlockput(ip);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	13e080e7          	jalr	318(ra) # 80003986 <iunlockput>
    end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	8f4080e7          	jalr	-1804(ra) # 80004144 <end_op>
    return -1;
    80005858:	557d                	li	a0,-1
    8000585a:	b761                	j	800057e2 <sys_open+0xe2>
      fileclose(f);
    8000585c:	854a                	mv	a0,s2
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	d30080e7          	jalr	-720(ra) # 8000458e <fileclose>
    iunlockput(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	11e080e7          	jalr	286(ra) # 80003986 <iunlockput>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	8d4080e7          	jalr	-1836(ra) # 80004144 <end_op>
    return -1;
    80005878:	557d                	li	a0,-1
    8000587a:	b7a5                	j	800057e2 <sys_open+0xe2>
    f->type = FD_DEVICE;
    8000587c:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005880:	04649783          	lh	a5,70(s1)
    80005884:	02f91223          	sh	a5,36(s2)
    80005888:	bf21                	j	800057a0 <sys_open+0xa0>
    itrunc(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	fa6080e7          	jalr	-90(ra) # 80003832 <itrunc>
    80005894:	bf2d                	j	800057ce <sys_open+0xce>

0000000080005896 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005896:	7175                	addi	sp,sp,-144
    80005898:	e506                	sd	ra,136(sp)
    8000589a:	e122                	sd	s0,128(sp)
    8000589c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	82c080e7          	jalr	-2004(ra) # 800040ca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a6:	08000613          	li	a2,128
    800058aa:	f7040593          	addi	a1,s0,-144
    800058ae:	4501                	li	a0,0
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	352080e7          	jalr	850(ra) # 80002c02 <argstr>
    800058b8:	02054963          	bltz	a0,800058ea <sys_mkdir+0x54>
    800058bc:	4681                	li	a3,0
    800058be:	4601                	li	a2,0
    800058c0:	4585                	li	a1,1
    800058c2:	f7040513          	addi	a0,s0,-144
    800058c6:	00000097          	auipc	ra,0x0
    800058ca:	806080e7          	jalr	-2042(ra) # 800050cc <create>
    800058ce:	cd11                	beqz	a0,800058ea <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	0b6080e7          	jalr	182(ra) # 80003986 <iunlockput>
  end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	86c080e7          	jalr	-1940(ra) # 80004144 <end_op>
  return 0;
    800058e0:	4501                	li	a0,0
}
    800058e2:	60aa                	ld	ra,136(sp)
    800058e4:	640a                	ld	s0,128(sp)
    800058e6:	6149                	addi	sp,sp,144
    800058e8:	8082                	ret
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	85a080e7          	jalr	-1958(ra) # 80004144 <end_op>
    return -1;
    800058f2:	557d                	li	a0,-1
    800058f4:	b7fd                	j	800058e2 <sys_mkdir+0x4c>

00000000800058f6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f6:	7135                	addi	sp,sp,-160
    800058f8:	ed06                	sd	ra,152(sp)
    800058fa:	e922                	sd	s0,144(sp)
    800058fc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	7cc080e7          	jalr	1996(ra) # 800040ca <begin_op>
  argint(1, &major);
    80005906:	f6c40593          	addi	a1,s0,-148
    8000590a:	4505                	li	a0,1
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	2b6080e7          	jalr	694(ra) # 80002bc2 <argint>
  argint(2, &minor);
    80005914:	f6840593          	addi	a1,s0,-152
    80005918:	4509                	li	a0,2
    8000591a:	ffffd097          	auipc	ra,0xffffd
    8000591e:	2a8080e7          	jalr	680(ra) # 80002bc2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005922:	08000613          	li	a2,128
    80005926:	f7040593          	addi	a1,s0,-144
    8000592a:	4501                	li	a0,0
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	2d6080e7          	jalr	726(ra) # 80002c02 <argstr>
    80005934:	02054b63          	bltz	a0,8000596a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005938:	f6841683          	lh	a3,-152(s0)
    8000593c:	f6c41603          	lh	a2,-148(s0)
    80005940:	458d                	li	a1,3
    80005942:	f7040513          	addi	a0,s0,-144
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	786080e7          	jalr	1926(ra) # 800050cc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594e:	cd11                	beqz	a0,8000596a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	036080e7          	jalr	54(ra) # 80003986 <iunlockput>
  end_op();
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	7ec080e7          	jalr	2028(ra) # 80004144 <end_op>
  return 0;
    80005960:	4501                	li	a0,0
}
    80005962:	60ea                	ld	ra,152(sp)
    80005964:	644a                	ld	s0,144(sp)
    80005966:	610d                	addi	sp,sp,160
    80005968:	8082                	ret
    end_op();
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	7da080e7          	jalr	2010(ra) # 80004144 <end_op>
    return -1;
    80005972:	557d                	li	a0,-1
    80005974:	b7fd                	j	80005962 <sys_mknod+0x6c>

0000000080005976 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005976:	7135                	addi	sp,sp,-160
    80005978:	ed06                	sd	ra,152(sp)
    8000597a:	e922                	sd	s0,144(sp)
    8000597c:	e526                	sd	s1,136(sp)
    8000597e:	e14a                	sd	s2,128(sp)
    80005980:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005982:	ffffc097          	auipc	ra,0xffffc
    80005986:	0a2080e7          	jalr	162(ra) # 80001a24 <myproc>
    8000598a:	892a                	mv	s2,a0
  
  begin_op();
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	73e080e7          	jalr	1854(ra) # 800040ca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005994:	08000613          	li	a2,128
    80005998:	f6040593          	addi	a1,s0,-160
    8000599c:	4501                	li	a0,0
    8000599e:	ffffd097          	auipc	ra,0xffffd
    800059a2:	264080e7          	jalr	612(ra) # 80002c02 <argstr>
    800059a6:	04054b63          	bltz	a0,800059fc <sys_chdir+0x86>
    800059aa:	f6040513          	addi	a0,s0,-160
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	51c080e7          	jalr	1308(ra) # 80003eca <namei>
    800059b6:	84aa                	mv	s1,a0
    800059b8:	c131                	beqz	a0,800059fc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	d6a080e7          	jalr	-662(ra) # 80003724 <ilock>
  if(ip->type != T_DIR){
    800059c2:	04449703          	lh	a4,68(s1)
    800059c6:	4785                	li	a5,1
    800059c8:	04f71063          	bne	a4,a5,80005a08 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059cc:	8526                	mv	a0,s1
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	e18080e7          	jalr	-488(ra) # 800037e6 <iunlock>
  iput(p->cwd);
    800059d6:	15093503          	ld	a0,336(s2)
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	f04080e7          	jalr	-252(ra) # 800038de <iput>
  end_op();
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	762080e7          	jalr	1890(ra) # 80004144 <end_op>
  p->cwd = ip;
    800059ea:	14993823          	sd	s1,336(s2)
  return 0;
    800059ee:	4501                	li	a0,0
}
    800059f0:	60ea                	ld	ra,152(sp)
    800059f2:	644a                	ld	s0,144(sp)
    800059f4:	64aa                	ld	s1,136(sp)
    800059f6:	690a                	ld	s2,128(sp)
    800059f8:	610d                	addi	sp,sp,160
    800059fa:	8082                	ret
    end_op();
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	748080e7          	jalr	1864(ra) # 80004144 <end_op>
    return -1;
    80005a04:	557d                	li	a0,-1
    80005a06:	b7ed                	j	800059f0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a08:	8526                	mv	a0,s1
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	f7c080e7          	jalr	-132(ra) # 80003986 <iunlockput>
    end_op();
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	732080e7          	jalr	1842(ra) # 80004144 <end_op>
    return -1;
    80005a1a:	557d                	li	a0,-1
    80005a1c:	bfd1                	j	800059f0 <sys_chdir+0x7a>

0000000080005a1e <sys_exec>:

uint64
sys_exec(void)
{
    80005a1e:	7121                	addi	sp,sp,-448
    80005a20:	ff06                	sd	ra,440(sp)
    80005a22:	fb22                	sd	s0,432(sp)
    80005a24:	f726                	sd	s1,424(sp)
    80005a26:	f34a                	sd	s2,416(sp)
    80005a28:	ef4e                	sd	s3,408(sp)
    80005a2a:	eb52                	sd	s4,400(sp)
    80005a2c:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a2e:	e4840593          	addi	a1,s0,-440
    80005a32:	4505                	li	a0,1
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	1ae080e7          	jalr	430(ra) # 80002be2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a3c:	08000613          	li	a2,128
    80005a40:	f5040593          	addi	a1,s0,-176
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	1bc080e7          	jalr	444(ra) # 80002c02 <argstr>
    80005a4e:	87aa                	mv	a5,a0
    return -1;
    80005a50:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a52:	0c07c263          	bltz	a5,80005b16 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a56:	10000613          	li	a2,256
    80005a5a:	4581                	li	a1,0
    80005a5c:	e5040513          	addi	a0,s0,-432
    80005a60:	ffffb097          	auipc	ra,0xffffb
    80005a64:	2e4080e7          	jalr	740(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a68:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a6c:	89a6                	mv	s3,s1
    80005a6e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a70:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a74:	00391513          	slli	a0,s2,0x3
    80005a78:	e4040593          	addi	a1,s0,-448
    80005a7c:	e4843783          	ld	a5,-440(s0)
    80005a80:	953e                	add	a0,a0,a5
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	0a2080e7          	jalr	162(ra) # 80002b24 <fetchaddr>
    80005a8a:	02054a63          	bltz	a0,80005abe <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a8e:	e4043783          	ld	a5,-448(s0)
    80005a92:	c3b9                	beqz	a5,80005ad8 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a94:	ffffb097          	auipc	ra,0xffffb
    80005a98:	0c4080e7          	jalr	196(ra) # 80000b58 <kalloc>
    80005a9c:	85aa                	mv	a1,a0
    80005a9e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aa2:	cd11                	beqz	a0,80005abe <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aa4:	6605                	lui	a2,0x1
    80005aa6:	e4043503          	ld	a0,-448(s0)
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	0cc080e7          	jalr	204(ra) # 80002b76 <fetchstr>
    80005ab2:	00054663          	bltz	a0,80005abe <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005ab6:	0905                	addi	s2,s2,1
    80005ab8:	09a1                	addi	s3,s3,8
    80005aba:	fb491de3          	bne	s2,s4,80005a74 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abe:	f5040913          	addi	s2,s0,-176
    80005ac2:	6088                	ld	a0,0(s1)
    80005ac4:	c921                	beqz	a0,80005b14 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	f94080e7          	jalr	-108(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	04a1                	addi	s1,s1,8
    80005ad0:	ff2499e3          	bne	s1,s2,80005ac2 <sys_exec+0xa4>
  return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	a081                	j	80005b16 <sys_exec+0xf8>
      argv[i] = 0;
    80005ad8:	0009079b          	sext.w	a5,s2
    80005adc:	078e                	slli	a5,a5,0x3
    80005ade:	fd078793          	addi	a5,a5,-48
    80005ae2:	97a2                	add	a5,a5,s0
    80005ae4:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005ae8:	e5040593          	addi	a1,s0,-432
    80005aec:	f5040513          	addi	a0,s0,-176
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	114080e7          	jalr	276(ra) # 80004c04 <exec>
    80005af8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afa:	f5040993          	addi	s3,s0,-176
    80005afe:	6088                	ld	a0,0(s1)
    80005b00:	c901                	beqz	a0,80005b10 <sys_exec+0xf2>
    kfree(argv[i]);
    80005b02:	ffffb097          	auipc	ra,0xffffb
    80005b06:	f58080e7          	jalr	-168(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0a:	04a1                	addi	s1,s1,8
    80005b0c:	ff3499e3          	bne	s1,s3,80005afe <sys_exec+0xe0>
  return ret;
    80005b10:	854a                	mv	a0,s2
    80005b12:	a011                	j	80005b16 <sys_exec+0xf8>
  return -1;
    80005b14:	557d                	li	a0,-1
}
    80005b16:	70fa                	ld	ra,440(sp)
    80005b18:	745a                	ld	s0,432(sp)
    80005b1a:	74ba                	ld	s1,424(sp)
    80005b1c:	791a                	ld	s2,416(sp)
    80005b1e:	69fa                	ld	s3,408(sp)
    80005b20:	6a5a                	ld	s4,400(sp)
    80005b22:	6139                	addi	sp,sp,448
    80005b24:	8082                	ret

0000000080005b26 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b26:	7139                	addi	sp,sp,-64
    80005b28:	fc06                	sd	ra,56(sp)
    80005b2a:	f822                	sd	s0,48(sp)
    80005b2c:	f426                	sd	s1,40(sp)
    80005b2e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	ef4080e7          	jalr	-268(ra) # 80001a24 <myproc>
    80005b38:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b3a:	fd840593          	addi	a1,s0,-40
    80005b3e:	4501                	li	a0,0
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	0a2080e7          	jalr	162(ra) # 80002be2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b48:	fc840593          	addi	a1,s0,-56
    80005b4c:	fd040513          	addi	a0,s0,-48
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	d6a080e7          	jalr	-662(ra) # 800048ba <pipealloc>
    return -1;
    80005b58:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b5a:	0c054463          	bltz	a0,80005c22 <sys_pipe+0xfc>
  fd0 = -1;
    80005b5e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b62:	fd043503          	ld	a0,-48(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	524080e7          	jalr	1316(ra) # 8000508a <fdalloc>
    80005b6e:	fca42223          	sw	a0,-60(s0)
    80005b72:	08054b63          	bltz	a0,80005c08 <sys_pipe+0xe2>
    80005b76:	fc843503          	ld	a0,-56(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	510080e7          	jalr	1296(ra) # 8000508a <fdalloc>
    80005b82:	fca42023          	sw	a0,-64(s0)
    80005b86:	06054863          	bltz	a0,80005bf6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b8a:	4691                	li	a3,4
    80005b8c:	fc440613          	addi	a2,s0,-60
    80005b90:	fd843583          	ld	a1,-40(s0)
    80005b94:	68a8                	ld	a0,80(s1)
    80005b96:	ffffc097          	auipc	ra,0xffffc
    80005b9a:	b4e080e7          	jalr	-1202(ra) # 800016e4 <copyout>
    80005b9e:	02054063          	bltz	a0,80005bbe <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba2:	4691                	li	a3,4
    80005ba4:	fc040613          	addi	a2,s0,-64
    80005ba8:	fd843583          	ld	a1,-40(s0)
    80005bac:	0591                	addi	a1,a1,4
    80005bae:	68a8                	ld	a0,80(s1)
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	b34080e7          	jalr	-1228(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bba:	06055463          	bgez	a0,80005c22 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bbe:	fc442783          	lw	a5,-60(s0)
    80005bc2:	07e9                	addi	a5,a5,26
    80005bc4:	078e                	slli	a5,a5,0x3
    80005bc6:	97a6                	add	a5,a5,s1
    80005bc8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bcc:	fc042783          	lw	a5,-64(s0)
    80005bd0:	07e9                	addi	a5,a5,26
    80005bd2:	078e                	slli	a5,a5,0x3
    80005bd4:	94be                	add	s1,s1,a5
    80005bd6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bda:	fd043503          	ld	a0,-48(s0)
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	9b0080e7          	jalr	-1616(ra) # 8000458e <fileclose>
    fileclose(wf);
    80005be6:	fc843503          	ld	a0,-56(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	9a4080e7          	jalr	-1628(ra) # 8000458e <fileclose>
    return -1;
    80005bf2:	57fd                	li	a5,-1
    80005bf4:	a03d                	j	80005c22 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bf6:	fc442783          	lw	a5,-60(s0)
    80005bfa:	0007c763          	bltz	a5,80005c08 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bfe:	07e9                	addi	a5,a5,26
    80005c00:	078e                	slli	a5,a5,0x3
    80005c02:	97a6                	add	a5,a5,s1
    80005c04:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	982080e7          	jalr	-1662(ra) # 8000458e <fileclose>
    fileclose(wf);
    80005c14:	fc843503          	ld	a0,-56(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	976080e7          	jalr	-1674(ra) # 8000458e <fileclose>
    return -1;
    80005c20:	57fd                	li	a5,-1
}
    80005c22:	853e                	mv	a0,a5
    80005c24:	70e2                	ld	ra,56(sp)
    80005c26:	7442                	ld	s0,48(sp)
    80005c28:	74a2                	ld	s1,40(sp)
    80005c2a:	6121                	addi	sp,sp,64
    80005c2c:	8082                	ret
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	d81fc0ef          	jal	ra,800029f0 <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	6d0c                	ld	a1,24(a0)
    80005ccc:	7110                	ld	a2,32(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	cf0080e7          	jalr	-784(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	97aa                	add	a5,a5,a0
    80005d2c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	cb8080e7          	jalr	-840(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5151b          	slliw	a0,a0,0xd
    80005d4c:	0c2017b7          	lui	a5,0xc201
    80005d50:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d52:	43c8                	lw	a0,4(a5)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c90080e7          	jalr	-880(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	04a7cc63          	blt	a5,a0,80005de8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	41c78793          	addi	a5,a5,1052 # 800231b0 <disk>
    80005d9c:	97aa                	add	a5,a5,a0
    80005d9e:	0187c783          	lbu	a5,24(a5)
    80005da2:	ebb9                	bnez	a5,80005df8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005da4:	00451693          	slli	a3,a0,0x4
    80005da8:	0001d797          	auipc	a5,0x1d
    80005dac:	40878793          	addi	a5,a5,1032 # 800231b0 <disk>
    80005db0:	6398                	ld	a4,0(a5)
    80005db2:	9736                	add	a4,a4,a3
    80005db4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005db8:	6398                	ld	a4,0(a5)
    80005dba:	9736                	add	a4,a4,a3
    80005dbc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005dc0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005dc4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	4705                	li	a4,1
    80005dcc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005dd0:	0001d517          	auipc	a0,0x1d
    80005dd4:	3f850513          	addi	a0,a0,1016 # 800231c8 <disk+0x18>
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	386080e7          	jalr	902(ra) # 8000215e <wakeup>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret
    panic("free_desc 1");
    80005de8:	00004517          	auipc	a0,0x4
    80005dec:	9f050513          	addi	a0,a0,-1552 # 800097d8 <syscalls+0x368>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005df8:	00004517          	auipc	a0,0x4
    80005dfc:	9f050513          	addi	a0,a0,-1552 # 800097e8 <syscalls+0x378>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>

0000000080005e08 <virtio_disk_init>:
{
    80005e08:	1101                	addi	sp,sp,-32
    80005e0a:	ec06                	sd	ra,24(sp)
    80005e0c:	e822                	sd	s0,16(sp)
    80005e0e:	e426                	sd	s1,8(sp)
    80005e10:	e04a                	sd	s2,0(sp)
    80005e12:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e14:	00004597          	auipc	a1,0x4
    80005e18:	9e458593          	addi	a1,a1,-1564 # 800097f8 <syscalls+0x388>
    80005e1c:	0001d517          	auipc	a0,0x1d
    80005e20:	4bc50513          	addi	a0,a0,1212 # 800232d8 <disk+0x128>
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	d94080e7          	jalr	-620(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e2c:	100017b7          	lui	a5,0x10001
    80005e30:	4398                	lw	a4,0(a5)
    80005e32:	2701                	sext.w	a4,a4
    80005e34:	747277b7          	lui	a5,0x74727
    80005e38:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e3c:	14f71b63          	bne	a4,a5,80005f92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e40:	100017b7          	lui	a5,0x10001
    80005e44:	43dc                	lw	a5,4(a5)
    80005e46:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e48:	4709                	li	a4,2
    80005e4a:	14e79463          	bne	a5,a4,80005f92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	479c                	lw	a5,8(a5)
    80005e54:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e56:	12e79e63          	bne	a5,a4,80005f92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	47d8                	lw	a4,12(a5)
    80005e60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e62:	554d47b7          	lui	a5,0x554d4
    80005e66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e6a:	12f71463          	bne	a4,a5,80005f92 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e76:	4705                	li	a4,1
    80005e78:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7a:	470d                	li	a4,3
    80005e7c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e7e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e80:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e84:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb03f>
    80005e88:	8f75                	and	a4,a4,a3
    80005e8a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8c:	472d                	li	a4,11
    80005e8e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e90:	5bbc                	lw	a5,112(a5)
    80005e92:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e96:	8ba1                	andi	a5,a5,8
    80005e98:	10078563          	beqz	a5,80005fa2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ea4:	43fc                	lw	a5,68(a5)
    80005ea6:	2781                	sext.w	a5,a5
    80005ea8:	10079563          	bnez	a5,80005fb2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	5bdc                	lw	a5,52(a5)
    80005eb2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005eb4:	10078763          	beqz	a5,80005fc2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005eb8:	471d                	li	a4,7
    80005eba:	10f77c63          	bgeu	a4,a5,80005fd2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	c9a080e7          	jalr	-870(ra) # 80000b58 <kalloc>
    80005ec6:	0001d497          	auipc	s1,0x1d
    80005eca:	2ea48493          	addi	s1,s1,746 # 800231b0 <disk>
    80005ece:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ed0:	ffffb097          	auipc	ra,0xffffb
    80005ed4:	c88080e7          	jalr	-888(ra) # 80000b58 <kalloc>
    80005ed8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	c7e080e7          	jalr	-898(ra) # 80000b58 <kalloc>
    80005ee2:	87aa                	mv	a5,a0
    80005ee4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ee6:	6088                	ld	a0,0(s1)
    80005ee8:	cd6d                	beqz	a0,80005fe2 <virtio_disk_init+0x1da>
    80005eea:	0001d717          	auipc	a4,0x1d
    80005eee:	2ce73703          	ld	a4,718(a4) # 800231b8 <disk+0x8>
    80005ef2:	cb65                	beqz	a4,80005fe2 <virtio_disk_init+0x1da>
    80005ef4:	c7fd                	beqz	a5,80005fe2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ef6:	6605                	lui	a2,0x1
    80005ef8:	4581                	li	a1,0
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e4a080e7          	jalr	-438(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f02:	0001d497          	auipc	s1,0x1d
    80005f06:	2ae48493          	addi	s1,s1,686 # 800231b0 <disk>
    80005f0a:	6605                	lui	a2,0x1
    80005f0c:	4581                	li	a1,0
    80005f0e:	6488                	ld	a0,8(s1)
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	e34080e7          	jalr	-460(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f18:	6605                	lui	a2,0x1
    80005f1a:	4581                	li	a1,0
    80005f1c:	6888                	ld	a0,16(s1)
    80005f1e:	ffffb097          	auipc	ra,0xffffb
    80005f22:	e26080e7          	jalr	-474(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f26:	100017b7          	lui	a5,0x10001
    80005f2a:	4721                	li	a4,8
    80005f2c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f2e:	4098                	lw	a4,0(s1)
    80005f30:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f34:	40d8                	lw	a4,4(s1)
    80005f36:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f3a:	6498                	ld	a4,8(s1)
    80005f3c:	0007069b          	sext.w	a3,a4
    80005f40:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f44:	9701                	srai	a4,a4,0x20
    80005f46:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f4a:	6898                	ld	a4,16(s1)
    80005f4c:	0007069b          	sext.w	a3,a4
    80005f50:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f54:	9701                	srai	a4,a4,0x20
    80005f56:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f5a:	4705                	li	a4,1
    80005f5c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f5e:	00e48c23          	sb	a4,24(s1)
    80005f62:	00e48ca3          	sb	a4,25(s1)
    80005f66:	00e48d23          	sb	a4,26(s1)
    80005f6a:	00e48da3          	sb	a4,27(s1)
    80005f6e:	00e48e23          	sb	a4,28(s1)
    80005f72:	00e48ea3          	sb	a4,29(s1)
    80005f76:	00e48f23          	sb	a4,30(s1)
    80005f7a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f7e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f82:	0727a823          	sw	s2,112(a5)
}
    80005f86:	60e2                	ld	ra,24(sp)
    80005f88:	6442                	ld	s0,16(sp)
    80005f8a:	64a2                	ld	s1,8(sp)
    80005f8c:	6902                	ld	s2,0(sp)
    80005f8e:	6105                	addi	sp,sp,32
    80005f90:	8082                	ret
    panic("could not find virtio disk");
    80005f92:	00004517          	auipc	a0,0x4
    80005f96:	87650513          	addi	a0,a0,-1930 # 80009808 <syscalls+0x398>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fa2:	00004517          	auipc	a0,0x4
    80005fa6:	88650513          	addi	a0,a0,-1914 # 80009828 <syscalls+0x3b8>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fb2:	00004517          	auipc	a0,0x4
    80005fb6:	89650513          	addi	a0,a0,-1898 # 80009848 <syscalls+0x3d8>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fc2:	00004517          	auipc	a0,0x4
    80005fc6:	8a650513          	addi	a0,a0,-1882 # 80009868 <syscalls+0x3f8>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fd2:	00004517          	auipc	a0,0x4
    80005fd6:	8b650513          	addi	a0,a0,-1866 # 80009888 <syscalls+0x418>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005fe2:	00004517          	auipc	a0,0x4
    80005fe6:	8c650513          	addi	a0,a0,-1850 # 800098a8 <syscalls+0x438>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>

0000000080005ff2 <virtio_disk_init_bootloader>:
{
    80005ff2:	1101                	addi	sp,sp,-32
    80005ff4:	ec06                	sd	ra,24(sp)
    80005ff6:	e822                	sd	s0,16(sp)
    80005ff8:	e426                	sd	s1,8(sp)
    80005ffa:	e04a                	sd	s2,0(sp)
    80005ffc:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ffe:	00003597          	auipc	a1,0x3
    80006002:	7fa58593          	addi	a1,a1,2042 # 800097f8 <syscalls+0x388>
    80006006:	0001d517          	auipc	a0,0x1d
    8000600a:	2d250513          	addi	a0,a0,722 # 800232d8 <disk+0x128>
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	baa080e7          	jalr	-1110(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006016:	100017b7          	lui	a5,0x10001
    8000601a:	4398                	lw	a4,0(a5)
    8000601c:	2701                	sext.w	a4,a4
    8000601e:	747277b7          	lui	a5,0x74727
    80006022:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006026:	12f71763          	bne	a4,a5,80006154 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000602a:	100017b7          	lui	a5,0x10001
    8000602e:	43dc                	lw	a5,4(a5)
    80006030:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006032:	4709                	li	a4,2
    80006034:	12e79063          	bne	a5,a4,80006154 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	479c                	lw	a5,8(a5)
    8000603e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006040:	10e79a63          	bne	a5,a4,80006154 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	47d8                	lw	a4,12(a5)
    8000604a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000604c:	554d47b7          	lui	a5,0x554d4
    80006050:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006054:	10f71063          	bne	a4,a5,80006154 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006058:	100017b7          	lui	a5,0x10001
    8000605c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006060:	4705                	li	a4,1
    80006062:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006064:	470d                	li	a4,3
    80006066:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006068:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000606a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000606e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb03f>
    80006072:	8f75                	and	a4,a4,a3
    80006074:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006076:	472d                	li	a4,11
    80006078:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000607a:	5bbc                	lw	a5,112(a5)
    8000607c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006080:	8ba1                	andi	a5,a5,8
    80006082:	c3ed                	beqz	a5,80006164 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000608c:	43fc                	lw	a5,68(a5)
    8000608e:	2781                	sext.w	a5,a5
    80006090:	e3f5                	bnez	a5,80006174 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006092:	100017b7          	lui	a5,0x10001
    80006096:	5bdc                	lw	a5,52(a5)
    80006098:	2781                	sext.w	a5,a5
  if(max == 0)
    8000609a:	c7ed                	beqz	a5,80006184 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    8000609c:	471d                	li	a4,7
    8000609e:	0ef77b63          	bgeu	a4,a5,80006194 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    800060a2:	0001d497          	auipc	s1,0x1d
    800060a6:	10e48493          	addi	s1,s1,270 # 800231b0 <disk>
    800060aa:	770007b7          	lui	a5,0x77000
    800060ae:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    800060b0:	770017b7          	lui	a5,0x77001
    800060b4:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    800060b6:	770027b7          	lui	a5,0x77002
    800060ba:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    800060bc:	6605                	lui	a2,0x1
    800060be:	4581                	li	a1,0
    800060c0:	77000537          	lui	a0,0x77000
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	c80080e7          	jalr	-896(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060cc:	6605                	lui	a2,0x1
    800060ce:	4581                	li	a1,0
    800060d0:	6488                	ld	a0,8(s1)
    800060d2:	ffffb097          	auipc	ra,0xffffb
    800060d6:	c72080e7          	jalr	-910(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    800060da:	6605                	lui	a2,0x1
    800060dc:	4581                	li	a1,0
    800060de:	6888                	ld	a0,16(s1)
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	c64080e7          	jalr	-924(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e8:	100017b7          	lui	a5,0x10001
    800060ec:	4721                	li	a4,8
    800060ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060f0:	4098                	lw	a4,0(s1)
    800060f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060f6:	40d8                	lw	a4,4(s1)
    800060f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060fc:	6498                	ld	a4,8(s1)
    800060fe:	0007069b          	sext.w	a3,a4
    80006102:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006106:	9701                	srai	a4,a4,0x20
    80006108:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000610c:	6898                	ld	a4,16(s1)
    8000610e:	0007069b          	sext.w	a3,a4
    80006112:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006116:	9701                	srai	a4,a4,0x20
    80006118:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000611c:	4705                	li	a4,1
    8000611e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006120:	00e48c23          	sb	a4,24(s1)
    80006124:	00e48ca3          	sb	a4,25(s1)
    80006128:	00e48d23          	sb	a4,26(s1)
    8000612c:	00e48da3          	sb	a4,27(s1)
    80006130:	00e48e23          	sb	a4,28(s1)
    80006134:	00e48ea3          	sb	a4,29(s1)
    80006138:	00e48f23          	sb	a4,30(s1)
    8000613c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006140:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006144:	0727a823          	sw	s2,112(a5)
}
    80006148:	60e2                	ld	ra,24(sp)
    8000614a:	6442                	ld	s0,16(sp)
    8000614c:	64a2                	ld	s1,8(sp)
    8000614e:	6902                	ld	s2,0(sp)
    80006150:	6105                	addi	sp,sp,32
    80006152:	8082                	ret
    panic("could not find virtio disk");
    80006154:	00003517          	auipc	a0,0x3
    80006158:	6b450513          	addi	a0,a0,1716 # 80009808 <syscalls+0x398>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006164:	00003517          	auipc	a0,0x3
    80006168:	6c450513          	addi	a0,a0,1732 # 80009828 <syscalls+0x3b8>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006174:	00003517          	auipc	a0,0x3
    80006178:	6d450513          	addi	a0,a0,1748 # 80009848 <syscalls+0x3d8>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006184:	00003517          	auipc	a0,0x3
    80006188:	6e450513          	addi	a0,a0,1764 # 80009868 <syscalls+0x3f8>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b4080e7          	jalr	948(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006194:	00003517          	auipc	a0,0x3
    80006198:	6f450513          	addi	a0,a0,1780 # 80009888 <syscalls+0x418>
    8000619c:	ffffa097          	auipc	ra,0xffffa
    800061a0:	3a4080e7          	jalr	932(ra) # 80000540 <panic>

00000000800061a4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061a4:	7159                	addi	sp,sp,-112
    800061a6:	f486                	sd	ra,104(sp)
    800061a8:	f0a2                	sd	s0,96(sp)
    800061aa:	eca6                	sd	s1,88(sp)
    800061ac:	e8ca                	sd	s2,80(sp)
    800061ae:	e4ce                	sd	s3,72(sp)
    800061b0:	e0d2                	sd	s4,64(sp)
    800061b2:	fc56                	sd	s5,56(sp)
    800061b4:	f85a                	sd	s6,48(sp)
    800061b6:	f45e                	sd	s7,40(sp)
    800061b8:	f062                	sd	s8,32(sp)
    800061ba:	ec66                	sd	s9,24(sp)
    800061bc:	e86a                	sd	s10,16(sp)
    800061be:	1880                	addi	s0,sp,112
    800061c0:	8a2a                	mv	s4,a0
    800061c2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061c4:	00c52c83          	lw	s9,12(a0)
    800061c8:	001c9c9b          	slliw	s9,s9,0x1
    800061cc:	1c82                	slli	s9,s9,0x20
    800061ce:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061d2:	0001d517          	auipc	a0,0x1d
    800061d6:	10650513          	addi	a0,a0,262 # 800232d8 <disk+0x128>
    800061da:	ffffb097          	auipc	ra,0xffffb
    800061de:	a6e080e7          	jalr	-1426(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    800061e2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800061e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061e6:	0001db17          	auipc	s6,0x1d
    800061ea:	fcab0b13          	addi	s6,s6,-54 # 800231b0 <disk>
  for(int i = 0; i < 3; i++){
    800061ee:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061f0:	0001dc17          	auipc	s8,0x1d
    800061f4:	0e8c0c13          	addi	s8,s8,232 # 800232d8 <disk+0x128>
    800061f8:	a095                	j	8000625c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061fa:	00fb0733          	add	a4,s6,a5
    800061fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006202:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006204:	0207c563          	bltz	a5,8000622e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006208:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    8000620a:	0591                	addi	a1,a1,4
    8000620c:	05560d63          	beq	a2,s5,80006266 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006210:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006212:	0001d717          	auipc	a4,0x1d
    80006216:	f9e70713          	addi	a4,a4,-98 # 800231b0 <disk>
    8000621a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000621c:	01874683          	lbu	a3,24(a4)
    80006220:	fee9                	bnez	a3,800061fa <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006222:	2785                	addiw	a5,a5,1
    80006224:	0705                	addi	a4,a4,1
    80006226:	fe979be3          	bne	a5,s1,8000621c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000622a:	57fd                	li	a5,-1
    8000622c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000622e:	00c05e63          	blez	a2,8000624a <virtio_disk_rw+0xa6>
    80006232:	060a                	slli	a2,a2,0x2
    80006234:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006238:	0009a503          	lw	a0,0(s3)
    8000623c:	00000097          	auipc	ra,0x0
    80006240:	b4a080e7          	jalr	-1206(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80006244:	0991                	addi	s3,s3,4
    80006246:	ffa999e3          	bne	s3,s10,80006238 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000624a:	85e2                	mv	a1,s8
    8000624c:	0001d517          	auipc	a0,0x1d
    80006250:	f7c50513          	addi	a0,a0,-132 # 800231c8 <disk+0x18>
    80006254:	ffffc097          	auipc	ra,0xffffc
    80006258:	ea6080e7          	jalr	-346(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000625c:	f9040993          	addi	s3,s0,-112
{
    80006260:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006262:	864a                	mv	a2,s2
    80006264:	b775                	j	80006210 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006266:	f9042503          	lw	a0,-112(s0)
    8000626a:	00a50713          	addi	a4,a0,10
    8000626e:	0712                	slli	a4,a4,0x4

  if(write)
    80006270:	0001d797          	auipc	a5,0x1d
    80006274:	f4078793          	addi	a5,a5,-192 # 800231b0 <disk>
    80006278:	00e786b3          	add	a3,a5,a4
    8000627c:	01703633          	snez	a2,s7
    80006280:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006282:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006286:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000628a:	f6070613          	addi	a2,a4,-160
    8000628e:	6394                	ld	a3,0(a5)
    80006290:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006292:	00870593          	addi	a1,a4,8
    80006296:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006298:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000629a:	0007b803          	ld	a6,0(a5)
    8000629e:	9642                	add	a2,a2,a6
    800062a0:	46c1                	li	a3,16
    800062a2:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062a4:	4585                	li	a1,1
    800062a6:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062aa:	f9442683          	lw	a3,-108(s0)
    800062ae:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062b2:	0692                	slli	a3,a3,0x4
    800062b4:	9836                	add	a6,a6,a3
    800062b6:	058a0613          	addi	a2,s4,88
    800062ba:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062be:	0007b803          	ld	a6,0(a5)
    800062c2:	96c2                	add	a3,a3,a6
    800062c4:	40000613          	li	a2,1024
    800062c8:	c690                	sw	a2,8(a3)
  if(write)
    800062ca:	001bb613          	seqz	a2,s7
    800062ce:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062d2:	00166613          	ori	a2,a2,1
    800062d6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062da:	f9842603          	lw	a2,-104(s0)
    800062de:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062e2:	00250693          	addi	a3,a0,2
    800062e6:	0692                	slli	a3,a3,0x4
    800062e8:	96be                	add	a3,a3,a5
    800062ea:	58fd                	li	a7,-1
    800062ec:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062f0:	0612                	slli	a2,a2,0x4
    800062f2:	9832                	add	a6,a6,a2
    800062f4:	f9070713          	addi	a4,a4,-112
    800062f8:	973e                	add	a4,a4,a5
    800062fa:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800062fe:	6398                	ld	a4,0(a5)
    80006300:	9732                	add	a4,a4,a2
    80006302:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006304:	4609                	li	a2,2
    80006306:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    8000630a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000630e:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006312:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006316:	6794                	ld	a3,8(a5)
    80006318:	0026d703          	lhu	a4,2(a3)
    8000631c:	8b1d                	andi	a4,a4,7
    8000631e:	0706                	slli	a4,a4,0x1
    80006320:	96ba                	add	a3,a3,a4
    80006322:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006326:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000632a:	6798                	ld	a4,8(a5)
    8000632c:	00275783          	lhu	a5,2(a4)
    80006330:	2785                	addiw	a5,a5,1
    80006332:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006336:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000633a:	100017b7          	lui	a5,0x10001
    8000633e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006342:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006346:	0001d917          	auipc	s2,0x1d
    8000634a:	f9290913          	addi	s2,s2,-110 # 800232d8 <disk+0x128>
  while(b->disk == 1) {
    8000634e:	4485                	li	s1,1
    80006350:	00b79c63          	bne	a5,a1,80006368 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006354:	85ca                	mv	a1,s2
    80006356:	8552                	mv	a0,s4
    80006358:	ffffc097          	auipc	ra,0xffffc
    8000635c:	da2080e7          	jalr	-606(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006360:	004a2783          	lw	a5,4(s4)
    80006364:	fe9788e3          	beq	a5,s1,80006354 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006368:	f9042903          	lw	s2,-112(s0)
    8000636c:	00290713          	addi	a4,s2,2
    80006370:	0712                	slli	a4,a4,0x4
    80006372:	0001d797          	auipc	a5,0x1d
    80006376:	e3e78793          	addi	a5,a5,-450 # 800231b0 <disk>
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006380:	0001d997          	auipc	s3,0x1d
    80006384:	e3098993          	addi	s3,s3,-464 # 800231b0 <disk>
    80006388:	00491713          	slli	a4,s2,0x4
    8000638c:	0009b783          	ld	a5,0(s3)
    80006390:	97ba                	add	a5,a5,a4
    80006392:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006396:	854a                	mv	a0,s2
    80006398:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000639c:	00000097          	auipc	ra,0x0
    800063a0:	9ea080e7          	jalr	-1558(ra) # 80005d86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063a4:	8885                	andi	s1,s1,1
    800063a6:	f0ed                	bnez	s1,80006388 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063a8:	0001d517          	auipc	a0,0x1d
    800063ac:	f3050513          	addi	a0,a0,-208 # 800232d8 <disk+0x128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	94c080e7          	jalr	-1716(ra) # 80000cfc <release>
}
    800063b8:	70a6                	ld	ra,104(sp)
    800063ba:	7406                	ld	s0,96(sp)
    800063bc:	64e6                	ld	s1,88(sp)
    800063be:	6946                	ld	s2,80(sp)
    800063c0:	69a6                	ld	s3,72(sp)
    800063c2:	6a06                	ld	s4,64(sp)
    800063c4:	7ae2                	ld	s5,56(sp)
    800063c6:	7b42                	ld	s6,48(sp)
    800063c8:	7ba2                	ld	s7,40(sp)
    800063ca:	7c02                	ld	s8,32(sp)
    800063cc:	6ce2                	ld	s9,24(sp)
    800063ce:	6d42                	ld	s10,16(sp)
    800063d0:	6165                	addi	sp,sp,112
    800063d2:	8082                	ret

00000000800063d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063d4:	1101                	addi	sp,sp,-32
    800063d6:	ec06                	sd	ra,24(sp)
    800063d8:	e822                	sd	s0,16(sp)
    800063da:	e426                	sd	s1,8(sp)
    800063dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063de:	0001d497          	auipc	s1,0x1d
    800063e2:	dd248493          	addi	s1,s1,-558 # 800231b0 <disk>
    800063e6:	0001d517          	auipc	a0,0x1d
    800063ea:	ef250513          	addi	a0,a0,-270 # 800232d8 <disk+0x128>
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	85a080e7          	jalr	-1958(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063f6:	10001737          	lui	a4,0x10001
    800063fa:	533c                	lw	a5,96(a4)
    800063fc:	8b8d                	andi	a5,a5,3
    800063fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006400:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006404:	689c                	ld	a5,16(s1)
    80006406:	0204d703          	lhu	a4,32(s1)
    8000640a:	0027d783          	lhu	a5,2(a5)
    8000640e:	04f70863          	beq	a4,a5,8000645e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006412:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006416:	6898                	ld	a4,16(s1)
    80006418:	0204d783          	lhu	a5,32(s1)
    8000641c:	8b9d                	andi	a5,a5,7
    8000641e:	078e                	slli	a5,a5,0x3
    80006420:	97ba                	add	a5,a5,a4
    80006422:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006424:	00278713          	addi	a4,a5,2
    80006428:	0712                	slli	a4,a4,0x4
    8000642a:	9726                	add	a4,a4,s1
    8000642c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006430:	e721                	bnez	a4,80006478 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006432:	0789                	addi	a5,a5,2
    80006434:	0792                	slli	a5,a5,0x4
    80006436:	97a6                	add	a5,a5,s1
    80006438:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000643a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000643e:	ffffc097          	auipc	ra,0xffffc
    80006442:	d20080e7          	jalr	-736(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006446:	0204d783          	lhu	a5,32(s1)
    8000644a:	2785                	addiw	a5,a5,1
    8000644c:	17c2                	slli	a5,a5,0x30
    8000644e:	93c1                	srli	a5,a5,0x30
    80006450:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006454:	6898                	ld	a4,16(s1)
    80006456:	00275703          	lhu	a4,2(a4)
    8000645a:	faf71ce3          	bne	a4,a5,80006412 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000645e:	0001d517          	auipc	a0,0x1d
    80006462:	e7a50513          	addi	a0,a0,-390 # 800232d8 <disk+0x128>
    80006466:	ffffb097          	auipc	ra,0xffffb
    8000646a:	896080e7          	jalr	-1898(ra) # 80000cfc <release>
}
    8000646e:	60e2                	ld	ra,24(sp)
    80006470:	6442                	ld	s0,16(sp)
    80006472:	64a2                	ld	s1,8(sp)
    80006474:	6105                	addi	sp,sp,32
    80006476:	8082                	ret
      panic("virtio_disk_intr status");
    80006478:	00003517          	auipc	a0,0x3
    8000647c:	44850513          	addi	a0,a0,1096 # 800098c0 <syscalls+0x450>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	0c0080e7          	jalr	192(ra) # 80000540 <panic>

0000000080006488 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    80006488:	1141                	addi	sp,sp,-16
    8000648a:	e422                	sd	s0,8(sp)
    8000648c:	0800                	addi	s0,sp,16
}
    8000648e:	6422                	ld	s0,8(sp)
    80006490:	0141                	addi	sp,sp,16
    80006492:	8082                	ret

0000000080006494 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    80006494:	1101                	addi	sp,sp,-32
    80006496:	ec06                	sd	ra,24(sp)
    80006498:	e822                	sd	s0,16(sp)
    8000649a:	e426                	sd	s1,8(sp)
    8000649c:	1000                	addi	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    8000649e:	454c                	lw	a1,12(a0)
    800064a0:	7cf00793          	li	a5,1999
    800064a4:	02b7ea63          	bltu	a5,a1,800064d8 <ramdiskrw+0x44>
    800064a8:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    800064aa:	00a5959b          	slliw	a1,a1,0xa
    800064ae:	1582                	slli	a1,a1,0x20
    800064b0:	9181                	srli	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    800064b2:	40000613          	li	a2,1024
    800064b6:	02100793          	li	a5,33
    800064ba:	07ea                	slli	a5,a5,0x1a
    800064bc:	95be                	add	a1,a1,a5
    800064be:	05850513          	addi	a0,a0,88
    800064c2:	ffffb097          	auipc	ra,0xffffb
    800064c6:	8de080e7          	jalr	-1826(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064ca:	4785                	li	a5,1
    800064cc:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064ce:	60e2                	ld	ra,24(sp)
    800064d0:	6442                	ld	s0,16(sp)
    800064d2:	64a2                	ld	s1,8(sp)
    800064d4:	6105                	addi	sp,sp,32
    800064d6:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800064d8:	00003517          	auipc	a0,0x3
    800064dc:	40050513          	addi	a0,a0,1024 # 800098d8 <syscalls+0x468>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	060080e7          	jalr	96(ra) # 80000540 <panic>

00000000800064e8 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    800064e8:	7119                	addi	sp,sp,-128
    800064ea:	fc86                	sd	ra,120(sp)
    800064ec:	f8a2                	sd	s0,112(sp)
    800064ee:	f4a6                	sd	s1,104(sp)
    800064f0:	f0ca                	sd	s2,96(sp)
    800064f2:	ecce                	sd	s3,88(sp)
    800064f4:	e8d2                	sd	s4,80(sp)
    800064f6:	e4d6                	sd	s5,72(sp)
    800064f8:	e0da                	sd	s6,64(sp)
    800064fa:	fc5e                	sd	s7,56(sp)
    800064fc:	f862                	sd	s8,48(sp)
    800064fe:	f466                	sd	s9,40(sp)
    80006500:	0100                	addi	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    80006502:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    80006506:	c5e1                	beqz	a1,800065ce <dump_hex+0xe6>
    80006508:	89ae                	mv	s3,a1
    8000650a:	892a                	mv	s2,a0
    8000650c:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    8000650e:	00003a97          	auipc	s5,0x3
    80006512:	3eaa8a93          	addi	s5,s5,1002 # 800098f8 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    80006516:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    8000651a:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    8000651e:	00003c17          	auipc	s8,0x3
    80006522:	3eac0c13          	addi	s8,s8,1002 # 80009908 <syscalls+0x498>
			printf(" ");
    80006526:	00003b97          	auipc	s7,0x3
    8000652a:	3dab8b93          	addi	s7,s7,986 # 80009900 <syscalls+0x490>
    8000652e:	a839                	j	8000654c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006530:	00f4f793          	andi	a5,s1,15
    80006534:	fa078793          	addi	a5,a5,-96
    80006538:	97a2                	add	a5,a5,s0
    8000653a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000653e:	0485                	addi	s1,s1,1
    80006540:	0074f793          	andi	a5,s1,7
    80006544:	cb9d                	beqz	a5,8000657a <dump_hex+0x92>
    80006546:	0b348a63          	beq	s1,s3,800065fa <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000654a:	0905                	addi	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000654c:	00094583          	lbu	a1,0(s2)
    80006550:	8556                	mv	a0,s5
    80006552:	ffffa097          	auipc	ra,0xffffa
    80006556:	038080e7          	jalr	56(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000655a:	00094703          	lbu	a4,0(s2)
    8000655e:	fe07079b          	addiw	a5,a4,-32
    80006562:	0ff7f793          	zext.b	a5,a5
    80006566:	fcfa65e3          	bltu	s4,a5,80006530 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000656a:	00f4f793          	andi	a5,s1,15
    8000656e:	fa078793          	addi	a5,a5,-96
    80006572:	97a2                	add	a5,a5,s0
    80006574:	fee78423          	sb	a4,-24(a5)
    80006578:	b7d9                	j	8000653e <dump_hex+0x56>
			printf(" ");
    8000657a:	855e                	mv	a0,s7
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	00e080e7          	jalr	14(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006584:	00f4fc93          	andi	s9,s1,15
    80006588:	080c8263          	beqz	s9,8000660c <dump_hex+0x124>
			} else if (i+1 == size) {
    8000658c:	fb349fe3          	bne	s1,s3,8000654a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    80006590:	fa0c8793          	addi	a5,s9,-96
    80006594:	97a2                	add	a5,a5,s0
    80006596:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    8000659a:	47a1                	li	a5,8
    8000659c:	0597f663          	bgeu	a5,s9,800065e8 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    800065a0:	00003917          	auipc	s2,0x3
    800065a4:	37090913          	addi	s2,s2,880 # 80009910 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065a8:	44bd                	li	s1,15
					printf("   ");
    800065aa:	854a                	mv	a0,s2
    800065ac:	ffffa097          	auipc	ra,0xffffa
    800065b0:	fde080e7          	jalr	-34(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065b4:	0c85                	addi	s9,s9,1
    800065b6:	ff94fae3          	bgeu	s1,s9,800065aa <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    800065ba:	f8840593          	addi	a1,s0,-120
    800065be:	00003517          	auipc	a0,0x3
    800065c2:	34a50513          	addi	a0,a0,842 # 80009908 <syscalls+0x498>
    800065c6:	ffffa097          	auipc	ra,0xffffa
    800065ca:	fc4080e7          	jalr	-60(ra) # 8000058a <printf>
			}
		}
	}
    800065ce:	70e6                	ld	ra,120(sp)
    800065d0:	7446                	ld	s0,112(sp)
    800065d2:	74a6                	ld	s1,104(sp)
    800065d4:	7906                	ld	s2,96(sp)
    800065d6:	69e6                	ld	s3,88(sp)
    800065d8:	6a46                	ld	s4,80(sp)
    800065da:	6aa6                	ld	s5,72(sp)
    800065dc:	6b06                	ld	s6,64(sp)
    800065de:	7be2                	ld	s7,56(sp)
    800065e0:	7c42                	ld	s8,48(sp)
    800065e2:	7ca2                	ld	s9,40(sp)
    800065e4:	6109                	addi	sp,sp,128
    800065e6:	8082                	ret
					printf(" ");
    800065e8:	00003517          	auipc	a0,0x3
    800065ec:	31850513          	addi	a0,a0,792 # 80009900 <syscalls+0x490>
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	f9a080e7          	jalr	-102(ra) # 8000058a <printf>
    800065f8:	b765                	j	800065a0 <dump_hex+0xb8>
			printf(" ");
    800065fa:	855e                	mv	a0,s7
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	f8e080e7          	jalr	-114(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006604:	00f9fc93          	andi	s9,s3,15
    80006608:	f80c94e3          	bnez	s9,80006590 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    8000660c:	f8840593          	addi	a1,s0,-120
    80006610:	8562                	mv	a0,s8
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	f78080e7          	jalr	-136(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    8000661a:	fb348ae3          	beq	s1,s3,800065ce <dump_hex+0xe6>
    8000661e:	0905                	addi	s2,s2,1
    80006620:	b735                	j	8000654c <dump_hex+0x64>

0000000080006622 <pmp_configuration>:
    // }
}


// PMP Configurations
void pmp_configuration(int current_mode) {
    80006622:	715d                	addi	sp,sp,-80
    80006624:	e486                	sd	ra,72(sp)
    80006626:	e0a2                	sd	s0,64(sp)
    80006628:	fc26                	sd	s1,56(sp)
    8000662a:	f84a                	sd	s2,48(sp)
    8000662c:	f44e                	sd	s3,40(sp)
    8000662e:	f052                	sd	s4,32(sp)
    80006630:	ec56                	sd	s5,24(sp)
    80006632:	e85a                	sd	s6,16(sp)
    80006634:	e45e                	sd	s7,8(sp)
    80006636:	e062                	sd	s8,0(sp)
    80006638:	0880                	addi	s0,sp,80
    8000663a:	84aa                	mv	s1,a0
    vmm->vmm_pagetable = (pte_t*)kalloc();
    8000663c:	00003917          	auipc	s2,0x3
    80006640:	62c90913          	addi	s2,s2,1580 # 80009c68 <vmm>
    80006644:	00093983          	ld	s3,0(s2)
    80006648:	ffffa097          	auipc	ra,0xffffa
    8000664c:	510080e7          	jalr	1296(ra) # 80000b58 <kalloc>
    80006650:	44a9b023          	sd	a0,1088(s3)
    if(vmm->vmm_pagetable == NULL)
    80006654:	00093783          	ld	a5,0(s2)
    80006658:	4407b503          	ld	a0,1088(a5)
    8000665c:	cd35                	beqz	a0,800066d8 <pmp_configuration+0xb6>
    memset(vmm->vmm_pagetable, 0, sizeof(pte_t) * PTE_ENTRIES * PAGE_LEVELS);
    8000665e:	660d                	lui	a2,0x3
    80006660:	4581                	li	a1,0
    80006662:	ffffa097          	auipc	ra,0xffffa
    80006666:	6e2080e7          	jalr	1762(ra) # 80000d44 <memset>
    struct proc *p = myproc();
    8000666a:	ffffb097          	auipc	ra,0xffffb
    8000666e:	3ba080e7          	jalr	954(ra) # 80001a24 <myproc>
    80006672:	8a2a                	mv	s4,a0
    pagetable_t old = p->pagetable; 
    80006674:	05053983          	ld	s3,80(a0)
    pagetable_t new = vmm->vmm_pagetable;
    80006678:	00003797          	auipc	a5,0x3
    8000667c:	5f07b783          	ld	a5,1520(a5) # 80009c68 <vmm>
    80006680:	4407b903          	ld	s2,1088(a5)
    if(execution_mode == M_MODE) {
    80006684:	4789                	li	a5,2
    80006686:	06f48163          	beq	s1,a5,800066e8 <pmp_configuration+0xc6>
    else if(execution_mode == S_MODE || execution_mode == U_MODE) {
    8000668a:	2481                	sext.w	s1,s1
    8000668c:	4785                	li	a5,1
    8000668e:	1497f363          	bgeu	a5,s1,800067d4 <pmp_configuration+0x1b2>
    uint64 final_addr = 0x80400000;
    pmp_pagetable_configuration(base_addr, final_addr, current_mode);
    uint64 final_addr_1 = base_addr;
    
    //printf("in pmp fucntion********");
    if(vmm->pmpaddr[0].val != 0)
    80006692:	00003797          	auipc	a5,0x3
    80006696:	5d67b783          	ld	a5,1494(a5) # 80009c68 <vmm>
    8000669a:	2387b483          	ld	s1,568(a5)
    8000669e:	18048a63          	beqz	s1,80006832 <pmp_configuration+0x210>
    {
        uint64 start_addr = vmm->pmpaddr[0].val;
        start_addr = start_addr << 2;
    800066a2:	048a                	slli	s1,s1,0x2
        if (vmm->pmpaddr[1].val != 0){
    800066a4:	2487b903          	ld	s2,584(a5)
    800066a8:	12090963          	beqz	s2,800067da <pmp_configuration+0x1b8>
    final_addr_1 = vmm->pmpaddr[1].val;
    final_addr_1 = final_addr_1 << 2;
    800066ac:	090a                	slli	s2,s2,0x2
    }
    uint64 cfg = vmm->pmpcfg[0].val;
    cfg = cfg & 0xFF0;
    cfg = cfg >> 8;
    800066ae:	3387b983          	ld	s3,824(a5)
    800066b2:	0089d993          	srli	s3,s3,0x8
   for (uint64 i = pmp_base_addr; i < pmp_final_addr; i += PGSIZE) {
    800066b6:	1724f963          	bgeu	s1,s2,80006828 <pmp_configuration+0x206>
    pte_t *pte = walk(vmm->vmm_pagetable, i, 0);
    800066ba:	00003a97          	auipc	s5,0x3
    800066be:	5aea8a93          	addi	s5,s5,1454 # 80009c68 <vmm>
        uint64 new_pte = PA2PTE(PTE2PA(*pte)) | PTE_V;
    800066c2:	7b7d                	lui	s6,0xfffff
    800066c4:	002b5b13          	srli	s6,s6,0x2
        if (cfg & PTE_R) {
    800066c8:	0029fc13          	andi	s8,s3,2
        if (cfg & PTE_W) {
    800066cc:	0049fb93          	andi	s7,s3,4
        if (cfg & PTE_X) {
    800066d0:	0089f993          	andi	s3,s3,8
   for (uint64 i = pmp_base_addr; i < pmp_final_addr; i += PGSIZE) {
    800066d4:	6a05                	lui	s4,0x1
    800066d6:	aa09                	j	800067e8 <pmp_configuration+0x1c6>
        panic("Could not allocate memory to pmp page table");
    800066d8:	00003517          	auipc	a0,0x3
    800066dc:	24050513          	addi	a0,a0,576 # 80009918 <syscalls+0x4a8>
    800066e0:	ffffa097          	auipc	ra,0xffffa
    800066e4:	e60080e7          	jalr	-416(ra) # 80000540 <panic>
        for(uint64 i = base_addr; i < final_addr; i += PGSIZE){
    800066e8:	4485                	li	s1,1
    800066ea:	04fe                	slli	s1,s1,0x1f
    800066ec:	20100a93          	li	s5,513
    800066f0:	0ada                	slli	s5,s5,0x16
            if((pte = walk(old, i, 0)) == 0)
    800066f2:	4601                	li	a2,0
    800066f4:	85a6                	mv	a1,s1
    800066f6:	854e                	mv	a0,s3
    800066f8:	ffffb097          	auipc	ra,0xffffb
    800066fc:	936080e7          	jalr	-1738(ra) # 8000102e <walk>
    80006700:	c935                	beqz	a0,80006774 <pmp_configuration+0x152>
            if((*pte & PTE_V) == 0)
    80006702:	6118                	ld	a4,0(a0)
    80006704:	00177793          	andi	a5,a4,1
    80006708:	cfb5                	beqz	a5,80006784 <pmp_configuration+0x162>
            pa = PTE2PA(*pte);
    8000670a:	00a75693          	srli	a3,a4,0xa
            if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    8000670e:	3ff77713          	andi	a4,a4,1023
    80006712:	06b2                	slli	a3,a3,0xc
    80006714:	6605                	lui	a2,0x1
    80006716:	85a6                	mv	a1,s1
    80006718:	854a                	mv	a0,s2
    8000671a:	ffffb097          	auipc	ra,0xffffb
    8000671e:	9fc080e7          	jalr	-1540(ra) # 80001116 <mappages>
    80006722:	e92d                	bnez	a0,80006794 <pmp_configuration+0x172>
        for(uint64 i = base_addr; i < final_addr; i += PGSIZE){
    80006724:	6785                	lui	a5,0x1
    80006726:	94be                	add	s1,s1,a5
    80006728:	fd5495e3          	bne	s1,s5,800066f2 <pmp_configuration+0xd0>
        for(uint64 i = 0; i < p->sz; i += PGSIZE){
    8000672c:	048a3783          	ld	a5,72(s4) # 1048 <_entry-0x7fffefb8>
    80006730:	d3ad                	beqz	a5,80006692 <pmp_configuration+0x70>
    80006732:	4481                	li	s1,0
            if((pte = walk(old, i, 0)) == 0)
    80006734:	4601                	li	a2,0
    80006736:	85a6                	mv	a1,s1
    80006738:	854e                	mv	a0,s3
    8000673a:	ffffb097          	auipc	ra,0xffffb
    8000673e:	8f4080e7          	jalr	-1804(ra) # 8000102e <walk>
    80006742:	c12d                	beqz	a0,800067a4 <pmp_configuration+0x182>
            if((*pte & PTE_V) == 0)
    80006744:	6118                	ld	a4,0(a0)
    80006746:	00177793          	andi	a5,a4,1
    8000674a:	c7ad                	beqz	a5,800067b4 <pmp_configuration+0x192>
            pa = PTE2PA(*pte);
    8000674c:	00a75693          	srli	a3,a4,0xa
            if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    80006750:	3ff77713          	andi	a4,a4,1023
    80006754:	06b2                	slli	a3,a3,0xc
    80006756:	6605                	lui	a2,0x1
    80006758:	85a6                	mv	a1,s1
    8000675a:	854a                	mv	a0,s2
    8000675c:	ffffb097          	auipc	ra,0xffffb
    80006760:	9ba080e7          	jalr	-1606(ra) # 80001116 <mappages>
    80006764:	e125                	bnez	a0,800067c4 <pmp_configuration+0x1a2>
        for(uint64 i = 0; i < p->sz; i += PGSIZE){
    80006766:	6785                	lui	a5,0x1
    80006768:	94be                	add	s1,s1,a5
    8000676a:	048a3783          	ld	a5,72(s4)
    8000676e:	fcf4e3e3          	bltu	s1,a5,80006734 <pmp_configuration+0x112>
    80006772:	b705                	j	80006692 <pmp_configuration+0x70>
                panic("pmp_pagetable_configuration: pte doesnot exist");
    80006774:	00003517          	auipc	a0,0x3
    80006778:	1d450513          	addi	a0,a0,468 # 80009948 <syscalls+0x4d8>
    8000677c:	ffffa097          	auipc	ra,0xffffa
    80006780:	dc4080e7          	jalr	-572(ra) # 80000540 <panic>
                panic("pmp_pagetable_configuration: page was not present");
    80006784:	00003517          	auipc	a0,0x3
    80006788:	1f450513          	addi	a0,a0,500 # 80009978 <syscalls+0x508>
    8000678c:	ffffa097          	auipc	ra,0xffffa
    80006790:	db4080e7          	jalr	-588(ra) # 80000540 <panic>
                panic("mappages failed, have a look");
    80006794:	00003517          	auipc	a0,0x3
    80006798:	21c50513          	addi	a0,a0,540 # 800099b0 <syscalls+0x540>
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	da4080e7          	jalr	-604(ra) # 80000540 <panic>
                panic("pmp_pagetable_configuration: pte doesnot exist");
    800067a4:	00003517          	auipc	a0,0x3
    800067a8:	1a450513          	addi	a0,a0,420 # 80009948 <syscalls+0x4d8>
    800067ac:	ffffa097          	auipc	ra,0xffffa
    800067b0:	d94080e7          	jalr	-620(ra) # 80000540 <panic>
                panic("pmp_pagetable_configuration: page was not present");
    800067b4:	00003517          	auipc	a0,0x3
    800067b8:	1c450513          	addi	a0,a0,452 # 80009978 <syscalls+0x508>
    800067bc:	ffffa097          	auipc	ra,0xffffa
    800067c0:	d84080e7          	jalr	-636(ra) # 80000540 <panic>
                panic("mappages failed, have a look");
    800067c4:	00003517          	auipc	a0,0x3
    800067c8:	1ec50513          	addi	a0,a0,492 # 800099b0 <syscalls+0x540>
    800067cc:	ffffa097          	auipc	ra,0xffffa
    800067d0:	d74080e7          	jalr	-652(ra) # 80000540 <panic>
        p->pagetable = vmm->vmm_pagetable;
    800067d4:	05253823          	sd	s2,80(a0)
    800067d8:	bd6d                	j	80006692 <pmp_configuration+0x70>
    uint64 final_addr_1 = base_addr;
    800067da:	4905                	li	s2,1
    800067dc:	097e                	slli	s2,s2,0x1f
    800067de:	bdc1                	j	800066ae <pmp_configuration+0x8c>
        *pte = new_pte;
    800067e0:	e118                	sd	a4,0(a0)
   for (uint64 i = pmp_base_addr; i < pmp_final_addr; i += PGSIZE) {
    800067e2:	94d2                	add	s1,s1,s4
    800067e4:	0524f263          	bgeu	s1,s2,80006828 <pmp_configuration+0x206>
    pte_t *pte = walk(vmm->vmm_pagetable, i, 0);
    800067e8:	000ab783          	ld	a5,0(s5)
    800067ec:	4601                	li	a2,0
    800067ee:	85a6                	mv	a1,s1
    800067f0:	4407b503          	ld	a0,1088(a5) # 1440 <_entry-0x7fffebc0>
    800067f4:	ffffb097          	auipc	ra,0xffffb
    800067f8:	83a080e7          	jalr	-1990(ra) # 8000102e <walk>
    if (pte && (*pte & PTE_V)) {  // Ensure the PTE is valid
    800067fc:	d17d                	beqz	a0,800067e2 <pmp_configuration+0x1c0>
    800067fe:	611c                	ld	a5,0(a0)
    80006800:	0017f713          	andi	a4,a5,1
    80006804:	df79                	beqz	a4,800067e2 <pmp_configuration+0x1c0>
        uint64 new_pte = PA2PTE(PTE2PA(*pte)) | PTE_V;
    80006806:	0167f7b3          	and	a5,a5,s6
            new_pte |= PTE_R;
    8000680a:	0037e713          	ori	a4,a5,3
        if (cfg & PTE_R) {
    8000680e:	000c1463          	bnez	s8,80006816 <pmp_configuration+0x1f4>
        uint64 new_pte = PA2PTE(PTE2PA(*pte)) | PTE_V;
    80006812:	0017e713          	ori	a4,a5,1
        if (cfg & PTE_W) {
    80006816:	000b8463          	beqz	s7,8000681e <pmp_configuration+0x1fc>
            new_pte |= PTE_W;
    8000681a:	00476713          	ori	a4,a4,4
        if (cfg & PTE_X) {
    8000681e:	fc0981e3          	beqz	s3,800067e0 <pmp_configuration+0x1be>
            new_pte |= PTE_X;
    80006822:	00876713          	ori	a4,a4,8
    80006826:	bf6d                	j	800067e0 <pmp_configuration+0x1be>
    pmp_config = true;
    80006828:	4785                	li	a5,1
    8000682a:	00003717          	auipc	a4,0x3
    8000682e:	44f70323          	sb	a5,1094(a4) # 80009c70 <pmp_config>
    //     //printf("Permisions for the remainnig addrewss");
    //     pte_t *pte = walk(vmm->vmm_pagetable, i, 0);
    //     *pte = ~(PTE_R | PTE_W | PTE_X);
    // }
    //printf("The scause value is: *****", r_scause());
}
    80006832:	60a6                	ld	ra,72(sp)
    80006834:	6406                	ld	s0,64(sp)
    80006836:	74e2                	ld	s1,56(sp)
    80006838:	7942                	ld	s2,48(sp)
    8000683a:	79a2                	ld	s3,40(sp)
    8000683c:	7a02                	ld	s4,32(sp)
    8000683e:	6ae2                	ld	s5,24(sp)
    80006840:	6b42                	ld	s6,16(sp)
    80006842:	6ba2                	ld	s7,8(sp)
    80006844:	6c02                	ld	s8,0(sp)
    80006846:	6161                	addi	sp,sp,80
    80006848:	8082                	ret

000000008000684a <trap_and_emulate>:
void trap_and_emulate(void) {
    8000684a:	715d                	addi	sp,sp,-80
    8000684c:	e486                	sd	ra,72(sp)
    8000684e:	e0a2                	sd	s0,64(sp)
    80006850:	fc26                	sd	s1,56(sp)
    80006852:	f84a                	sd	s2,48(sp)
    80006854:	f44e                	sd	s3,40(sp)
    80006856:	f052                	sd	s4,32(sp)
    80006858:	ec56                	sd	s5,24(sp)
    8000685a:	e85a                	sd	s6,16(sp)
    8000685c:	0880                	addi	s0,sp,80
    struct proc *p = myproc();
    8000685e:	ffffb097          	auipc	ra,0xffffb
    80006862:	1c6080e7          	jalr	454(ra) # 80001a24 <myproc>
    80006866:	89aa                	mv	s3,a0
    uint64 type_instruction = 0;
    80006868:	fa043c23          	sd	zero,-72(s0)
    if(copyin(pagetable, (char*)&type_instruction, p->trapframe->epc, sizeof(type_instruction)) < 0){
    8000686c:	6d3c                	ld	a5,88(a0)
    8000686e:	46a1                	li	a3,8
    80006870:	6f90                	ld	a2,24(a5)
    80006872:	fb840593          	addi	a1,s0,-72
    80006876:	6928                	ld	a0,80(a0)
    80006878:	ffffb097          	auipc	ra,0xffffb
    8000687c:	ef8080e7          	jalr	-264(ra) # 80001770 <copyin>
    80006880:	06054b63          	bltz	a0,800068f6 <trap_and_emulate+0xac>
    uint32 op       = type_instruction & 0x7F;
    80006884:	fb843603          	ld	a2,-72(s0)
    uint32 rd       = (type_instruction >> 7) & 0x1F;
    80006888:	00765b13          	srli	s6,a2,0x7
    8000688c:	01fb7b13          	andi	s6,s6,31
    uint32 funct3   = (type_instruction >> 12) & 0x7;
    80006890:	00c65913          	srli	s2,a2,0xc
    80006894:	00797913          	andi	s2,s2,7
    uint32 rs1      = (type_instruction >> 15) & 0x1F;
    80006898:	00f65a13          	srli	s4,a2,0xf
    8000689c:	01fa7a13          	andi	s4,s4,31
    uint32 uimm     = (type_instruction >> 20) & 0xFFF;
    800068a0:	01465493          	srli	s1,a2,0x14
    800068a4:	00048a9b          	sext.w	s5,s1
    800068a8:	14d2                	slli	s1,s1,0x34
    800068aa:	90d1                	srli	s1,s1,0x34
    uint64 addr     = p->trapframe->epc;
    800068ac:	0589b583          	ld	a1,88(s3)
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n",
    800068b0:	8826                	mv	a6,s1
    800068b2:	87d2                	mv	a5,s4
    800068b4:	874a                	mv	a4,s2
    800068b6:	86da                	mv	a3,s6
    800068b8:	07f67613          	andi	a2,a2,127
    800068bc:	6d8c                	ld	a1,24(a1)
    800068be:	00003517          	auipc	a0,0x3
    800068c2:	11250513          	addi	a0,a0,274 # 800099d0 <syscalls+0x560>
    800068c6:	ffffa097          	auipc	ra,0xffffa
    800068ca:	cc4080e7          	jalr	-828(ra) # 8000058a <printf>
    if(funct3 ==0 && uimm==0){
    800068ce:	009967b3          	or	a5,s2,s1
    800068d2:	c3b1                	beqz	a5,80006916 <trap_and_emulate+0xcc>
    else if (funct3 == 0 && uimm == 0x102) {
    800068d4:	12091c63          	bnez	s2,80006a0c <trap_and_emulate+0x1c2>
    800068d8:	10200793          	li	a5,258
    800068dc:	06f48d63          	beq	s1,a5,80006956 <trap_and_emulate+0x10c>
    else if (funct3 == 0 && uimm == 0x302) {
    800068e0:	30200793          	li	a5,770
    800068e4:	0af48663          	beq	s1,a5,80006990 <trap_and_emulate+0x146>
        kill(p->pid);
    800068e8:	0309a503          	lw	a0,48(s3)
    800068ec:	ffffc097          	auipc	ra,0xffffc
    800068f0:	a18080e7          	jalr	-1512(ra) # 80002304 <kill>
    800068f4:	a039                	j	80006902 <trap_and_emulate+0xb8>
        kill(p->pid);
    800068f6:	0309a503          	lw	a0,48(s3)
    800068fa:	ffffc097          	auipc	ra,0xffffc
    800068fe:	a0a080e7          	jalr	-1526(ra) # 80002304 <kill>
}
    80006902:	60a6                	ld	ra,72(sp)
    80006904:	6406                	ld	s0,64(sp)
    80006906:	74e2                	ld	s1,56(sp)
    80006908:	7942                	ld	s2,48(sp)
    8000690a:	79a2                	ld	s3,40(sp)
    8000690c:	7a02                	ld	s4,32(sp)
    8000690e:	6ae2                	ld	s5,24(sp)
    80006910:	6b42                	ld	s6,16(sp)
    80006912:	6161                	addi	sp,sp,80
    80006914:	8082                	ret
        printf("(EC at %p)\n", p->trapframe->epc);
    80006916:	0589b783          	ld	a5,88(s3)
    8000691a:	6f8c                	ld	a1,24(a5)
    8000691c:	00003517          	auipc	a0,0x3
    80006920:	0f450513          	addi	a0,a0,244 # 80009a10 <syscalls+0x5a0>
    80006924:	ffffa097          	auipc	ra,0xffffa
    80006928:	c66080e7          	jalr	-922(ra) # 8000058a <printf>
        if(vmm->exec_mode == 0)
    8000692c:	00003797          	auipc	a5,0x3
    80006930:	33c7b783          	ld	a5,828(a5) # 80009c68 <vmm>
    80006934:	4307b703          	ld	a4,1072(a5)
    80006938:	f769                	bnez	a4,80006902 <trap_and_emulate+0xb8>
            vmm->exec_mode = 1;
    8000693a:	4705                	li	a4,1
    8000693c:	42e7b823          	sd	a4,1072(a5)
            vmm->sepc.val = p->trapframe->epc;
    80006940:	0589b703          	ld	a4,88(s3)
    80006944:	6f18                	ld	a4,24(a4)
    80006946:	16e7b423          	sd	a4,360(a5)
            p->trapframe->epc = vmm->stvec.val;
    8000694a:	0589b703          	ld	a4,88(s3)
    8000694e:	1787b783          	ld	a5,376(a5)
    80006952:	ef1c                	sd	a5,24(a4)
    80006954:	b77d                	j	80006902 <trap_and_emulate+0xb8>
        uint64 value_sstatus = vmm->sstatus.val;
    80006956:	00003797          	auipc	a5,0x3
    8000695a:	3127b783          	ld	a5,786(a5) # 80009c68 <vmm>
    8000695e:	1487b703          	ld	a4,328(a5)
        if(vmm->exec_mode != 1){
    80006962:	4307b603          	ld	a2,1072(a5)
    80006966:	4685                	li	a3,1
    80006968:	00d61d63          	bne	a2,a3,80006982 <trap_and_emulate+0x138>
        uint64 spp_bit_value = (value_sstatus >> 8) & 0x1;
    8000696c:	8321                	srli	a4,a4,0x8
    8000696e:	8b05                	andi	a4,a4,1
        if (spp_bit_value == 1) {
    80006970:	fb49                	bnez	a4,80006902 <trap_and_emulate+0xb8>
                vmm->exec_mode = U_MODE;
    80006972:	4207b823          	sd	zero,1072(a5)
                p->trapframe->epc = vmm->sepc.val;
    80006976:	0589b703          	ld	a4,88(s3)
    8000697a:	1687b783          	ld	a5,360(a5)
    8000697e:	ef1c                	sd	a5,24(a4)
    80006980:	b749                	j	80006902 <trap_and_emulate+0xb8>
            kill(p->pid);
    80006982:	0309a503          	lw	a0,48(s3)
    80006986:	ffffc097          	auipc	ra,0xffffc
    8000698a:	97e080e7          	jalr	-1666(ra) # 80002304 <kill>
    8000698e:	bf95                	j	80006902 <trap_and_emulate+0xb8>
        uint64 value_mstatus = vmm->mstatus.val;
    80006990:	00003717          	auipc	a4,0x3
    80006994:	2d873703          	ld	a4,728(a4) # 80009c68 <vmm>
        uint64 mpp_bit_value = (value_mstatus >> 11) & 0x3;
    80006998:	6f1c                	ld	a5,24(a4)
    8000699a:	83ad                	srli	a5,a5,0xb
    8000699c:	8b8d                	andi	a5,a5,3
        if (mpp_bit_value == 3) {
    8000699e:	468d                	li	a3,3
    800069a0:	00d78f63          	beq	a5,a3,800069be <trap_and_emulate+0x174>
        } else if (mpp_bit_value == 2) {
    800069a4:	4689                	li	a3,2
    800069a6:	04d78463          	beq	a5,a3,800069ee <trap_and_emulate+0x1a4>
        } else if (mpp_bit_value == 1) {
    800069aa:	4685                	li	a3,1
    800069ac:	04d78863          	beq	a5,a3,800069fc <trap_and_emulate+0x1b2>
            vmm->exec_mode = U_MODE;
    800069b0:	42073823          	sd	zero,1072(a4)
            p->trapframe->epc = vmm->mepc.val;
    800069b4:	0589b783          	ld	a5,88(s3)
    800069b8:	7718                	ld	a4,40(a4)
    800069ba:	ef98                	sd	a4,24(a5)
    800069bc:	a801                	j	800069cc <trap_and_emulate+0x182>
            vmm->exec_mode = M_MODE;
    800069be:	4789                	li	a5,2
    800069c0:	42f73823          	sd	a5,1072(a4)
            p->trapframe->epc = vmm->mepc.val;
    800069c4:	0589b783          	ld	a5,88(s3)
    800069c8:	7718                	ld	a4,40(a4)
    800069ca:	ef98                	sd	a4,24(a5)
        pmp_configuration(M_MODE);
    800069cc:	4509                	li	a0,2
    800069ce:	00000097          	auipc	ra,0x0
    800069d2:	c54080e7          	jalr	-940(ra) # 80006622 <pmp_configuration>
        if(pmp_config == true)
    800069d6:	00003797          	auipc	a5,0x3
    800069da:	29a7c783          	lbu	a5,666(a5) # 80009c70 <pmp_config>
    800069de:	d395                	beqz	a5,80006902 <trap_and_emulate+0xb8>
            kill(p->pid);
    800069e0:	0309a503          	lw	a0,48(s3)
    800069e4:	ffffc097          	auipc	ra,0xffffc
    800069e8:	920080e7          	jalr	-1760(ra) # 80002304 <kill>
    800069ec:	bf19                	j	80006902 <trap_and_emulate+0xb8>
            kill(p->pid);
    800069ee:	0309a503          	lw	a0,48(s3)
    800069f2:	ffffc097          	auipc	ra,0xffffc
    800069f6:	912080e7          	jalr	-1774(ra) # 80002304 <kill>
    800069fa:	bfc9                	j	800069cc <trap_and_emulate+0x182>
            vmm->exec_mode = S_MODE;
    800069fc:	4785                	li	a5,1
    800069fe:	42f73823          	sd	a5,1072(a4)
            p->trapframe->epc = vmm->mepc.val;
    80006a02:	0589b783          	ld	a5,88(s3)
    80006a06:	7718                	ld	a4,40(a4)
    80006a08:	ef98                	sd	a4,24(a5)
    80006a0a:	b7c9                	j	800069cc <trap_and_emulate+0x182>
    else if (funct3 == 0x2) {
    80006a0c:	4789                	li	a5,2
    80006a0e:	04f90863          	beq	s2,a5,80006a5e <trap_and_emulate+0x214>
    else if (funct3 == 0x1) {
    80006a12:	4785                	li	a5,1
    80006a14:	ecf91ae3          	bne	s2,a5,800068e8 <trap_and_emulate+0x9e>
    80006a18:	0001d697          	auipc	a3,0x1d
    80006a1c:	8d868693          	addi	a3,a3,-1832 # 800232f0 <csr_register_map_values>
    for(int i = 0; i < CSR_MAP_SIZE; i++) 
    80006a20:	4701                	li	a4,0
    80006a22:	04300613          	li	a2,67
        if(csr_register_map_values[i].csr_code == code) 
    80006a26:	429c                	lw	a5,0(a3)
    80006a28:	16978c63          	beq	a5,s1,80006ba0 <trap_and_emulate+0x356>
    for(int i = 0; i < CSR_MAP_SIZE; i++) 
    80006a2c:	2705                	addiw	a4,a4,1
    80006a2e:	06c1                	addi	a3,a3,16
    80006a30:	fec71be3          	bne	a4,a2,80006a26 <trap_and_emulate+0x1dc>
            printf("Invalid CSR for he uimm is : %x\n", uimm);
    80006a34:	85a6                	mv	a1,s1
    80006a36:	00003517          	auipc	a0,0x3
    80006a3a:	01250513          	addi	a0,a0,18 # 80009a48 <syscalls+0x5d8>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	b4c080e7          	jalr	-1204(ra) # 8000058a <printf>
            kill(p->pid);
    80006a46:	0309a503          	lw	a0,48(s3)
    80006a4a:	ffffc097          	auipc	ra,0xffffc
    80006a4e:	8ba080e7          	jalr	-1862(ra) # 80002304 <kill>
        p->trapframe->epc += 4;
    80006a52:	0589b703          	ld	a4,88(s3)
    80006a56:	6f1c                	ld	a5,24(a4)
    80006a58:	0791                	addi	a5,a5,4
    80006a5a:	ef1c                	sd	a5,24(a4)
    80006a5c:	b55d                	j	80006902 <trap_and_emulate+0xb8>
        struct vm_reg* found_reg = csr_register_1(uimm, vmm->exec_mode);
    80006a5e:	00003797          	auipc	a5,0x3
    80006a62:	20a7b783          	ld	a5,522(a5) # 80009c68 <vmm>
    80006a66:	4307b603          	ld	a2,1072(a5)
    80006a6a:	0006051b          	sext.w	a0,a2
    for(int i = 0; i < CSR_MAP_SIZE; i++) 
    80006a6e:	0001d797          	auipc	a5,0x1d
    80006a72:	88278793          	addi	a5,a5,-1918 # 800232f0 <csr_register_map_values>
    80006a76:	0001d697          	auipc	a3,0x1d
    80006a7a:	caa68693          	addi	a3,a3,-854 # 80023720 <end>
    80006a7e:	a021                	j	80006a86 <trap_and_emulate+0x23c>
    80006a80:	07c1                	addi	a5,a5,16
    80006a82:	74d78b63          	beq	a5,a3,800071d8 <trap_and_emulate+0x98e>
        if(csr_register_map_values[i].csr_code == code) 
    80006a86:	4398                	lw	a4,0(a5)
    80006a88:	fe971ce3          	bne	a4,s1,80006a80 <trap_and_emulate+0x236>
            if (csr_register_map_values[i].vm_reg_val == NULL)
    80006a8c:	6798                	ld	a4,8(a5)
    80006a8e:	74070563          	beqz	a4,800071d8 <trap_and_emulate+0x98e>
            if(curr_mode >= csr_mode) 
    80006a92:	434c                	lw	a1,4(a4)
    80006a94:	feb546e3          	blt	a0,a1,80006a80 <trap_and_emulate+0x236>
            csrr_write_trapframe(rd, found_reg->val, p);
    80006a98:	4714                	lw	a3,8(a4)
    if (reg_val == 0xa) 
    80006a9a:	3b59                	addiw	s6,s6,-10 # ffffffffffffeff6 <end+0xffffffff7ffdb8d6>
    80006a9c:	000b071b          	sext.w	a4,s6
    80006aa0:	47e9                	li	a5,26
    80006aa2:	74e7ea63          	bltu	a5,a4,800071f6 <trap_and_emulate+0x9ac>
    80006aa6:	020b1793          	slli	a5,s6,0x20
    80006aaa:	01e7db13          	srli	s6,a5,0x1e
    80006aae:	00003717          	auipc	a4,0x3
    80006ab2:	01670713          	addi	a4,a4,22 # 80009ac4 <syscalls+0x654>
    80006ab6:	9b3a                	add	s6,s6,a4
    80006ab8:	000b2783          	lw	a5,0(s6)
    80006abc:	97ba                	add	a5,a5,a4
    80006abe:	8782                	jr	a5
        p->trapframe->a0 = value;
    80006ac0:	0589b783          	ld	a5,88(s3)
    80006ac4:	fbb4                	sd	a3,112(a5)
    80006ac6:	af05                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a1 = value;
    80006ac8:	0589b783          	ld	a5,88(s3)
    80006acc:	ffb4                	sd	a3,120(a5)
    80006ace:	a725                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a2 = value;
    80006ad0:	0589b783          	ld	a5,88(s3)
    80006ad4:	e3d4                	sd	a3,128(a5)
    80006ad6:	a705                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a3 = value;
    80006ad8:	0589b783          	ld	a5,88(s3)
    80006adc:	e7d4                	sd	a3,136(a5)
    80006ade:	af21                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a4 = value;
    80006ae0:	0589b783          	ld	a5,88(s3)
    80006ae4:	ebd4                	sd	a3,144(a5)
    80006ae6:	af01                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a5 = value;
    80006ae8:	0589b783          	ld	a5,88(s3)
    80006aec:	efd4                	sd	a3,152(a5)
    80006aee:	a721                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a6 = value;
    80006af0:	0589b783          	ld	a5,88(s3)
    80006af4:	f3d4                	sd	a3,160(a5)
    80006af6:	a701                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->a7 = value;
    80006af8:	0589b783          	ld	a5,88(s3)
    80006afc:	f7d4                	sd	a3,168(a5)
    80006afe:	ade5                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t0 = value;
    80006b00:	0589b783          	ld	a5,88(s3)
    80006b04:	e7b4                	sd	a3,72(a5)
    80006b06:	adc5                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t1 = value;
    80006b08:	0589b783          	ld	a5,88(s3)
    80006b0c:	ebb4                	sd	a3,80(a5)
    80006b0e:	a5e5                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t2 = value;
    80006b10:	0589b783          	ld	a5,88(s3)
    80006b14:	efb4                	sd	a3,88(a5)
    80006b16:	a5c5                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t3 = value;
    80006b18:	0589b783          	ld	a5,88(s3)
    80006b1c:	10d7b023          	sd	a3,256(a5)
    80006b20:	add9                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t4 = value;
    80006b22:	0589b783          	ld	a5,88(s3)
    80006b26:	10d7b423          	sd	a3,264(a5)
    80006b2a:	a5f1                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t5 = value;
    80006b2c:	0589b783          	ld	a5,88(s3)
    80006b30:	10d7b823          	sd	a3,272(a5)
    80006b34:	a5c9                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->t6 = value;
    80006b36:	0589b783          	ld	a5,88(s3)
    80006b3a:	10d7bc23          	sd	a3,280(a5)
    80006b3e:	ad65                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s0 = value;
    80006b40:	0589b783          	ld	a5,88(s3)
    80006b44:	f3b4                	sd	a3,96(a5)
    80006b46:	ad45                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s1 = value;
    80006b48:	0589b783          	ld	a5,88(s3)
    80006b4c:	f7b4                	sd	a3,104(a5)
    80006b4e:	a565                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s2 = value;
    80006b50:	0589b783          	ld	a5,88(s3)
    80006b54:	fbd4                	sd	a3,176(a5)
    80006b56:	a545                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s3 = value;
    80006b58:	0589b783          	ld	a5,88(s3)
    80006b5c:	ffd4                	sd	a3,184(a5)
    80006b5e:	ad61                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s4 = value;
    80006b60:	0589b783          	ld	a5,88(s3)
    80006b64:	e3f4                	sd	a3,192(a5)
    80006b66:	ad41                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s5 = value;
    80006b68:	0589b783          	ld	a5,88(s3)
    80006b6c:	e7f4                	sd	a3,200(a5)
    80006b6e:	a561                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s6 = value;
    80006b70:	0589b783          	ld	a5,88(s3)
    80006b74:	ebf4                	sd	a3,208(a5)
    80006b76:	a541                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s7 = value;
    80006b78:	0589b783          	ld	a5,88(s3)
    80006b7c:	eff4                	sd	a3,216(a5)
    80006b7e:	ada5                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s8 = value;
    80006b80:	0589b783          	ld	a5,88(s3)
    80006b84:	f3f4                	sd	a3,224(a5)
    80006b86:	ad85                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s9 = value;
    80006b88:	0589b783          	ld	a5,88(s3)
    80006b8c:	f7f4                	sd	a3,232(a5)
    80006b8e:	a5a5                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s10 = value;
    80006b90:	0589b783          	ld	a5,88(s3)
    80006b94:	fbf4                	sd	a3,240(a5)
    80006b96:	a585                	j	800071f6 <trap_and_emulate+0x9ac>
        p->trapframe->s11 = value;
    80006b98:	0589b783          	ld	a5,88(s3)
    80006b9c:	fff4                	sd	a3,248(a5)
    80006b9e:	ada1                	j	800071f6 <trap_and_emulate+0x9ac>
            return csr_register_map_values[i].vm_reg_val;
    80006ba0:	0712                	slli	a4,a4,0x4
    80006ba2:	0001c797          	auipc	a5,0x1c
    80006ba6:	74e78793          	addi	a5,a5,1870 # 800232f0 <csr_register_map_values>
    80006baa:	97ba                	add	a5,a5,a4
        if (found_reg != NULL) {
    80006bac:	679c                	ld	a5,8(a5)
    80006bae:	e80783e3          	beqz	a5,80006a34 <trap_and_emulate+0x1ea>
    80006bb2:	0a0a                	slli	s4,s4,0x2
    80006bb4:	00003717          	auipc	a4,0x3
    80006bb8:	f7c70713          	addi	a4,a4,-132 # 80009b30 <syscalls+0x6c0>
    80006bbc:	9a3a                	add	s4,s4,a4
    80006bbe:	000a2783          	lw	a5,0(s4)
    80006bc2:	97ba                	add	a5,a5,a4
    80006bc4:	8782                	jr	a5
        return p->trapframe->ra;
    80006bc6:	0589b783          	ld	a5,88(s3)
    80006bca:	0287aa03          	lw	s4,40(a5)
    struct proc *p = myproc();
    80006bce:	ffffb097          	auipc	ra,0xffffb
    80006bd2:	e56080e7          	jalr	-426(ra) # 80001a24 <myproc>
    80006bd6:	892a                	mv	s2,a0
    if (code >= 0x3A0 && code <= 0x3BF) 
    80006bd8:	c604879b          	addiw	a5,s1,-928
    80006bdc:	0007871b          	sext.w	a4,a5
    80006be0:	46fd                	li	a3,31
    80006be2:	16e6e563          	bltu	a3,a4,80006d4c <trap_and_emulate+0x502>
        if (vmm->exec_mode != M_MODE) 
    80006be6:	00003697          	auipc	a3,0x3
    80006bea:	0826b683          	ld	a3,130(a3) # 80009c68 <vmm>
    80006bee:	4306b583          	ld	a1,1072(a3)
    80006bf2:	4609                	li	a2,2
    80006bf4:	14c59663          	bne	a1,a2,80006d40 <trap_and_emulate+0x4f6>
        if (code >= 0x3a0 && code <= 0x3af) 
    80006bf8:	463d                	li	a2,15
    80006bfa:	5ce67763          	bgeu	a2,a4,800071c8 <trap_and_emulate+0x97e>
            vmm->pmpaddr[pmp_index].val = value;
    80006bfe:	c504879b          	addiw	a5,s1,-944
    80006c02:	02378793          	addi	a5,a5,35
    80006c06:	0792                	slli	a5,a5,0x4
    80006c08:	96be                	add	a3,a3,a5
    80006c0a:	0146b423          	sd	s4,8(a3)
    80006c0e:	b591                	j	80006a52 <trap_and_emulate+0x208>
        return p->trapframe->sp;
    80006c10:	0589b783          	ld	a5,88(s3)
    80006c14:	0307aa03          	lw	s4,48(a5)
    80006c18:	bf5d                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->gp;
    80006c1a:	0589b783          	ld	a5,88(s3)
    80006c1e:	0387aa03          	lw	s4,56(a5)
    80006c22:	b775                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->tp;
    80006c24:	0589b783          	ld	a5,88(s3)
    80006c28:	0407aa03          	lw	s4,64(a5)
    80006c2c:	b74d                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t0;
    80006c2e:	0589b783          	ld	a5,88(s3)
    80006c32:	0487aa03          	lw	s4,72(a5)
    80006c36:	bf61                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t1;
    80006c38:	0589b783          	ld	a5,88(s3)
    80006c3c:	0507aa03          	lw	s4,80(a5)
    80006c40:	b779                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t2;
    80006c42:	0589b783          	ld	a5,88(s3)
    80006c46:	0587aa03          	lw	s4,88(a5)
    80006c4a:	b751                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s0;
    80006c4c:	0589b783          	ld	a5,88(s3)
    80006c50:	0607aa03          	lw	s4,96(a5)
    80006c54:	bfad                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s1;
    80006c56:	0589b783          	ld	a5,88(s3)
    80006c5a:	0687aa03          	lw	s4,104(a5)
    80006c5e:	bf85                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a0;
    80006c60:	0589b783          	ld	a5,88(s3)
    80006c64:	0707aa03          	lw	s4,112(a5)
    80006c68:	b79d                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a1;
    80006c6a:	0589b783          	ld	a5,88(s3)
    80006c6e:	0787aa03          	lw	s4,120(a5)
    80006c72:	bfb1                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a2;
    80006c74:	0589b783          	ld	a5,88(s3)
    80006c78:	0807aa03          	lw	s4,128(a5)
    80006c7c:	bf89                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a3;
    80006c7e:	0589b783          	ld	a5,88(s3)
    80006c82:	0887aa03          	lw	s4,136(a5)
    80006c86:	b7a1                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a4;
    80006c88:	0589b783          	ld	a5,88(s3)
    80006c8c:	0907aa03          	lw	s4,144(a5)
    80006c90:	bf3d                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a5;
    80006c92:	0589b783          	ld	a5,88(s3)
    80006c96:	0987aa03          	lw	s4,152(a5)
    80006c9a:	bf15                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a6;
    80006c9c:	0589b783          	ld	a5,88(s3)
    80006ca0:	0a07aa03          	lw	s4,160(a5)
    80006ca4:	b72d                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->a7;
    80006ca6:	0589b783          	ld	a5,88(s3)
    80006caa:	0a87aa03          	lw	s4,168(a5)
    80006cae:	b705                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s2;
    80006cb0:	0589b783          	ld	a5,88(s3)
    80006cb4:	0b07aa03          	lw	s4,176(a5)
    80006cb8:	bf19                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s3;
    80006cba:	0589b783          	ld	a5,88(s3)
    80006cbe:	0b87aa03          	lw	s4,184(a5)
    80006cc2:	b731                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s4;
    80006cc4:	0589b783          	ld	a5,88(s3)
    80006cc8:	0c07aa03          	lw	s4,192(a5)
    80006ccc:	b709                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s5;
    80006cce:	0589b783          	ld	a5,88(s3)
    80006cd2:	0c87aa03          	lw	s4,200(a5)
    80006cd6:	bde5                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s6;
    80006cd8:	0589b783          	ld	a5,88(s3)
    80006cdc:	0d07aa03          	lw	s4,208(a5)
    80006ce0:	b5fd                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s7;
    80006ce2:	0589b783          	ld	a5,88(s3)
    80006ce6:	0d87aa03          	lw	s4,216(a5)
    80006cea:	b5d5                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s8;
    80006cec:	0589b783          	ld	a5,88(s3)
    80006cf0:	0e07aa03          	lw	s4,224(a5)
    80006cf4:	bde9                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s9;
    80006cf6:	0589b783          	ld	a5,88(s3)
    80006cfa:	0e87aa03          	lw	s4,232(a5)
    80006cfe:	bdc1                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s10;
    80006d00:	0589b783          	ld	a5,88(s3)
    80006d04:	0f07aa03          	lw	s4,240(a5)
    80006d08:	b5d9                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->s11;
    80006d0a:	0589b783          	ld	a5,88(s3)
    80006d0e:	0f87aa03          	lw	s4,248(a5)
    80006d12:	bd75                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t3;
    80006d14:	0589b783          	ld	a5,88(s3)
    80006d18:	1007aa03          	lw	s4,256(a5)
    80006d1c:	bd4d                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t4;
    80006d1e:	0589b783          	ld	a5,88(s3)
    80006d22:	1087aa03          	lw	s4,264(a5)
    80006d26:	b565                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t5;
    80006d28:	0589b783          	ld	a5,88(s3)
    80006d2c:	1107aa03          	lw	s4,272(a5)
    80006d30:	bd79                	j	80006bce <trap_and_emulate+0x384>
        return p->trapframe->t6;
    80006d32:	0589b783          	ld	a5,88(s3)
    80006d36:	1187aa03          	lw	s4,280(a5)
    80006d3a:	bd51                	j	80006bce <trap_and_emulate+0x384>
        if (found_reg != NULL) {
    80006d3c:	4a01                	li	s4,0
    80006d3e:	bd41                	j	80006bce <trap_and_emulate+0x384>
            kill(p->pid);
    80006d40:	5908                	lw	a0,48(a0)
    80006d42:	ffffb097          	auipc	ra,0xffffb
    80006d46:	5c2080e7          	jalr	1474(ra) # 80002304 <kill>
            return;
    80006d4a:	b321                	j	80006a52 <trap_and_emulate+0x208>
    if (code == 0x300) 
    80006d4c:	10500793          	li	a5,261
    80006d50:	2cf48363          	beq	s1,a5,80007016 <trap_and_emulate+0x7cc>
    80006d54:	0c97e363          	bltu	a5,s1,80006e1a <trap_and_emulate+0x5d0>
    80006d58:	04400793          	li	a5,68
    80006d5c:	0697e163          	bltu	a5,s1,80006dbe <trap_and_emulate+0x574>
    80006d60:	6785                	lui	a5,0x1
    80006d62:	fc078793          	addi	a5,a5,-64 # fc0 <_entry-0x7ffff040>
    80006d66:	00fafab3          	and	s5,s5,a5
    80006d6a:	020a9763          	bnez	s5,80006d98 <trap_and_emulate+0x54e>
    80006d6e:	4791                	li	a5,4
    80006d70:	3af48763          	beq	s1,a5,8000711e <trap_and_emulate+0x8d4>
    80006d74:	4795                	li	a5,5
    80006d76:	42f49963          	bne	s1,a5,800071a8 <trap_and_emulate+0x95e>
        if (vmm->exec_mode != U_MODE)
    80006d7a:	00003797          	auipc	a5,0x3
    80006d7e:	eee7b783          	ld	a5,-274(a5) # 80009c68 <vmm>
    80006d82:	4307b783          	ld	a5,1072(a5)
    80006d86:	3c079063          	bnez	a5,80007146 <trap_and_emulate+0x8fc>
        vmm->utvec.val = value;
    80006d8a:	00003797          	auipc	a5,0x3
    80006d8e:	ede7b783          	ld	a5,-290(a5) # 80009c68 <vmm>
    80006d92:	1d47b423          	sd	s4,456(a5)
    80006d96:	b975                	j	80006a52 <trap_and_emulate+0x208>
    80006d98:	fc04879b          	addiw	a5,s1,-64
    80006d9c:	0007869b          	sext.w	a3,a5
    80006da0:	4711                	li	a4,4
    80006da2:	40d76363          	bltu	a4,a3,800071a8 <trap_and_emulate+0x95e>
    80006da6:	02079713          	slli	a4,a5,0x20
    80006daa:	01e75793          	srli	a5,a4,0x1e
    80006dae:	00003717          	auipc	a4,0x3
    80006db2:	e0270713          	addi	a4,a4,-510 # 80009bb0 <syscalls+0x740>
    80006db6:	97ba                	add	a5,a5,a4
    80006db8:	439c                	lw	a5,0(a5)
    80006dba:	97ba                	add	a5,a5,a4
    80006dbc:	8782                	jr	a5
    80006dbe:	10200793          	li	a5,258
    80006dc2:	28f48763          	beq	s1,a5,80007050 <trap_and_emulate+0x806>
    80006dc6:	10400793          	li	a5,260
    80006dca:	02f49363          	bne	s1,a5,80006df0 <trap_and_emulate+0x5a6>
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
    80006dce:	00003797          	auipc	a5,0x3
    80006dd2:	e9a7b783          	ld	a5,-358(a5) # 80009c68 <vmm>
    80006dd6:	4307b783          	ld	a5,1072(a5)
    80006dda:	17fd                	addi	a5,a5,-1
    80006ddc:	4705                	li	a4,1
    80006dde:	22f76663          	bltu	a4,a5,8000700a <trap_and_emulate+0x7c0>
        vmm->sie.val = value;
    80006de2:	00003797          	auipc	a5,0x3
    80006de6:	e867b783          	ld	a5,-378(a5) # 80009c68 <vmm>
    80006dea:	1547bc23          	sd	s4,344(a5)
    80006dee:	b195                	j	80006a52 <trap_and_emulate+0x208>
    80006df0:	10000793          	li	a5,256
    80006df4:	3af49a63          	bne	s1,a5,800071a8 <trap_and_emulate+0x95e>
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
    80006df8:	00003797          	auipc	a5,0x3
    80006dfc:	e707b783          	ld	a5,-400(a5) # 80009c68 <vmm>
    80006e00:	4307b783          	ld	a5,1072(a5)
    80006e04:	17fd                	addi	a5,a5,-1
    80006e06:	4705                	li	a4,1
    80006e08:	1ef76b63          	bltu	a4,a5,80006ffe <trap_and_emulate+0x7b4>
        vmm->sstatus.val = value;
    80006e0c:	00003797          	auipc	a5,0x3
    80006e10:	e5c7b783          	ld	a5,-420(a5) # 80009c68 <vmm>
    80006e14:	1547b423          	sd	s4,328(a5)
    80006e18:	b92d                	j	80006a52 <trap_and_emulate+0x208>
    80006e1a:	30500793          	li	a5,773
    80006e1e:	0697e263          	bltu	a5,s1,80006e82 <trap_and_emulate+0x638>
    80006e22:	2ff00793          	li	a5,767
    80006e26:	0297f563          	bgeu	a5,s1,80006e50 <trap_and_emulate+0x606>
    80006e2a:	d004879b          	addiw	a5,s1,-768
    80006e2e:	0007869b          	sext.w	a3,a5
    80006e32:	4715                	li	a4,5
    80006e34:	36d76a63          	bltu	a4,a3,800071a8 <trap_and_emulate+0x95e>
    80006e38:	02079713          	slli	a4,a5,0x20
    80006e3c:	01e75793          	srli	a5,a4,0x1e
    80006e40:	00003717          	auipc	a4,0x3
    80006e44:	d8470713          	addi	a4,a4,-636 # 80009bc4 <syscalls+0x754>
    80006e48:	97ba                	add	a5,a5,a4
    80006e4a:	439c                	lw	a5,0(a5)
    80006e4c:	97ba                	add	a5,a5,a4
    80006e4e:	8782                	jr	a5
    80006e50:	14100793          	li	a5,321
    80006e54:	32f48363          	beq	s1,a5,8000717a <trap_and_emulate+0x930>
    80006e58:	18000793          	li	a5,384
    80006e5c:	34f49663          	bne	s1,a5,800071a8 <trap_and_emulate+0x95e>
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
    80006e60:	00003797          	auipc	a5,0x3
    80006e64:	e087b783          	ld	a5,-504(a5) # 80009c68 <vmm>
    80006e68:	4307b783          	ld	a5,1072(a5)
    80006e6c:	17fd                	addi	a5,a5,-1
    80006e6e:	4705                	li	a4,1
    80006e70:	1cf76a63          	bltu	a4,a5,80007044 <trap_and_emulate+0x7fa>
        vmm->satp.val = value;
    80006e74:	00003797          	auipc	a5,0x3
    80006e78:	df47b783          	ld	a5,-524(a5) # 80009c68 <vmm>
    80006e7c:	1947b423          	sd	s4,392(a5)
    80006e80:	bec9                	j	80006a52 <trap_and_emulate+0x208>
    80006e82:	34100793          	li	a5,833
    80006e86:	14f48663          	beq	s1,a5,80006fd2 <trap_and_emulate+0x788>
    80006e8a:	34400793          	li	a5,836
    80006e8e:	30f49d63          	bne	s1,a5,800071a8 <trap_and_emulate+0x95e>
        if (vmm->exec_mode != M_MODE)
    80006e92:	00003797          	auipc	a5,0x3
    80006e96:	dd67b783          	ld	a5,-554(a5) # 80009c68 <vmm>
    80006e9a:	4307b703          	ld	a4,1072(a5)
    80006e9e:	4789                	li	a5,2
    80006ea0:	12f71363          	bne	a4,a5,80006fc6 <trap_and_emulate+0x77c>
        vmm->mip.val = value;
    80006ea4:	00003797          	auipc	a5,0x3
    80006ea8:	dc47b783          	ld	a5,-572(a5) # 80009c68 <vmm>
    80006eac:	0747b423          	sd	s4,104(a5)
    80006eb0:	b64d                	j	80006a52 <trap_and_emulate+0x208>
        if (vmm->exec_mode != M_MODE)
    80006eb2:	00003797          	auipc	a5,0x3
    80006eb6:	db67b783          	ld	a5,-586(a5) # 80009c68 <vmm>
    80006eba:	4307b703          	ld	a4,1072(a5)
    80006ebe:	4789                	li	a5,2
    80006ec0:	00f71963          	bne	a4,a5,80006ed2 <trap_and_emulate+0x688>
        vmm->mstatus.val = value;
    80006ec4:	00003797          	auipc	a5,0x3
    80006ec8:	da47b783          	ld	a5,-604(a5) # 80009c68 <vmm>
    80006ecc:	0147bc23          	sd	s4,24(a5)
    80006ed0:	b649                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006ed2:	03092503          	lw	a0,48(s2)
    80006ed6:	ffffb097          	auipc	ra,0xffffb
    80006eda:	42e080e7          	jalr	1070(ra) # 80002304 <kill>
    80006ede:	b7dd                	j	80006ec4 <trap_and_emulate+0x67a>
        if (vmm->exec_mode != M_MODE)
    80006ee0:	00003797          	auipc	a5,0x3
    80006ee4:	d887b783          	ld	a5,-632(a5) # 80009c68 <vmm>
    80006ee8:	4307b703          	ld	a4,1072(a5)
    80006eec:	4789                	li	a5,2
    80006eee:	00f71963          	bne	a4,a5,80006f00 <trap_and_emulate+0x6b6>
        vmm->misa.val = value;
    80006ef2:	00003797          	auipc	a5,0x3
    80006ef6:	d767b783          	ld	a5,-650(a5) # 80009c68 <vmm>
    80006efa:	1147bc23          	sd	s4,280(a5)
    80006efe:	be91                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006f00:	03092503          	lw	a0,48(s2)
    80006f04:	ffffb097          	auipc	ra,0xffffb
    80006f08:	400080e7          	jalr	1024(ra) # 80002304 <kill>
    80006f0c:	b7dd                	j	80006ef2 <trap_and_emulate+0x6a8>
        if (vmm->exec_mode != M_MODE)
    80006f0e:	00003797          	auipc	a5,0x3
    80006f12:	d5a7b783          	ld	a5,-678(a5) # 80009c68 <vmm>
    80006f16:	4307b703          	ld	a4,1072(a5)
    80006f1a:	4789                	li	a5,2
    80006f1c:	00f71963          	bne	a4,a5,80006f2e <trap_and_emulate+0x6e4>
        vmm->medeleg.val = value;
    80006f20:	00003797          	auipc	a5,0x3
    80006f24:	d487b783          	ld	a5,-696(a5) # 80009c68 <vmm>
    80006f28:	0347bc23          	sd	s4,56(a5)
    80006f2c:	b61d                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006f2e:	03092503          	lw	a0,48(s2)
    80006f32:	ffffb097          	auipc	ra,0xffffb
    80006f36:	3d2080e7          	jalr	978(ra) # 80002304 <kill>
    80006f3a:	b7dd                	j	80006f20 <trap_and_emulate+0x6d6>
        if (vmm->exec_mode != M_MODE)
    80006f3c:	00003797          	auipc	a5,0x3
    80006f40:	d2c7b783          	ld	a5,-724(a5) # 80009c68 <vmm>
    80006f44:	4307b703          	ld	a4,1072(a5)
    80006f48:	4789                	li	a5,2
    80006f4a:	00f71963          	bne	a4,a5,80006f5c <trap_and_emulate+0x712>
        vmm->mideleg.val = value;
    80006f4e:	00003797          	auipc	a5,0x3
    80006f52:	d1a7b783          	ld	a5,-742(a5) # 80009c68 <vmm>
    80006f56:	0547b423          	sd	s4,72(a5)
    80006f5a:	bce5                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006f5c:	03092503          	lw	a0,48(s2)
    80006f60:	ffffb097          	auipc	ra,0xffffb
    80006f64:	3a4080e7          	jalr	932(ra) # 80002304 <kill>
    80006f68:	b7dd                	j	80006f4e <trap_and_emulate+0x704>
        if (vmm->exec_mode != M_MODE)
    80006f6a:	00003797          	auipc	a5,0x3
    80006f6e:	cfe7b783          	ld	a5,-770(a5) # 80009c68 <vmm>
    80006f72:	4307b703          	ld	a4,1072(a5)
    80006f76:	4789                	li	a5,2
    80006f78:	00f71963          	bne	a4,a5,80006f8a <trap_and_emulate+0x740>
        vmm->mie.val = value;
    80006f7c:	00003797          	auipc	a5,0x3
    80006f80:	cec7b783          	ld	a5,-788(a5) # 80009c68 <vmm>
    80006f84:	0547bc23          	sd	s4,88(a5)
    80006f88:	b4e9                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006f8a:	03092503          	lw	a0,48(s2)
    80006f8e:	ffffb097          	auipc	ra,0xffffb
    80006f92:	376080e7          	jalr	886(ra) # 80002304 <kill>
    80006f96:	b7dd                	j	80006f7c <trap_and_emulate+0x732>
        if (vmm->exec_mode != M_MODE)
    80006f98:	00003797          	auipc	a5,0x3
    80006f9c:	cd07b783          	ld	a5,-816(a5) # 80009c68 <vmm>
    80006fa0:	4307b703          	ld	a4,1072(a5)
    80006fa4:	4789                	li	a5,2
    80006fa6:	00f71963          	bne	a4,a5,80006fb8 <trap_and_emulate+0x76e>
        vmm->mtvec.val = value;
    80006faa:	00003797          	auipc	a5,0x3
    80006fae:	cbe7b783          	ld	a5,-834(a5) # 80009c68 <vmm>
    80006fb2:	0147b423          	sd	s4,8(a5)
    80006fb6:	bc71                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006fb8:	03092503          	lw	a0,48(s2)
    80006fbc:	ffffb097          	auipc	ra,0xffffb
    80006fc0:	348080e7          	jalr	840(ra) # 80002304 <kill>
    80006fc4:	b7dd                	j	80006faa <trap_and_emulate+0x760>
            kill(p->pid);
    80006fc6:	5908                	lw	a0,48(a0)
    80006fc8:	ffffb097          	auipc	ra,0xffffb
    80006fcc:	33c080e7          	jalr	828(ra) # 80002304 <kill>
    80006fd0:	bdd1                	j	80006ea4 <trap_and_emulate+0x65a>
        if (vmm->exec_mode != M_MODE)
    80006fd2:	00003797          	auipc	a5,0x3
    80006fd6:	c967b783          	ld	a5,-874(a5) # 80009c68 <vmm>
    80006fda:	4307b703          	ld	a4,1072(a5)
    80006fde:	4789                	li	a5,2
    80006fe0:	00f71963          	bne	a4,a5,80006ff2 <trap_and_emulate+0x7a8>
        vmm->mepc.val = value;
    80006fe4:	00003797          	auipc	a5,0x3
    80006fe8:	c847b783          	ld	a5,-892(a5) # 80009c68 <vmm>
    80006fec:	0347b423          	sd	s4,40(a5)
    80006ff0:	b48d                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80006ff2:	5908                	lw	a0,48(a0)
    80006ff4:	ffffb097          	auipc	ra,0xffffb
    80006ff8:	310080e7          	jalr	784(ra) # 80002304 <kill>
    80006ffc:	b7e5                	j	80006fe4 <trap_and_emulate+0x79a>
            kill(p->pid);
    80006ffe:	5908                	lw	a0,48(a0)
    80007000:	ffffb097          	auipc	ra,0xffffb
    80007004:	304080e7          	jalr	772(ra) # 80002304 <kill>
    80007008:	b511                	j	80006e0c <trap_and_emulate+0x5c2>
            kill(p->pid);
    8000700a:	5908                	lw	a0,48(a0)
    8000700c:	ffffb097          	auipc	ra,0xffffb
    80007010:	2f8080e7          	jalr	760(ra) # 80002304 <kill>
    80007014:	b3f9                	j	80006de2 <trap_and_emulate+0x598>
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
    80007016:	00003797          	auipc	a5,0x3
    8000701a:	c527b783          	ld	a5,-942(a5) # 80009c68 <vmm>
    8000701e:	4307b783          	ld	a5,1072(a5)
    80007022:	17fd                	addi	a5,a5,-1
    80007024:	4705                	li	a4,1
    80007026:	00f76963          	bltu	a4,a5,80007038 <trap_and_emulate+0x7ee>
        vmm->stvec.val = value;
    8000702a:	00003797          	auipc	a5,0x3
    8000702e:	c3e7b783          	ld	a5,-962(a5) # 80009c68 <vmm>
    80007032:	1747bc23          	sd	s4,376(a5)
    80007036:	bc31                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80007038:	5908                	lw	a0,48(a0)
    8000703a:	ffffb097          	auipc	ra,0xffffb
    8000703e:	2ca080e7          	jalr	714(ra) # 80002304 <kill>
    80007042:	b7e5                	j	8000702a <trap_and_emulate+0x7e0>
            kill(p->pid);
    80007044:	5908                	lw	a0,48(a0)
    80007046:	ffffb097          	auipc	ra,0xffffb
    8000704a:	2be080e7          	jalr	702(ra) # 80002304 <kill>
    8000704e:	b51d                	j	80006e74 <trap_and_emulate+0x62a>
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
    80007050:	00003797          	auipc	a5,0x3
    80007054:	c187b783          	ld	a5,-1000(a5) # 80009c68 <vmm>
    80007058:	4307b783          	ld	a5,1072(a5)
    8000705c:	17fd                	addi	a5,a5,-1
    8000705e:	4705                	li	a4,1
    80007060:	00f76963          	bltu	a4,a5,80007072 <trap_and_emulate+0x828>
        vmm->sedeleg.val = value;
    80007064:	00003797          	auipc	a5,0x3
    80007068:	c047b783          	ld	a5,-1020(a5) # 80009c68 <vmm>
    8000706c:	1947bc23          	sd	s4,408(a5)
    80007070:	b2cd                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80007072:	5908                	lw	a0,48(a0)
    80007074:	ffffb097          	auipc	ra,0xffffb
    80007078:	290080e7          	jalr	656(ra) # 80002304 <kill>
    8000707c:	b7e5                	j	80007064 <trap_and_emulate+0x81a>
        if (vmm->exec_mode != U_MODE)
    8000707e:	00003797          	auipc	a5,0x3
    80007082:	bea7b783          	ld	a5,-1046(a5) # 80009c68 <vmm>
    80007086:	4307b783          	ld	a5,1072(a5)
    8000708a:	eb81                	bnez	a5,8000709a <trap_and_emulate+0x850>
        vmm->uepc.val = value;
    8000708c:	00003797          	auipc	a5,0x3
    80007090:	bdc7b783          	ld	a5,-1060(a5) # 80009c68 <vmm>
    80007094:	1b47bc23          	sd	s4,440(a5)
    80007098:	ba6d                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    8000709a:	5908                	lw	a0,48(a0)
    8000709c:	ffffb097          	auipc	ra,0xffffb
    800070a0:	268080e7          	jalr	616(ra) # 80002304 <kill>
    800070a4:	b7e5                	j	8000708c <trap_and_emulate+0x842>
        if (vmm->exec_mode != U_MODE)
    800070a6:	00003797          	auipc	a5,0x3
    800070aa:	bc27b783          	ld	a5,-1086(a5) # 80009c68 <vmm>
    800070ae:	4307b783          	ld	a5,1072(a5)
    800070b2:	eb81                	bnez	a5,800070c2 <trap_and_emulate+0x878>
        vmm->ucause.val = value;
    800070b4:	00003797          	auipc	a5,0x3
    800070b8:	bb47b783          	ld	a5,-1100(a5) # 80009c68 <vmm>
    800070bc:	1f47bc23          	sd	s4,504(a5)
    800070c0:	ba49                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    800070c2:	5908                	lw	a0,48(a0)
    800070c4:	ffffb097          	auipc	ra,0xffffb
    800070c8:	240080e7          	jalr	576(ra) # 80002304 <kill>
    800070cc:	b7e5                	j	800070b4 <trap_and_emulate+0x86a>
        if (vmm->exec_mode != U_MODE)
    800070ce:	00003797          	auipc	a5,0x3
    800070d2:	b9a7b783          	ld	a5,-1126(a5) # 80009c68 <vmm>
    800070d6:	4307b783          	ld	a5,1072(a5)
    800070da:	eb81                	bnez	a5,800070ea <trap_and_emulate+0x8a0>
        vmm->uip.val = value;
    800070dc:	00003797          	auipc	a5,0x3
    800070e0:	b8c7b783          	ld	a5,-1140(a5) # 80009c68 <vmm>
    800070e4:	2147bc23          	sd	s4,536(a5)
    800070e8:	b2ad                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    800070ea:	5908                	lw	a0,48(a0)
    800070ec:	ffffb097          	auipc	ra,0xffffb
    800070f0:	218080e7          	jalr	536(ra) # 80002304 <kill>
    800070f4:	b7e5                	j	800070dc <trap_and_emulate+0x892>
        if (vmm->exec_mode != U_MODE)
    800070f6:	00003797          	auipc	a5,0x3
    800070fa:	b727b783          	ld	a5,-1166(a5) # 80009c68 <vmm>
    800070fe:	4307b783          	ld	a5,1072(a5)
    80007102:	eb81                	bnez	a5,80007112 <trap_and_emulate+0x8c8>
        vmm->ubadaddr.val = value;
    80007104:	00003797          	auipc	a5,0x3
    80007108:	b647b783          	ld	a5,-1180(a5) # 80009c68 <vmm>
    8000710c:	2147b423          	sd	s4,520(a5)
    80007110:	b289                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    80007112:	5908                	lw	a0,48(a0)
    80007114:	ffffb097          	auipc	ra,0xffffb
    80007118:	1f0080e7          	jalr	496(ra) # 80002304 <kill>
    8000711c:	b7e5                	j	80007104 <trap_and_emulate+0x8ba>
        if (vmm->exec_mode != U_MODE)
    8000711e:	00003797          	auipc	a5,0x3
    80007122:	b4a7b783          	ld	a5,-1206(a5) # 80009c68 <vmm>
    80007126:	4307b783          	ld	a5,1072(a5)
    8000712a:	eb81                	bnez	a5,8000713a <trap_and_emulate+0x8f0>
        vmm->uie.val = value;
    8000712c:	00003797          	auipc	a5,0x3
    80007130:	b3c7b783          	ld	a5,-1220(a5) # 80009c68 <vmm>
    80007134:	2347b423          	sd	s4,552(a5)
    80007138:	ba29                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    8000713a:	5908                	lw	a0,48(a0)
    8000713c:	ffffb097          	auipc	ra,0xffffb
    80007140:	1c8080e7          	jalr	456(ra) # 80002304 <kill>
    80007144:	b7e5                	j	8000712c <trap_and_emulate+0x8e2>
            kill(p->pid);
    80007146:	5908                	lw	a0,48(a0)
    80007148:	ffffb097          	auipc	ra,0xffffb
    8000714c:	1bc080e7          	jalr	444(ra) # 80002304 <kill>
    80007150:	b92d                	j	80006d8a <trap_and_emulate+0x540>
        if (vmm->exec_mode != U_MODE)
    80007152:	00003797          	auipc	a5,0x3
    80007156:	b167b783          	ld	a5,-1258(a5) # 80009c68 <vmm>
    8000715a:	4307b783          	ld	a5,1072(a5)
    8000715e:	eb81                	bnez	a5,8000716e <trap_and_emulate+0x924>
        vmm->uscratch.val = value;
    80007160:	00003797          	auipc	a5,0x3
    80007164:	b087b783          	ld	a5,-1272(a5) # 80009c68 <vmm>
    80007168:	1d47bc23          	sd	s4,472(a5)
    8000716c:	b0dd                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    8000716e:	5908                	lw	a0,48(a0)
    80007170:	ffffb097          	auipc	ra,0xffffb
    80007174:	194080e7          	jalr	404(ra) # 80002304 <kill>
    80007178:	b7e5                	j	80007160 <trap_and_emulate+0x916>
        if (vmm->exec_mode != S_MODE && vmm->exec_mode != M_MODE)
    8000717a:	00003797          	auipc	a5,0x3
    8000717e:	aee7b783          	ld	a5,-1298(a5) # 80009c68 <vmm>
    80007182:	4307b783          	ld	a5,1072(a5)
    80007186:	17fd                	addi	a5,a5,-1
    80007188:	4705                	li	a4,1
    8000718a:	00f76963          	bltu	a4,a5,8000719c <trap_and_emulate+0x952>
        vmm->sepc.val = value;
    8000718e:	00003797          	auipc	a5,0x3
    80007192:	ada7b783          	ld	a5,-1318(a5) # 80009c68 <vmm>
    80007196:	1747b423          	sd	s4,360(a5)
    8000719a:	b865                	j	80006a52 <trap_and_emulate+0x208>
            kill(p->pid);
    8000719c:	5908                	lw	a0,48(a0)
    8000719e:	ffffb097          	auipc	ra,0xffffb
    800071a2:	166080e7          	jalr	358(ra) # 80002304 <kill>
    800071a6:	b7e5                	j	8000718e <trap_and_emulate+0x944>
        printf("Invalid code could not update!!!!: %x\n", code);
    800071a8:	85a6                	mv	a1,s1
    800071aa:	00003517          	auipc	a0,0x3
    800071ae:	87650513          	addi	a0,a0,-1930 # 80009a20 <syscalls+0x5b0>
    800071b2:	ffff9097          	auipc	ra,0xffff9
    800071b6:	3d8080e7          	jalr	984(ra) # 8000058a <printf>
        kill(p->pid);
    800071ba:	03092503          	lw	a0,48(s2)
    800071be:	ffffb097          	auipc	ra,0xffffb
    800071c2:	146080e7          	jalr	326(ra) # 80002304 <kill>
    800071c6:	b071                	j	80006a52 <trap_and_emulate+0x208>
            vmm->pmpcfg[pmp_index].val = value;
    800071c8:	2781                	sext.w	a5,a5
    800071ca:	03378793          	addi	a5,a5,51
    800071ce:	0792                	slli	a5,a5,0x4
    800071d0:	96be                	add	a3,a3,a5
    800071d2:	0146b423          	sd	s4,8(a3)
    800071d6:	b8b5                	j	80006a52 <trap_and_emulate+0x208>
            printf("Incorrect CSR code %x for execution mode as : %d\n", uimm, vmm->exec_mode);
    800071d8:	85a6                	mv	a1,s1
    800071da:	00003517          	auipc	a0,0x3
    800071de:	89650513          	addi	a0,a0,-1898 # 80009a70 <syscalls+0x600>
    800071e2:	ffff9097          	auipc	ra,0xffff9
    800071e6:	3a8080e7          	jalr	936(ra) # 8000058a <printf>
            kill(p->pid);
    800071ea:	0309a503          	lw	a0,48(s3)
    800071ee:	ffffb097          	auipc	ra,0xffffb
    800071f2:	116080e7          	jalr	278(ra) # 80002304 <kill>
        p->trapframe->epc += 4;
    800071f6:	0589b703          	ld	a4,88(s3)
    800071fa:	6f1c                	ld	a5,24(a4)
    800071fc:	0791                	addi	a5,a5,4
    800071fe:	ef1c                	sd	a5,24(a4)
    80007200:	f02ff06f          	j	80006902 <trap_and_emulate+0xb8>

0000000080007204 <trap_and_emulate_init>:

// Initialize the VM privileged state with specific code, mode, and val for each register
void trap_and_emulate_init(void) {
    80007204:	1141                	addi	sp,sp,-16
    80007206:	e406                	sd	ra,8(sp)
    80007208:	e022                	sd	s0,0(sp)
    8000720a:	0800                	addi	s0,sp,16
    //printf("Allocating the memory\n");
    vmm = (struct vm_virtual_state*)kalloc();
    8000720c:	ffffa097          	auipc	ra,0xffffa
    80007210:	94c080e7          	jalr	-1716(ra) # 80000b58 <kalloc>
    80007214:	00003797          	auipc	a5,0x3
    80007218:	a4a7ba23          	sd	a0,-1452(a5) # 80009c68 <vmm>
    if(vmm == NULL){
    8000721c:	48050863          	beqz	a0,800076ac <trap_and_emulate_init+0x4a8>
        panic("Could not allocate memory");
    }

    memset(vmm, 0, sizeof(struct vm_virtual_state));
    80007220:	44800613          	li	a2,1096
    80007224:	4581                	li	a1,0
    80007226:	ffffa097          	auipc	ra,0xffffa
    8000722a:	b1e080e7          	jalr	-1250(ra) # 80000d44 <memset>

    vmm->mtval2.code = 0x34B;
    8000722e:	00003797          	auipc	a5,0x3
    80007232:	a3a7b783          	ld	a5,-1478(a5) # 80009c68 <vmm>
    80007236:	34b00713          	li	a4,843
    8000723a:	dbb8                	sw	a4,112(a5)
    vmm->mtval2.mode = M_MODE;
    8000723c:	4709                	li	a4,2
    8000723e:	dbf8                	sw	a4,116(a5)
    vmm->mtval2.val = 0;
    80007240:	0607bc23          	sd	zero,120(a5)

    vmm->mcause.code = 0x342;
    80007244:	34200693          	li	a3,834
    80007248:	0ed7a823          	sw	a3,240(a5)
    vmm->mcause.mode = M_MODE;
    8000724c:	0ee7aa23          	sw	a4,244(a5)
    vmm->mcause.val = 0;
    80007250:	0e07bc23          	sd	zero,248(a5)

    vmm->mstatush.code = 0x310;
    80007254:	31000693          	li	a3,784
    80007258:	08d7a823          	sw	a3,144(a5)
    vmm->mstatush.mode = M_MODE;
    8000725c:	08e7aa23          	sw	a4,148(a5)
    vmm->mstatush.val = 0;
    80007260:	0807bc23          	sd	zero,152(a5)

    vmm->mvendorid.code = 0xf11;
    80007264:	6685                	lui	a3,0x1
    80007266:	f1168613          	addi	a2,a3,-239 # f11 <_entry-0x7ffff0ef>
    8000726a:	0ac7a023          	sw	a2,160(a5)
    vmm->mvendorid.mode = M_MODE;
    8000726e:	0ae7a223          	sw	a4,164(a5)
    vmm->mvendorid.val = 0x637365353336;
    80007272:	00002617          	auipc	a2,0x2
    80007276:	d9663603          	ld	a2,-618(a2) # 80009008 <etext+0x8>
    8000727a:	f7d0                	sd	a2,168(a5)

    vmm->marchid.code = 0xf12;
    8000727c:	f1268613          	addi	a2,a3,-238
    80007280:	0ac7a823          	sw	a2,176(a5)
    vmm->marchid.mode = M_MODE;
    80007284:	0ae7aa23          	sw	a4,180(a5)
    vmm->marchid.val = 0;
    80007288:	0a07bc23          	sd	zero,184(a5)

    vmm->mimpid.code = 0xf13;
    8000728c:	f1368613          	addi	a2,a3,-237
    80007290:	0cc7a023          	sw	a2,192(a5)
    vmm->mimpid.mode = M_MODE;
    80007294:	0ce7a223          	sw	a4,196(a5)
    vmm->mimpid.val = 0;
    80007298:	0c07b423          	sd	zero,200(a5)

    vmm->mhartid.code = 0xf14;
    8000729c:	f1468613          	addi	a2,a3,-236
    800072a0:	0cc7a823          	sw	a2,208(a5)
    vmm->mhartid.mode = M_MODE;
    800072a4:	0ce7aa23          	sw	a4,212(a5)
    vmm->mhartid.val = 0;
    800072a8:	0c07bc23          	sd	zero,216(a5)

    vmm->mconfigptr.code = 0xf15;
    800072ac:	f1568693          	addi	a3,a3,-235
    800072b0:	0ed7a023          	sw	a3,224(a5)
    vmm->mconfigptr.mode = M_MODE;
    800072b4:	0ee7a223          	sw	a4,228(a5)
    vmm->mconfigptr.val = 0;
    800072b8:	0e07b423          	sd	zero,232(a5)

    vmm->mtvec.code = 0x305;
    800072bc:	30500693          	li	a3,773
    800072c0:	c394                	sw	a3,0(a5)
    vmm->mtvec.mode = M_MODE;
    800072c2:	c3d8                	sw	a4,4(a5)
    vmm->mtvec.val = 0;
    800072c4:	0007b423          	sd	zero,8(a5)

    vmm->mstatus.code = 0x300;
    800072c8:	30000693          	li	a3,768
    800072cc:	cb94                	sw	a3,16(a5)
    vmm->mstatus.mode = M_MODE;
    800072ce:	cbd8                	sw	a4,20(a5)
    vmm->mstatus.val = 0;
    800072d0:	0007bc23          	sd	zero,24(a5)

    vmm->mepc.code = 0x341;
    800072d4:	34100693          	li	a3,833
    800072d8:	d394                	sw	a3,32(a5)
    vmm->mepc.mode = M_MODE;
    800072da:	d3d8                	sw	a4,36(a5)
    vmm->mepc.val = 0;
    800072dc:	0207b423          	sd	zero,40(a5)

    vmm->medeleg.code = 0x302;
    800072e0:	30200693          	li	a3,770
    800072e4:	db94                	sw	a3,48(a5)
    vmm->medeleg.mode = M_MODE;
    800072e6:	dbd8                	sw	a4,52(a5)
    vmm->medeleg.val = 0;
    800072e8:	0207bc23          	sd	zero,56(a5)

    vmm->mideleg.code = 0x303;
    800072ec:	30300693          	li	a3,771
    800072f0:	c3b4                	sw	a3,64(a5)
    vmm->mideleg.mode = M_MODE;
    800072f2:	c3f8                	sw	a4,68(a5)
    vmm->mideleg.val = 0;
    800072f4:	0407b423          	sd	zero,72(a5)

    vmm->mie.code = 0x304;
    800072f8:	30400693          	li	a3,772
    800072fc:	cbb4                	sw	a3,80(a5)
    vmm->mie.mode = M_MODE; 
    800072fe:	cbf8                	sw	a4,84(a5)
    vmm->mie.val = 0;
    80007300:	0407bc23          	sd	zero,88(a5)

    vmm->mip.code = 0x344;
    80007304:	34400693          	li	a3,836
    80007308:	d3b4                	sw	a3,96(a5)
    vmm->mip.mode = M_MODE;
    8000730a:	d3f8                	sw	a4,100(a5)
    vmm->mip.val = 0;
    8000730c:	0607b423          	sd	zero,104(a5)

    vmm->mcounteren.code = 0x306;
    80007310:	30600693          	li	a3,774
    80007314:	08d7a023          	sw	a3,128(a5)
    vmm->mcounteren.mode = M_MODE;
    80007318:	08e7a223          	sw	a4,132(a5)
    vmm->mcounteren.val = 0;
    8000731c:	0807b423          	sd	zero,136(a5)

    vmm->mscratch.code = 0x140;
    80007320:	14000693          	li	a3,320
    80007324:	10d7a023          	sw	a3,256(a5)
    vmm->mscratch.mode = M_MODE;
    80007328:	10e7a223          	sw	a4,260(a5)
    vmm->mscratch.val = 0;
    8000732c:	1007b423          	sd	zero,264(a5)

    vmm->misa.code = 0x301;
    80007330:	30100693          	li	a3,769
    80007334:	10d7a823          	sw	a3,272(a5)
    vmm->misa.mode = M_MODE;
    80007338:	10e7aa23          	sw	a4,276(a5)
    vmm->misa.val = 0;
    8000733c:	1007bc23          	sd	zero,280(a5)

    vmm->mtval.code = 0x343;
    80007340:	34300693          	li	a3,835
    80007344:	12d7a023          	sw	a3,288(a5)
    vmm->mtval.mode = M_MODE;
    80007348:	12e7a223          	sw	a4,292(a5)
    vmm->mtval.val = 0;
    8000734c:	1207b423          	sd	zero,296(a5)

    vmm->mtinst.code = 0x34A;
    80007350:	34a00693          	li	a3,842
    80007354:	12d7a823          	sw	a3,304(a5)
    vmm->mtinst.mode = M_MODE;
    80007358:	12e7aa23          	sw	a4,308(a5)
    vmm->mtinst.val = 0;
    8000735c:	1207bc23          	sd	zero,312(a5)

    vmm->sstatus.code = 0x100;
    80007360:	10000713          	li	a4,256
    80007364:	14e7a023          	sw	a4,320(a5)
    vmm->sstatus.mode = S_MODE;
    80007368:	4705                	li	a4,1
    8000736a:	14e7a223          	sw	a4,324(a5)
    vmm->sstatus.val = 0;
    8000736e:	1407b423          	sd	zero,328(a5)

    vmm->sedeleg.code = 0x102;
    80007372:	10200693          	li	a3,258
    80007376:	18d7a823          	sw	a3,400(a5)
    vmm->sedeleg.mode = S_MODE;
    8000737a:	18e7aa23          	sw	a4,404(a5)
    vmm->sedeleg.val = 0;
    8000737e:	1807bc23          	sd	zero,408(a5)

    vmm->sie.code = 0x104;
    80007382:	10400693          	li	a3,260
    80007386:	14d7a823          	sw	a3,336(a5)
    vmm->sie.mode = S_MODE;
    8000738a:	14e7aa23          	sw	a4,340(a5)
    vmm->sie.val = 0;
    8000738e:	1407bc23          	sd	zero,344(a5)

    vmm->stvec.code = 0x105;
    80007392:	10500693          	li	a3,261
    80007396:	16d7a823          	sw	a3,368(a5)
    vmm->stvec.mode = S_MODE;
    8000739a:	16e7aa23          	sw	a4,372(a5)
    vmm->stvec.val = 0;
    8000739e:	1607bc23          	sd	zero,376(a5)

    vmm->scounteren.code = 0x106;
    800073a2:	10600693          	li	a3,262
    800073a6:	1ad7a023          	sw	a3,416(a5)
    vmm->scounteren.mode = S_MODE;
    800073aa:	1ae7a223          	sw	a4,420(a5)
    vmm->scounteren.val = 0;
    800073ae:	1a07b423          	sd	zero,424(a5)

    vmm->sepc.code = 0x141;
    800073b2:	14100693          	li	a3,321
    800073b6:	16d7a023          	sw	a3,352(a5)
    vmm->sepc.mode = S_MODE;
    800073ba:	16e7a223          	sw	a4,356(a5)
    vmm->sepc.val = 0;
    800073be:	1607b423          	sd	zero,360(a5)

    vmm->satp.code = 0x180;
    800073c2:	18000693          	li	a3,384
    800073c6:	18d7a023          	sw	a3,384(a5)
    vmm->satp.mode = S_MODE;
    800073ca:	18e7a223          	sw	a4,388(a5)
    vmm->satp.val = 0;
    800073ce:	1807b423          	sd	zero,392(a5)

    vmm->uepc.code = 0x041;
    800073d2:	04100713          	li	a4,65
    800073d6:	1ae7a823          	sw	a4,432(a5)
    vmm->uepc.mode = U_MODE;
    800073da:	1a07aa23          	sw	zero,436(a5)
    vmm->uepc.val = 0;
    800073de:	1a07bc23          	sd	zero,440(a5)

    vmm->ucause.code = 0x042;
    800073e2:	04200713          	li	a4,66
    800073e6:	1ee7a823          	sw	a4,496(a5)
    vmm->ucause.mode = U_MODE;
    800073ea:	1e07aa23          	sw	zero,500(a5)
    vmm->ucause.val = 0;
    800073ee:	1e07bc23          	sd	zero,504(a5)

    vmm->ubadaddr.code = 0x043;
    800073f2:	04300713          	li	a4,67
    800073f6:	20e7a023          	sw	a4,512(a5)
    vmm->ubadaddr.mode = U_MODE;
    800073fa:	2007a223          	sw	zero,516(a5)
    vmm->ubadaddr.val = 0;
    800073fe:	2007b423          	sd	zero,520(a5)

    vmm->uip.code = 0x044;
    80007402:	04400713          	li	a4,68
    80007406:	20e7a823          	sw	a4,528(a5)
    vmm->uip.mode = U_MODE;
    8000740a:	2007aa23          	sw	zero,532(a5)
    vmm->uip.val = 0;
    8000740e:	2007bc23          	sd	zero,536(a5)

    vmm->ustatus.code = 0x000; 
    80007412:	1e07a023          	sw	zero,480(a5)
    vmm->ustatus.mode = U_MODE;
    80007416:	1e07a223          	sw	zero,484(a5)
    vmm->ustatus.val = 0;
    8000741a:	1e07b423          	sd	zero,488(a5)

    vmm->uie.code = 0x004;
    8000741e:	4711                	li	a4,4
    80007420:	22e7a023          	sw	a4,544(a5)
    vmm->uie.mode = U_MODE;
    80007424:	2207a223          	sw	zero,548(a5)
    vmm->uie.val = 0;
    80007428:	2207b423          	sd	zero,552(a5)

    vmm->utvec.code = 0x005;
    8000742c:	4715                	li	a4,5
    8000742e:	1ce7a023          	sw	a4,448(a5)
    vmm->utvec.mode = U_MODE;
    80007432:	1c07a223          	sw	zero,452(a5)
    vmm->utvec.val = 0;
    80007436:	1c07b423          	sd	zero,456(a5)

    vmm->uscratch.code = 0x040;
    8000743a:	04000713          	li	a4,64
    8000743e:	1ce7a823          	sw	a4,464(a5)
    vmm->uscratch.mode = U_MODE;
    80007442:	1c07aa23          	sw	zero,468(a5)
    vmm->uscratch.val = 0;
    80007446:	1c07bc23          	sd	zero,472(a5)

    for (int i = 0; i < 16; i++) {
    8000744a:	23078713          	addi	a4,a5,560
    vmm->uscratch.val = 0;
    8000744e:	3a000693          	li	a3,928
        vmm->pmpcfg[i].code = 0x3a0 + i;
        vmm->pmpcfg[i].val = 0;
        vmm->pmpcfg[i].mode = M_MODE;
    80007452:	4609                	li	a2,2
    for (int i = 0; i < 16; i++) {
    80007454:	3b000513          	li	a0,944
        vmm->pmpcfg[i].code = 0x3a0 + i;
    80007458:	10d72023          	sw	a3,256(a4)
        vmm->pmpcfg[i].val = 0;
    8000745c:	10073423          	sd	zero,264(a4)
        vmm->pmpcfg[i].mode = M_MODE;
    80007460:	10c72223          	sw	a2,260(a4)

        vmm->pmpaddr[i].code = 0x3b0 + i;
    80007464:	0106859b          	addiw	a1,a3,16
    80007468:	c30c                	sw	a1,0(a4)
        vmm->pmpaddr[i].val = 0;
    8000746a:	00073423          	sd	zero,8(a4)
        vmm->pmpaddr[i].mode = M_MODE;
    8000746e:	c350                	sw	a2,4(a4)
    for (int i = 0; i < 16; i++) {
    80007470:	2685                	addiw	a3,a3,1
    80007472:	0741                	addi	a4,a4,16
    80007474:	fea692e3          	bne	a3,a0,80007458 <trap_and_emulate_init+0x254>
    csr_register_map_values[0]  = (struct csr_register_map){ 0x305, &vmm->mtvec };
    80007478:	0001c717          	auipc	a4,0x1c
    8000747c:	e7870713          	addi	a4,a4,-392 # 800232f0 <csr_register_map_values>
    80007480:	30500693          	li	a3,773
    80007484:	c314                	sw	a3,0(a4)
    80007486:	e71c                	sd	a5,8(a4)
    csr_register_map_values[1]  = (struct csr_register_map){ 0xf14, &vmm->mhartid };
    80007488:	6685                	lui	a3,0x1
    8000748a:	f1468613          	addi	a2,a3,-236 # f14 <_entry-0x7ffff0ec>
    8000748e:	cb10                	sw	a2,16(a4)
    80007490:	0d078613          	addi	a2,a5,208
    80007494:	ef10                	sd	a2,24(a4)
    csr_register_map_values[2]  = (struct csr_register_map){ 0x300, &vmm->mstatus };
    80007496:	30000613          	li	a2,768
    8000749a:	d310                	sw	a2,32(a4)
    8000749c:	01078613          	addi	a2,a5,16
    800074a0:	f710                	sd	a2,40(a4)
    csr_register_map_values[3]  = (struct csr_register_map){ 0x341, &vmm->mepc };
    800074a2:	34100613          	li	a2,833
    800074a6:	db10                	sw	a2,48(a4)
    800074a8:	02078613          	addi	a2,a5,32
    800074ac:	ff10                	sd	a2,56(a4)
    csr_register_map_values[4]  = (struct csr_register_map){ 0x302, &vmm->medeleg };
    800074ae:	30200613          	li	a2,770
    800074b2:	c330                	sw	a2,64(a4)
    800074b4:	03078613          	addi	a2,a5,48
    800074b8:	e730                	sd	a2,72(a4)
    csr_register_map_values[5]  = (struct csr_register_map){ 0x303, &vmm->mideleg };
    800074ba:	30300613          	li	a2,771
    800074be:	cb30                	sw	a2,80(a4)
    800074c0:	04078613          	addi	a2,a5,64
    800074c4:	ef30                	sd	a2,88(a4)
    csr_register_map_values[6]  = (struct csr_register_map){ 0xf11, &vmm->mvendorid };
    800074c6:	f1168613          	addi	a2,a3,-239
    800074ca:	d330                	sw	a2,96(a4)
    800074cc:	0a078613          	addi	a2,a5,160
    800074d0:	f730                	sd	a2,104(a4)
    csr_register_map_values[7]  = (struct csr_register_map){ 0x140, &vmm->mscratch };
    800074d2:	14000613          	li	a2,320
    800074d6:	db30                	sw	a2,112(a4)
    800074d8:	10078613          	addi	a2,a5,256
    800074dc:	ff30                	sd	a2,120(a4)
    csr_register_map_values[8]  = (struct csr_register_map){ 0x342, &vmm->mcause };
    800074de:	34200613          	li	a2,834
    800074e2:	08c72023          	sw	a2,128(a4)
    800074e6:	0f078613          	addi	a2,a5,240
    800074ea:	e750                	sd	a2,136(a4)
    csr_register_map_values[9]  = (struct csr_register_map){ 0x343, &vmm->mtval };
    800074ec:	34300613          	li	a2,835
    800074f0:	08c72823          	sw	a2,144(a4)
    800074f4:	12078613          	addi	a2,a5,288
    800074f8:	ef50                	sd	a2,152(a4)
    csr_register_map_values[10] = (struct csr_register_map){ 0x344, &vmm->mip };
    800074fa:	34400613          	li	a2,836
    800074fe:	0ac72023          	sw	a2,160(a4)
    80007502:	06078613          	addi	a2,a5,96
    80007506:	f750                	sd	a2,168(a4)
    csr_register_map_values[11] = (struct csr_register_map){ 0x34A, &vmm->mtinst };
    80007508:	34a00613          	li	a2,842
    8000750c:	0ac72823          	sw	a2,176(a4)
    80007510:	13078613          	addi	a2,a5,304
    80007514:	ff50                	sd	a2,184(a4)
    csr_register_map_values[12] = (struct csr_register_map){ 0x301, &vmm->misa };
    80007516:	30100613          	li	a2,769
    8000751a:	0cc72023          	sw	a2,192(a4)
    8000751e:	11078613          	addi	a2,a5,272
    80007522:	e770                	sd	a2,200(a4)
    csr_register_map_values[13] = (struct csr_register_map){ 0x304, &vmm->mie };
    80007524:	30400613          	li	a2,772
    80007528:	0cc72823          	sw	a2,208(a4)
    8000752c:	05078613          	addi	a2,a5,80
    80007530:	ef70                	sd	a2,216(a4)
    csr_register_map_values[14] = (struct csr_register_map){ 0x306, &vmm->mcounteren };
    80007532:	30600613          	li	a2,774
    80007536:	0ec72023          	sw	a2,224(a4)
    8000753a:	08078613          	addi	a2,a5,128
    8000753e:	f770                	sd	a2,232(a4)
    csr_register_map_values[15] = (struct csr_register_map){ 0xf12, &vmm->marchid };
    80007540:	f1268613          	addi	a2,a3,-238
    80007544:	0ec72823          	sw	a2,240(a4)
    80007548:	0b078613          	addi	a2,a5,176
    8000754c:	ff70                	sd	a2,248(a4)
    csr_register_map_values[16] = (struct csr_register_map){ 0xf13, &vmm->mimpid };
    8000754e:	f1368613          	addi	a2,a3,-237
    80007552:	10c72023          	sw	a2,256(a4)
    80007556:	0c078613          	addi	a2,a5,192
    8000755a:	10c73423          	sd	a2,264(a4)
    csr_register_map_values[17] = (struct csr_register_map){ 0xf15, &vmm->mconfigptr };
    8000755e:	f1568693          	addi	a3,a3,-235
    80007562:	10d72823          	sw	a3,272(a4)
    80007566:	0e078693          	addi	a3,a5,224
    8000756a:	10d73c23          	sd	a3,280(a4)
    csr_register_map_values[18] = (struct csr_register_map){ 0x180, &vmm->satp };
    8000756e:	18000693          	li	a3,384
    80007572:	12d72023          	sw	a3,288(a4)
    80007576:	18078693          	addi	a3,a5,384
    8000757a:	12d73423          	sd	a3,296(a4)
    csr_register_map_values[19] = (struct csr_register_map){ 0x104, &vmm->sie };
    8000757e:	10400693          	li	a3,260
    80007582:	12d72823          	sw	a3,304(a4)
    80007586:	15078693          	addi	a3,a5,336
    8000758a:	12d73c23          	sd	a3,312(a4)
    csr_register_map_values[20] = (struct csr_register_map){ 0x105, &vmm->stvec };
    8000758e:	10500693          	li	a3,261
    80007592:	14d72023          	sw	a3,320(a4)
    80007596:	17078693          	addi	a3,a5,368
    8000759a:	14d73423          	sd	a3,328(a4)
    csr_register_map_values[21] = (struct csr_register_map){ 0x100, &vmm->sstatus };
    8000759e:	10000693          	li	a3,256
    800075a2:	14d72823          	sw	a3,336(a4)
    800075a6:	14078693          	addi	a3,a5,320
    800075aa:	14d73c23          	sd	a3,344(a4)
    csr_register_map_values[22] = (struct csr_register_map){ 0x102, &vmm->sedeleg };
    800075ae:	10200693          	li	a3,258
    800075b2:	16d72023          	sw	a3,352(a4)
    800075b6:	19078693          	addi	a3,a5,400
    800075ba:	16d73423          	sd	a3,360(a4)
    csr_register_map_values[23] = (struct csr_register_map){ 0x106, &vmm->scounteren };
    800075be:	10600693          	li	a3,262
    800075c2:	16d72823          	sw	a3,368(a4)
    800075c6:	1a078693          	addi	a3,a5,416
    800075ca:	16d73c23          	sd	a3,376(a4)
    csr_register_map_values[24] = (struct csr_register_map){ 0x041, &vmm->uepc };
    800075ce:	04100693          	li	a3,65
    800075d2:	18d72023          	sw	a3,384(a4)
    800075d6:	1b078693          	addi	a3,a5,432
    800075da:	18d73423          	sd	a3,392(a4)
    csr_register_map_values[25] = (struct csr_register_map){ 0x042, &vmm->ucause };
    800075de:	04200693          	li	a3,66
    800075e2:	18d72823          	sw	a3,400(a4)
    800075e6:	1f078693          	addi	a3,a5,496
    800075ea:	18d73c23          	sd	a3,408(a4)
    csr_register_map_values[26] = (struct csr_register_map){ 0x043, &vmm->ubadaddr };
    800075ee:	04300693          	li	a3,67
    800075f2:	1ad72023          	sw	a3,416(a4)
    800075f6:	20078693          	addi	a3,a5,512
    800075fa:	1ad73423          	sd	a3,424(a4)
    csr_register_map_values[27] = (struct csr_register_map){ 0x044, &vmm->uip };
    800075fe:	04400693          	li	a3,68
    80007602:	1ad72823          	sw	a3,432(a4)
    80007606:	21078693          	addi	a3,a5,528
    8000760a:	1ad73c23          	sd	a3,440(a4)
    csr_register_map_values[28] = (struct csr_register_map){ 0x004, &vmm->uie };
    8000760e:	4691                	li	a3,4
    80007610:	1cd72023          	sw	a3,448(a4)
    80007614:	22078693          	addi	a3,a5,544
    80007618:	1cd73423          	sd	a3,456(a4)
    csr_register_map_values[29] = (struct csr_register_map){ 0x005, &vmm->utvec };
    8000761c:	4695                	li	a3,5
    8000761e:	1cd72823          	sw	a3,464(a4)
    80007622:	1c078693          	addi	a3,a5,448
    80007626:	1cd73c23          	sd	a3,472(a4)
    csr_register_map_values[30] = (struct csr_register_map){ 0x040, &vmm->uscratch };
    8000762a:	04000693          	li	a3,64
    8000762e:	1ed72023          	sw	a3,480(a4)
    80007632:	1d078693          	addi	a3,a5,464
    80007636:	1ed73423          	sd	a3,488(a4)
    csr_register_map_values[31] = (struct csr_register_map){ 0x34B, &vmm->mtval2 };
    8000763a:	34b00693          	li	a3,843
    8000763e:	1ed72823          	sw	a3,496(a4)
    80007642:	07078693          	addi	a3,a5,112
    80007646:	1ed73c23          	sd	a3,504(a4)
    csr_register_map_values[32] = (struct csr_register_map){ 0x141, &vmm->sepc };
    8000764a:	14100693          	li	a3,321
    8000764e:	20d72023          	sw	a3,512(a4)
    80007652:	16078693          	addi	a3,a5,352
    80007656:	20d73423          	sd	a3,520(a4)
    csr_register_map_values[33] = (struct csr_register_map){ 0x34C, NULL }; 
    8000765a:	34c00693          	li	a3,844
    8000765e:	20d72823          	sw	a3,528(a4)
    80007662:	20073c23          	sd	zero,536(a4)
    csr_register_map_values[34] = (struct csr_register_map){ 0x000, NULL }; 
    80007666:	22072023          	sw	zero,544(a4)
    8000766a:	22073423          	sd	zero,552(a4)
    for(int i = 0; i < 16; i++) {
    8000766e:	0001c717          	auipc	a4,0x1c
    80007672:	eb270713          	addi	a4,a4,-334 # 80023520 <csr_register_map_values+0x230>
    80007676:	33078613          	addi	a2,a5,816
    csr_register_map_values[34] = (struct csr_register_map){ 0x000, NULL }; 
    8000767a:	3a000693          	li	a3,928
    for(int i = 0; i < 16; i++) {
    8000767e:	3b000513          	li	a0,944
        csr_register_map_values[index++] = (struct csr_register_map){ 0x3a0 + i, &vmm->pmpcfg[i] };
    80007682:	c314                	sw	a3,0(a4)
    80007684:	e710                	sd	a2,8(a4)
        csr_register_map_values[index++] = (struct csr_register_map){ 0x3b0 + i, &vmm->pmpaddr[i] };
    80007686:	0106859b          	addiw	a1,a3,16
    8000768a:	cb0c                	sw	a1,16(a4)
    8000768c:	f0060593          	addi	a1,a2,-256
    80007690:	ef0c                	sd	a1,24(a4)
    for(int i = 0; i < 16; i++) {
    80007692:	2685                	addiw	a3,a3,1
    80007694:	02070713          	addi	a4,a4,32
    80007698:	0641                	addi	a2,a2,16
    8000769a:	fea694e3          	bne	a3,a0,80007682 <trap_and_emulate_init+0x47e>
    }

    
    initialize_csr_register_map_values();

    vmm->exec_mode = M_MODE;
    8000769e:	4709                	li	a4,2
    800076a0:	42e7b823          	sd	a4,1072(a5)
    //printf("\nAfter the trap and emulate init\n");
    800076a4:	60a2                	ld	ra,8(sp)
    800076a6:	6402                	ld	s0,0(sp)
    800076a8:	0141                	addi	sp,sp,16
    800076aa:	8082                	ret
        panic("Could not allocate memory");
    800076ac:	00002517          	auipc	a0,0x2
    800076b0:	3fc50513          	addi	a0,a0,1020 # 80009aa8 <syscalls+0x638>
    800076b4:	ffff9097          	auipc	ra,0xffff9
    800076b8:	e8c080e7          	jalr	-372(ra) # 80000540 <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0)
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0)
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
