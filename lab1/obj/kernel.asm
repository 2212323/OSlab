
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01660613          	addi	a2,a2,22 # 80204028 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	568000ef          	jal	ra,8020058a <memset>

    cons_init();  // init the console
    80200026:	14a000ef          	jal	ra,80200170 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	9ae58593          	addi	a1,a1,-1618 # 802009d8 <etext>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	9c650513          	addi	a0,a0,-1594 # 802009f8 <etext+0x20>
    8020003a:	030000ef          	jal	ra,8020006a <cprintf>

    print_kerninfo();
    8020003e:	062000ef          	jal	ra,802000a0 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	13e000ef          	jal	ra,80200180 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0e8000ef          	jal	ra,8020012e <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	130000ef          	jal	ra,8020017a <intr_enable>
    
    while (1)
    8020004e:	a001                	j	8020004e <kern_init+0x44>

0000000080200050 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200050:	1141                	addi	sp,sp,-16
    80200052:	e022                	sd	s0,0(sp)
    80200054:	e406                	sd	ra,8(sp)
    80200056:	842e                	mv	s0,a1
    cons_putc(c);
    80200058:	11a000ef          	jal	ra,80200172 <cons_putc>
    (*cnt)++;
    8020005c:	401c                	lw	a5,0(s0)
}
    8020005e:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200060:	2785                	addiw	a5,a5,1
    80200062:	c01c                	sw	a5,0(s0)
}
    80200064:	6402                	ld	s0,0(sp)
    80200066:	0141                	addi	sp,sp,16
    80200068:	8082                	ret

000000008020006a <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    8020006a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    8020006c:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200070:	8e2a                	mv	t3,a0
    80200072:	f42e                	sd	a1,40(sp)
    80200074:	f832                	sd	a2,48(sp)
    80200076:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200078:	00000517          	auipc	a0,0x0
    8020007c:	fd850513          	addi	a0,a0,-40 # 80200050 <cputch>
    80200080:	004c                	addi	a1,sp,4
    80200082:	869a                	mv	a3,t1
    80200084:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    80200086:	ec06                	sd	ra,24(sp)
    80200088:	e0ba                	sd	a4,64(sp)
    8020008a:	e4be                	sd	a5,72(sp)
    8020008c:	e8c2                	sd	a6,80(sp)
    8020008e:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200090:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200092:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200094:	574000ef          	jal	ra,80200608 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200098:	60e2                	ld	ra,24(sp)
    8020009a:	4512                	lw	a0,4(sp)
    8020009c:	6125                	addi	sp,sp,96
    8020009e:	8082                	ret

00000000802000a0 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a0:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a2:	00001517          	auipc	a0,0x1
    802000a6:	95e50513          	addi	a0,a0,-1698 # 80200a00 <etext+0x28>
void print_kerninfo(void) {
    802000aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000ac:	fbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5a58593          	addi	a1,a1,-166 # 8020000a <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	96850513          	addi	a0,a0,-1688 # 80200a20 <etext+0x48>
    802000c0:	fabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	91458593          	addi	a1,a1,-1772 # 802009d8 <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	97450513          	addi	a0,a0,-1676 # 80200a40 <etext+0x68>
    802000d4:	f97ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3858593          	addi	a1,a1,-200 # 80204010 <ticks>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	98050513          	addi	a0,a0,-1664 # 80200a60 <etext+0x88>
    802000e8:	f83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f3c58593          	addi	a1,a1,-196 # 80204028 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	98c50513          	addi	a0,a0,-1652 # 80200a80 <etext+0xa8>
    802000fc:	f6fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200100:	00004597          	auipc	a1,0x4
    80200104:	32758593          	addi	a1,a1,807 # 80204427 <end+0x3ff>
    80200108:	00000797          	auipc	a5,0x0
    8020010c:	f0278793          	addi	a5,a5,-254 # 8020000a <kern_init>
    80200110:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200114:	43f7d593          	srai	a1,a5,0x3f
}
    80200118:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	3ff5f593          	andi	a1,a1,1023
    8020011e:	95be                	add	a1,a1,a5
    80200120:	85a9                	srai	a1,a1,0xa
    80200122:	00001517          	auipc	a0,0x1
    80200126:	97e50513          	addi	a0,a0,-1666 # 80200aa0 <etext+0xc8>
}
    8020012a:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020012c:	bf3d                	j	8020006a <cprintf>

000000008020012e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    8020012e:	1141                	addi	sp,sp,-16
    80200130:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200132:	02000793          	li	a5,32
    80200136:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020013a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020013e:	67e1                	lui	a5,0x18
    80200140:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200144:	953e                	add	a0,a0,a5
    80200146:	05f000ef          	jal	ra,802009a4 <sbi_set_timer>
}
    8020014a:	60a2                	ld	ra,8(sp)
    ticks = 0;
    8020014c:	00004797          	auipc	a5,0x4
    80200150:	ec07b223          	sd	zero,-316(a5) # 80204010 <ticks>
    cprintf("++ setup timer interrupts\n");
    80200154:	00001517          	auipc	a0,0x1
    80200158:	97c50513          	addi	a0,a0,-1668 # 80200ad0 <etext+0xf8>
}
    8020015c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    8020015e:	b731                	j	8020006a <cprintf>

0000000080200160 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200160:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200164:	67e1                	lui	a5,0x18
    80200166:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    8020016a:	953e                	add	a0,a0,a5
    8020016c:	0390006f          	j	802009a4 <sbi_set_timer>

0000000080200170 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200170:	8082                	ret

0000000080200172 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200172:	0ff57513          	zext.b	a0,a0
    80200176:	0150006f          	j	8020098a <sbi_console_putchar>

000000008020017a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    8020017a:	100167f3          	csrrsi	a5,sstatus,2
    8020017e:	8082                	ret

0000000080200180 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200180:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200184:	00000797          	auipc	a5,0x0
    80200188:	33478793          	addi	a5,a5,820 # 802004b8 <__alltraps>
    8020018c:	10579073          	csrw	stvec,a5
}
    80200190:	8082                	ret

0000000080200192 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200192:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    80200194:	1141                	addi	sp,sp,-16
    80200196:	e022                	sd	s0,0(sp)
    80200198:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019a:	00001517          	auipc	a0,0x1
    8020019e:	95650513          	addi	a0,a0,-1706 # 80200af0 <etext+0x118>
void print_regs(struct pushregs *gpr) {
    802001a2:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a4:	ec7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001a8:	640c                	ld	a1,8(s0)
    802001aa:	00001517          	auipc	a0,0x1
    802001ae:	95e50513          	addi	a0,a0,-1698 # 80200b08 <etext+0x130>
    802001b2:	eb9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001b6:	680c                	ld	a1,16(s0)
    802001b8:	00001517          	auipc	a0,0x1
    802001bc:	96850513          	addi	a0,a0,-1688 # 80200b20 <etext+0x148>
    802001c0:	eabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001c4:	6c0c                	ld	a1,24(s0)
    802001c6:	00001517          	auipc	a0,0x1
    802001ca:	97250513          	addi	a0,a0,-1678 # 80200b38 <etext+0x160>
    802001ce:	e9dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001d2:	700c                	ld	a1,32(s0)
    802001d4:	00001517          	auipc	a0,0x1
    802001d8:	97c50513          	addi	a0,a0,-1668 # 80200b50 <etext+0x178>
    802001dc:	e8fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e0:	740c                	ld	a1,40(s0)
    802001e2:	00001517          	auipc	a0,0x1
    802001e6:	98650513          	addi	a0,a0,-1658 # 80200b68 <etext+0x190>
    802001ea:	e81ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001ee:	780c                	ld	a1,48(s0)
    802001f0:	00001517          	auipc	a0,0x1
    802001f4:	99050513          	addi	a0,a0,-1648 # 80200b80 <etext+0x1a8>
    802001f8:	e73ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    802001fc:	7c0c                	ld	a1,56(s0)
    802001fe:	00001517          	auipc	a0,0x1
    80200202:	99a50513          	addi	a0,a0,-1638 # 80200b98 <etext+0x1c0>
    80200206:	e65ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    8020020a:	602c                	ld	a1,64(s0)
    8020020c:	00001517          	auipc	a0,0x1
    80200210:	9a450513          	addi	a0,a0,-1628 # 80200bb0 <etext+0x1d8>
    80200214:	e57ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200218:	642c                	ld	a1,72(s0)
    8020021a:	00001517          	auipc	a0,0x1
    8020021e:	9ae50513          	addi	a0,a0,-1618 # 80200bc8 <etext+0x1f0>
    80200222:	e49ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    80200226:	682c                	ld	a1,80(s0)
    80200228:	00001517          	auipc	a0,0x1
    8020022c:	9b850513          	addi	a0,a0,-1608 # 80200be0 <etext+0x208>
    80200230:	e3bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200234:	6c2c                	ld	a1,88(s0)
    80200236:	00001517          	auipc	a0,0x1
    8020023a:	9c250513          	addi	a0,a0,-1598 # 80200bf8 <etext+0x220>
    8020023e:	e2dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200242:	702c                	ld	a1,96(s0)
    80200244:	00001517          	auipc	a0,0x1
    80200248:	9cc50513          	addi	a0,a0,-1588 # 80200c10 <etext+0x238>
    8020024c:	e1fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200250:	742c                	ld	a1,104(s0)
    80200252:	00001517          	auipc	a0,0x1
    80200256:	9d650513          	addi	a0,a0,-1578 # 80200c28 <etext+0x250>
    8020025a:	e11ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    8020025e:	782c                	ld	a1,112(s0)
    80200260:	00001517          	auipc	a0,0x1
    80200264:	9e050513          	addi	a0,a0,-1568 # 80200c40 <etext+0x268>
    80200268:	e03ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    8020026c:	7c2c                	ld	a1,120(s0)
    8020026e:	00001517          	auipc	a0,0x1
    80200272:	9ea50513          	addi	a0,a0,-1558 # 80200c58 <etext+0x280>
    80200276:	df5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    8020027a:	604c                	ld	a1,128(s0)
    8020027c:	00001517          	auipc	a0,0x1
    80200280:	9f450513          	addi	a0,a0,-1548 # 80200c70 <etext+0x298>
    80200284:	de7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200288:	644c                	ld	a1,136(s0)
    8020028a:	00001517          	auipc	a0,0x1
    8020028e:	9fe50513          	addi	a0,a0,-1538 # 80200c88 <etext+0x2b0>
    80200292:	dd9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    80200296:	684c                	ld	a1,144(s0)
    80200298:	00001517          	auipc	a0,0x1
    8020029c:	a0850513          	addi	a0,a0,-1528 # 80200ca0 <etext+0x2c8>
    802002a0:	dcbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002a4:	6c4c                	ld	a1,152(s0)
    802002a6:	00001517          	auipc	a0,0x1
    802002aa:	a1250513          	addi	a0,a0,-1518 # 80200cb8 <etext+0x2e0>
    802002ae:	dbdff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002b2:	704c                	ld	a1,160(s0)
    802002b4:	00001517          	auipc	a0,0x1
    802002b8:	a1c50513          	addi	a0,a0,-1508 # 80200cd0 <etext+0x2f8>
    802002bc:	dafff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c0:	744c                	ld	a1,168(s0)
    802002c2:	00001517          	auipc	a0,0x1
    802002c6:	a2650513          	addi	a0,a0,-1498 # 80200ce8 <etext+0x310>
    802002ca:	da1ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002ce:	784c                	ld	a1,176(s0)
    802002d0:	00001517          	auipc	a0,0x1
    802002d4:	a3050513          	addi	a0,a0,-1488 # 80200d00 <etext+0x328>
    802002d8:	d93ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002dc:	7c4c                	ld	a1,184(s0)
    802002de:	00001517          	auipc	a0,0x1
    802002e2:	a3a50513          	addi	a0,a0,-1478 # 80200d18 <etext+0x340>
    802002e6:	d85ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002ea:	606c                	ld	a1,192(s0)
    802002ec:	00001517          	auipc	a0,0x1
    802002f0:	a4450513          	addi	a0,a0,-1468 # 80200d30 <etext+0x358>
    802002f4:	d77ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002f8:	646c                	ld	a1,200(s0)
    802002fa:	00001517          	auipc	a0,0x1
    802002fe:	a4e50513          	addi	a0,a0,-1458 # 80200d48 <etext+0x370>
    80200302:	d69ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    80200306:	686c                	ld	a1,208(s0)
    80200308:	00001517          	auipc	a0,0x1
    8020030c:	a5850513          	addi	a0,a0,-1448 # 80200d60 <etext+0x388>
    80200310:	d5bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200314:	6c6c                	ld	a1,216(s0)
    80200316:	00001517          	auipc	a0,0x1
    8020031a:	a6250513          	addi	a0,a0,-1438 # 80200d78 <etext+0x3a0>
    8020031e:	d4dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200322:	706c                	ld	a1,224(s0)
    80200324:	00001517          	auipc	a0,0x1
    80200328:	a6c50513          	addi	a0,a0,-1428 # 80200d90 <etext+0x3b8>
    8020032c:	d3fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200330:	746c                	ld	a1,232(s0)
    80200332:	00001517          	auipc	a0,0x1
    80200336:	a7650513          	addi	a0,a0,-1418 # 80200da8 <etext+0x3d0>
    8020033a:	d31ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    8020033e:	786c                	ld	a1,240(s0)
    80200340:	00001517          	auipc	a0,0x1
    80200344:	a8050513          	addi	a0,a0,-1408 # 80200dc0 <etext+0x3e8>
    80200348:	d23ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020034c:	7c6c                	ld	a1,248(s0)
}
    8020034e:	6402                	ld	s0,0(sp)
    80200350:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200352:	00001517          	auipc	a0,0x1
    80200356:	a8650513          	addi	a0,a0,-1402 # 80200dd8 <etext+0x400>
}
    8020035a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020035c:	b339                	j	8020006a <cprintf>

000000008020035e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    8020035e:	1141                	addi	sp,sp,-16
    80200360:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200362:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200364:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200366:	00001517          	auipc	a0,0x1
    8020036a:	a8a50513          	addi	a0,a0,-1398 # 80200df0 <etext+0x418>
void print_trapframe(struct trapframe *tf) {
    8020036e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200370:	cfbff0ef          	jal	ra,8020006a <cprintf>
    print_regs(&tf->gpr);
    80200374:	8522                	mv	a0,s0
    80200376:	e1dff0ef          	jal	ra,80200192 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    8020037a:	10043583          	ld	a1,256(s0)
    8020037e:	00001517          	auipc	a0,0x1
    80200382:	a8a50513          	addi	a0,a0,-1398 # 80200e08 <etext+0x430>
    80200386:	ce5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    8020038a:	10843583          	ld	a1,264(s0)
    8020038e:	00001517          	auipc	a0,0x1
    80200392:	a9250513          	addi	a0,a0,-1390 # 80200e20 <etext+0x448>
    80200396:	cd5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    8020039a:	11043583          	ld	a1,272(s0)
    8020039e:	00001517          	auipc	a0,0x1
    802003a2:	a9a50513          	addi	a0,a0,-1382 # 80200e38 <etext+0x460>
    802003a6:	cc5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003aa:	11843583          	ld	a1,280(s0)
}
    802003ae:	6402                	ld	s0,0(sp)
    802003b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b2:	00001517          	auipc	a0,0x1
    802003b6:	a9e50513          	addi	a0,a0,-1378 # 80200e50 <etext+0x478>
}
    802003ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003bc:	b17d                	j	8020006a <cprintf>

00000000802003be <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003be:	11853783          	ld	a5,280(a0)
    802003c2:	472d                	li	a4,11
    802003c4:	0786                	slli	a5,a5,0x1
    802003c6:	8385                	srli	a5,a5,0x1
    802003c8:	08f76163          	bltu	a4,a5,8020044a <interrupt_handler+0x8c>
    802003cc:	00001717          	auipc	a4,0x1
    802003d0:	b4c70713          	addi	a4,a4,-1204 # 80200f18 <etext+0x540>
    802003d4:	078a                	slli	a5,a5,0x2
    802003d6:	97ba                	add	a5,a5,a4
    802003d8:	439c                	lw	a5,0(a5)
    802003da:	97ba                	add	a5,a5,a4
    802003dc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003de:	00001517          	auipc	a0,0x1
    802003e2:	aea50513          	addi	a0,a0,-1302 # 80200ec8 <etext+0x4f0>
    802003e6:	b151                	j	8020006a <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003e8:	00001517          	auipc	a0,0x1
    802003ec:	ac050513          	addi	a0,a0,-1344 # 80200ea8 <etext+0x4d0>
    802003f0:	b9ad                	j	8020006a <cprintf>
            cprintf("User software interrupt\n");
    802003f2:	00001517          	auipc	a0,0x1
    802003f6:	a7650513          	addi	a0,a0,-1418 # 80200e68 <etext+0x490>
    802003fa:	b985                	j	8020006a <cprintf>
            cprintf("Supervisor software interrupt\n");
    802003fc:	00001517          	auipc	a0,0x1
    80200400:	a8c50513          	addi	a0,a0,-1396 # 80200e88 <etext+0x4b0>
    80200404:	b19d                	j	8020006a <cprintf>
void interrupt_handler(struct trapframe *tf) {
    80200406:	1141                	addi	sp,sp,-16
    80200408:	e022                	sd	s0,0(sp)
    8020040a:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
           clock_set_next_event();
    8020040c:	d55ff0ef          	jal	ra,80200160 <clock_set_next_event>
           ticks++;
    80200410:	00004797          	auipc	a5,0x4
    80200414:	c0078793          	addi	a5,a5,-1024 # 80204010 <ticks>
    80200418:	6398                	ld	a4,0(a5)
           if(ticks==100){
    8020041a:	06400693          	li	a3,100
    8020041e:	00004417          	auipc	s0,0x4
    80200422:	bfa40413          	addi	s0,s0,-1030 # 80204018 <num>
           ticks++;
    80200426:	0705                	addi	a4,a4,1
    80200428:	e398                	sd	a4,0(a5)
           if(ticks==100){
    8020042a:	639c                	ld	a5,0(a5)
    8020042c:	02d78063          	beq	a5,a3,8020044c <interrupt_handler+0x8e>
            num++;
            cprintf("100 ticks");
            ticks=0;
           }
            if(num==10){
    80200430:	6018                	ld	a4,0(s0)
    80200432:	47a9                	li	a5,10
    80200434:	02f70a63          	beq	a4,a5,80200468 <interrupt_handler+0xaa>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    80200438:	60a2                	ld	ra,8(sp)
    8020043a:	6402                	ld	s0,0(sp)
    8020043c:	0141                	addi	sp,sp,16
    8020043e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
    80200440:	00001517          	auipc	a0,0x1
    80200444:	ab850513          	addi	a0,a0,-1352 # 80200ef8 <etext+0x520>
    80200448:	b10d                	j	8020006a <cprintf>
            print_trapframe(tf);
    8020044a:	bf11                	j	8020035e <print_trapframe>
            num++;
    8020044c:	601c                	ld	a5,0(s0)
            cprintf("100 ticks");
    8020044e:	00001517          	auipc	a0,0x1
    80200452:	a9a50513          	addi	a0,a0,-1382 # 80200ee8 <etext+0x510>
            num++;
    80200456:	0785                	addi	a5,a5,1
    80200458:	e01c                	sd	a5,0(s0)
            cprintf("100 ticks");
    8020045a:	c11ff0ef          	jal	ra,8020006a <cprintf>
            ticks=0;
    8020045e:	00004797          	auipc	a5,0x4
    80200462:	ba07b923          	sd	zero,-1102(a5) # 80204010 <ticks>
    80200466:	b7e9                	j	80200430 <interrupt_handler+0x72>
}
    80200468:	6402                	ld	s0,0(sp)
    8020046a:	60a2                	ld	ra,8(sp)
    8020046c:	0141                	addi	sp,sp,16
                sbi_shutdown();
    8020046e:	ab81                	j	802009be <sbi_shutdown>

0000000080200470 <trap>:
    }
}

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    80200470:	11853783          	ld	a5,280(a0)
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) { trap_dispatch(tf); }
    80200474:	872a                	mv	a4,a0
    if ((intptr_t)tf->cause < 0) {
    80200476:	0207c763          	bltz	a5,802004a4 <trap+0x34>
    switch (tf->cause) {
    8020047a:	468d                	li	a3,3
    8020047c:	02d78863          	beq	a5,a3,802004ac <trap+0x3c>
    80200480:	00f6ed63          	bltu	a3,a5,8020049a <trap+0x2a>
    80200484:	4685                	li	a3,1
    80200486:	02f6f263          	bgeu	a3,a5,802004aa <trap+0x3a>
    8020048a:	4689                	li	a3,2
    8020048c:	00d79d63          	bne	a5,a3,802004a6 <trap+0x36>
           cprintf("Illegal instruction");
    80200490:	00001517          	auipc	a0,0x1
    80200494:	ab850513          	addi	a0,a0,-1352 # 80200f48 <etext+0x570>
    80200498:	bec9                	j	8020006a <cprintf>
    switch (tf->cause) {
    8020049a:	17f1                	addi	a5,a5,-4
    8020049c:	469d                	li	a3,7
    8020049e:	00f6e463          	bltu	a3,a5,802004a6 <trap+0x36>
    802004a2:	8082                	ret
        interrupt_handler(tf);
    802004a4:	bf29                	j	802003be <interrupt_handler>
            print_trapframe(tf);
    802004a6:	853a                	mv	a0,a4
    802004a8:	bd5d                	j	8020035e <print_trapframe>
void trap(struct trapframe *tf) { trap_dispatch(tf); }
    802004aa:	8082                	ret
           cprintf("breakpoint");
    802004ac:	00001517          	auipc	a0,0x1
    802004b0:	ab450513          	addi	a0,a0,-1356 # 80200f60 <etext+0x588>
    802004b4:	be5d                	j	8020006a <cprintf>
	...

00000000802004b8 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    802004b8:	14011073          	csrw	sscratch,sp
    802004bc:	712d                	addi	sp,sp,-288
    802004be:	e002                	sd	zero,0(sp)
    802004c0:	e406                	sd	ra,8(sp)
    802004c2:	ec0e                	sd	gp,24(sp)
    802004c4:	f012                	sd	tp,32(sp)
    802004c6:	f416                	sd	t0,40(sp)
    802004c8:	f81a                	sd	t1,48(sp)
    802004ca:	fc1e                	sd	t2,56(sp)
    802004cc:	e0a2                	sd	s0,64(sp)
    802004ce:	e4a6                	sd	s1,72(sp)
    802004d0:	e8aa                	sd	a0,80(sp)
    802004d2:	ecae                	sd	a1,88(sp)
    802004d4:	f0b2                	sd	a2,96(sp)
    802004d6:	f4b6                	sd	a3,104(sp)
    802004d8:	f8ba                	sd	a4,112(sp)
    802004da:	fcbe                	sd	a5,120(sp)
    802004dc:	e142                	sd	a6,128(sp)
    802004de:	e546                	sd	a7,136(sp)
    802004e0:	e94a                	sd	s2,144(sp)
    802004e2:	ed4e                	sd	s3,152(sp)
    802004e4:	f152                	sd	s4,160(sp)
    802004e6:	f556                	sd	s5,168(sp)
    802004e8:	f95a                	sd	s6,176(sp)
    802004ea:	fd5e                	sd	s7,184(sp)
    802004ec:	e1e2                	sd	s8,192(sp)
    802004ee:	e5e6                	sd	s9,200(sp)
    802004f0:	e9ea                	sd	s10,208(sp)
    802004f2:	edee                	sd	s11,216(sp)
    802004f4:	f1f2                	sd	t3,224(sp)
    802004f6:	f5f6                	sd	t4,232(sp)
    802004f8:	f9fa                	sd	t5,240(sp)
    802004fa:	fdfe                	sd	t6,248(sp)
    802004fc:	14001473          	csrrw	s0,sscratch,zero
    80200500:	100024f3          	csrr	s1,sstatus
    80200504:	14102973          	csrr	s2,sepc
    80200508:	143029f3          	csrr	s3,stval
    8020050c:	14202a73          	csrr	s4,scause
    80200510:	e822                	sd	s0,16(sp)
    80200512:	e226                	sd	s1,256(sp)
    80200514:	e64a                	sd	s2,264(sp)
    80200516:	ea4e                	sd	s3,272(sp)
    80200518:	ee52                	sd	s4,280(sp)

    move  a0, sp
    8020051a:	850a                	mv	a0,sp
    jal trap
    8020051c:	f55ff0ef          	jal	ra,80200470 <trap>

0000000080200520 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    80200520:	6492                	ld	s1,256(sp)
    80200522:	6932                	ld	s2,264(sp)
    80200524:	10049073          	csrw	sstatus,s1
    80200528:	14191073          	csrw	sepc,s2
    8020052c:	60a2                	ld	ra,8(sp)
    8020052e:	61e2                	ld	gp,24(sp)
    80200530:	7202                	ld	tp,32(sp)
    80200532:	72a2                	ld	t0,40(sp)
    80200534:	7342                	ld	t1,48(sp)
    80200536:	73e2                	ld	t2,56(sp)
    80200538:	6406                	ld	s0,64(sp)
    8020053a:	64a6                	ld	s1,72(sp)
    8020053c:	6546                	ld	a0,80(sp)
    8020053e:	65e6                	ld	a1,88(sp)
    80200540:	7606                	ld	a2,96(sp)
    80200542:	76a6                	ld	a3,104(sp)
    80200544:	7746                	ld	a4,112(sp)
    80200546:	77e6                	ld	a5,120(sp)
    80200548:	680a                	ld	a6,128(sp)
    8020054a:	68aa                	ld	a7,136(sp)
    8020054c:	694a                	ld	s2,144(sp)
    8020054e:	69ea                	ld	s3,152(sp)
    80200550:	7a0a                	ld	s4,160(sp)
    80200552:	7aaa                	ld	s5,168(sp)
    80200554:	7b4a                	ld	s6,176(sp)
    80200556:	7bea                	ld	s7,184(sp)
    80200558:	6c0e                	ld	s8,192(sp)
    8020055a:	6cae                	ld	s9,200(sp)
    8020055c:	6d4e                	ld	s10,208(sp)
    8020055e:	6dee                	ld	s11,216(sp)
    80200560:	7e0e                	ld	t3,224(sp)
    80200562:	7eae                	ld	t4,232(sp)
    80200564:	7f4e                	ld	t5,240(sp)
    80200566:	7fee                	ld	t6,248(sp)
    80200568:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    8020056a:	10200073          	sret

000000008020056e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    8020056e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    80200570:	e589                	bnez	a1,8020057a <strnlen+0xc>
    80200572:	a811                	j	80200586 <strnlen+0x18>
        cnt ++;
    80200574:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    80200576:	00f58863          	beq	a1,a5,80200586 <strnlen+0x18>
    8020057a:	00f50733          	add	a4,a0,a5
    8020057e:	00074703          	lbu	a4,0(a4)
    80200582:	fb6d                	bnez	a4,80200574 <strnlen+0x6>
    80200584:	85be                	mv	a1,a5
    }
    return cnt;
}
    80200586:	852e                	mv	a0,a1
    80200588:	8082                	ret

000000008020058a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    8020058a:	ca01                	beqz	a2,8020059a <memset+0x10>
    8020058c:	962a                	add	a2,a2,a0
    char *p = s;
    8020058e:	87aa                	mv	a5,a0
        *p ++ = c;
    80200590:	0785                	addi	a5,a5,1
    80200592:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    80200596:	fec79de3          	bne	a5,a2,80200590 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    8020059a:	8082                	ret

000000008020059c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    8020059c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802005a0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    802005a2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802005a6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    802005a8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    802005ac:	f022                	sd	s0,32(sp)
    802005ae:	ec26                	sd	s1,24(sp)
    802005b0:	e84a                	sd	s2,16(sp)
    802005b2:	f406                	sd	ra,40(sp)
    802005b4:	e44e                	sd	s3,8(sp)
    802005b6:	84aa                	mv	s1,a0
    802005b8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    802005ba:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    802005be:	2a01                	sext.w	s4,s4
    if (num >= base) {
    802005c0:	03067e63          	bgeu	a2,a6,802005fc <printnum+0x60>
    802005c4:	89be                	mv	s3,a5
        while (-- width > 0)
    802005c6:	00805763          	blez	s0,802005d4 <printnum+0x38>
    802005ca:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    802005cc:	85ca                	mv	a1,s2
    802005ce:	854e                	mv	a0,s3
    802005d0:	9482                	jalr	s1
        while (-- width > 0)
    802005d2:	fc65                	bnez	s0,802005ca <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    802005d4:	1a02                	slli	s4,s4,0x20
    802005d6:	00001797          	auipc	a5,0x1
    802005da:	99a78793          	addi	a5,a5,-1638 # 80200f70 <etext+0x598>
    802005de:	020a5a13          	srli	s4,s4,0x20
    802005e2:	9a3e                	add	s4,s4,a5
}
    802005e4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    802005e6:	000a4503          	lbu	a0,0(s4)
}
    802005ea:	70a2                	ld	ra,40(sp)
    802005ec:	69a2                	ld	s3,8(sp)
    802005ee:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    802005f0:	85ca                	mv	a1,s2
    802005f2:	87a6                	mv	a5,s1
}
    802005f4:	6942                	ld	s2,16(sp)
    802005f6:	64e2                	ld	s1,24(sp)
    802005f8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    802005fa:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    802005fc:	03065633          	divu	a2,a2,a6
    80200600:	8722                	mv	a4,s0
    80200602:	f9bff0ef          	jal	ra,8020059c <printnum>
    80200606:	b7f9                	j	802005d4 <printnum+0x38>

0000000080200608 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    80200608:	7119                	addi	sp,sp,-128
    8020060a:	f4a6                	sd	s1,104(sp)
    8020060c:	f0ca                	sd	s2,96(sp)
    8020060e:	ecce                	sd	s3,88(sp)
    80200610:	e8d2                	sd	s4,80(sp)
    80200612:	e4d6                	sd	s5,72(sp)
    80200614:	e0da                	sd	s6,64(sp)
    80200616:	fc5e                	sd	s7,56(sp)
    80200618:	f06a                	sd	s10,32(sp)
    8020061a:	fc86                	sd	ra,120(sp)
    8020061c:	f8a2                	sd	s0,112(sp)
    8020061e:	f862                	sd	s8,48(sp)
    80200620:	f466                	sd	s9,40(sp)
    80200622:	ec6e                	sd	s11,24(sp)
    80200624:	892a                	mv	s2,a0
    80200626:	84ae                	mv	s1,a1
    80200628:	8d32                	mv	s10,a2
    8020062a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020062c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200630:	5b7d                	li	s6,-1
    80200632:	00001a97          	auipc	s5,0x1
    80200636:	972a8a93          	addi	s5,s5,-1678 # 80200fa4 <etext+0x5cc>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020063a:	00001b97          	auipc	s7,0x1
    8020063e:	b46b8b93          	addi	s7,s7,-1210 # 80201180 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200642:	000d4503          	lbu	a0,0(s10)
    80200646:	001d0413          	addi	s0,s10,1
    8020064a:	01350a63          	beq	a0,s3,8020065e <vprintfmt+0x56>
            if (ch == '\0') {
    8020064e:	c121                	beqz	a0,8020068e <vprintfmt+0x86>
            putch(ch, putdat);
    80200650:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200652:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    80200654:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200656:	fff44503          	lbu	a0,-1(s0)
    8020065a:	ff351ae3          	bne	a0,s3,8020064e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    8020065e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200662:	02000793          	li	a5,32
        lflag = altflag = 0;
    80200666:	4c81                	li	s9,0
    80200668:	4881                	li	a7,0
        width = precision = -1;
    8020066a:	5c7d                	li	s8,-1
    8020066c:	5dfd                	li	s11,-1
    8020066e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    80200672:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200674:	fdd6059b          	addiw	a1,a2,-35
    80200678:	0ff5f593          	zext.b	a1,a1
    8020067c:	00140d13          	addi	s10,s0,1
    80200680:	04b56263          	bltu	a0,a1,802006c4 <vprintfmt+0xbc>
    80200684:	058a                	slli	a1,a1,0x2
    80200686:	95d6                	add	a1,a1,s5
    80200688:	4194                	lw	a3,0(a1)
    8020068a:	96d6                	add	a3,a3,s5
    8020068c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    8020068e:	70e6                	ld	ra,120(sp)
    80200690:	7446                	ld	s0,112(sp)
    80200692:	74a6                	ld	s1,104(sp)
    80200694:	7906                	ld	s2,96(sp)
    80200696:	69e6                	ld	s3,88(sp)
    80200698:	6a46                	ld	s4,80(sp)
    8020069a:	6aa6                	ld	s5,72(sp)
    8020069c:	6b06                	ld	s6,64(sp)
    8020069e:	7be2                	ld	s7,56(sp)
    802006a0:	7c42                	ld	s8,48(sp)
    802006a2:	7ca2                	ld	s9,40(sp)
    802006a4:	7d02                	ld	s10,32(sp)
    802006a6:	6de2                	ld	s11,24(sp)
    802006a8:	6109                	addi	sp,sp,128
    802006aa:	8082                	ret
            padc = '0';
    802006ac:	87b2                	mv	a5,a2
            goto reswitch;
    802006ae:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802006b2:	846a                	mv	s0,s10
    802006b4:	00140d13          	addi	s10,s0,1
    802006b8:	fdd6059b          	addiw	a1,a2,-35
    802006bc:	0ff5f593          	zext.b	a1,a1
    802006c0:	fcb572e3          	bgeu	a0,a1,80200684 <vprintfmt+0x7c>
            putch('%', putdat);
    802006c4:	85a6                	mv	a1,s1
    802006c6:	02500513          	li	a0,37
    802006ca:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802006cc:	fff44783          	lbu	a5,-1(s0)
    802006d0:	8d22                	mv	s10,s0
    802006d2:	f73788e3          	beq	a5,s3,80200642 <vprintfmt+0x3a>
    802006d6:	ffed4783          	lbu	a5,-2(s10)
    802006da:	1d7d                	addi	s10,s10,-1
    802006dc:	ff379de3          	bne	a5,s3,802006d6 <vprintfmt+0xce>
    802006e0:	b78d                	j	80200642 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    802006e2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    802006e6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802006ea:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    802006ec:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    802006f0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    802006f4:	02d86463          	bltu	a6,a3,8020071c <vprintfmt+0x114>
                ch = *fmt;
    802006f8:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    802006fc:	002c169b          	slliw	a3,s8,0x2
    80200700:	0186873b          	addw	a4,a3,s8
    80200704:	0017171b          	slliw	a4,a4,0x1
    80200708:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    8020070a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    8020070e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200710:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    80200714:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200718:	fed870e3          	bgeu	a6,a3,802006f8 <vprintfmt+0xf0>
            if (width < 0)
    8020071c:	f40ddce3          	bgez	s11,80200674 <vprintfmt+0x6c>
                width = precision, precision = -1;
    80200720:	8de2                	mv	s11,s8
    80200722:	5c7d                	li	s8,-1
    80200724:	bf81                	j	80200674 <vprintfmt+0x6c>
            if (width < 0)
    80200726:	fffdc693          	not	a3,s11
    8020072a:	96fd                	srai	a3,a3,0x3f
    8020072c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    80200730:	00144603          	lbu	a2,1(s0)
    80200734:	2d81                	sext.w	s11,s11
    80200736:	846a                	mv	s0,s10
            goto reswitch;
    80200738:	bf35                	j	80200674 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    8020073a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    8020073e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200742:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200744:	846a                	mv	s0,s10
            goto process_precision;
    80200746:	bfd9                	j	8020071c <vprintfmt+0x114>
    if (lflag >= 2) {
    80200748:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020074a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    8020074e:	01174463          	blt	a4,a7,80200756 <vprintfmt+0x14e>
    else if (lflag) {
    80200752:	1a088e63          	beqz	a7,8020090e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    80200756:	000a3603          	ld	a2,0(s4)
    8020075a:	46c1                	li	a3,16
    8020075c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    8020075e:	2781                	sext.w	a5,a5
    80200760:	876e                	mv	a4,s11
    80200762:	85a6                	mv	a1,s1
    80200764:	854a                	mv	a0,s2
    80200766:	e37ff0ef          	jal	ra,8020059c <printnum>
            break;
    8020076a:	bde1                	j	80200642 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    8020076c:	000a2503          	lw	a0,0(s4)
    80200770:	85a6                	mv	a1,s1
    80200772:	0a21                	addi	s4,s4,8
    80200774:	9902                	jalr	s2
            break;
    80200776:	b5f1                	j	80200642 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200778:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020077a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    8020077e:	01174463          	blt	a4,a7,80200786 <vprintfmt+0x17e>
    else if (lflag) {
    80200782:	18088163          	beqz	a7,80200904 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    80200786:	000a3603          	ld	a2,0(s4)
    8020078a:	46a9                	li	a3,10
    8020078c:	8a2e                	mv	s4,a1
    8020078e:	bfc1                	j	8020075e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    80200790:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    80200794:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200796:	846a                	mv	s0,s10
            goto reswitch;
    80200798:	bdf1                	j	80200674 <vprintfmt+0x6c>
            putch(ch, putdat);
    8020079a:	85a6                	mv	a1,s1
    8020079c:	02500513          	li	a0,37
    802007a0:	9902                	jalr	s2
            break;
    802007a2:	b545                	j	80200642 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    802007a4:	00144603          	lbu	a2,1(s0)
            lflag ++;
    802007a8:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    802007aa:	846a                	mv	s0,s10
            goto reswitch;
    802007ac:	b5e1                	j	80200674 <vprintfmt+0x6c>
    if (lflag >= 2) {
    802007ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802007b0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802007b4:	01174463          	blt	a4,a7,802007bc <vprintfmt+0x1b4>
    else if (lflag) {
    802007b8:	14088163          	beqz	a7,802008fa <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    802007bc:	000a3603          	ld	a2,0(s4)
    802007c0:	46a1                	li	a3,8
    802007c2:	8a2e                	mv	s4,a1
    802007c4:	bf69                	j	8020075e <vprintfmt+0x156>
            putch('0', putdat);
    802007c6:	03000513          	li	a0,48
    802007ca:	85a6                	mv	a1,s1
    802007cc:	e03e                	sd	a5,0(sp)
    802007ce:	9902                	jalr	s2
            putch('x', putdat);
    802007d0:	85a6                	mv	a1,s1
    802007d2:	07800513          	li	a0,120
    802007d6:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802007d8:	0a21                	addi	s4,s4,8
            goto number;
    802007da:	6782                	ld	a5,0(sp)
    802007dc:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    802007de:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    802007e2:	bfb5                	j	8020075e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    802007e4:	000a3403          	ld	s0,0(s4)
    802007e8:	008a0713          	addi	a4,s4,8
    802007ec:	e03a                	sd	a4,0(sp)
    802007ee:	14040263          	beqz	s0,80200932 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    802007f2:	0fb05763          	blez	s11,802008e0 <vprintfmt+0x2d8>
    802007f6:	02d00693          	li	a3,45
    802007fa:	0cd79163          	bne	a5,a3,802008bc <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007fe:	00044783          	lbu	a5,0(s0)
    80200802:	0007851b          	sext.w	a0,a5
    80200806:	cf85                	beqz	a5,8020083e <vprintfmt+0x236>
    80200808:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020080c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200810:	000c4563          	bltz	s8,8020081a <vprintfmt+0x212>
    80200814:	3c7d                	addiw	s8,s8,-1
    80200816:	036c0263          	beq	s8,s6,8020083a <vprintfmt+0x232>
                    putch('?', putdat);
    8020081a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020081c:	0e0c8e63          	beqz	s9,80200918 <vprintfmt+0x310>
    80200820:	3781                	addiw	a5,a5,-32
    80200822:	0ef47b63          	bgeu	s0,a5,80200918 <vprintfmt+0x310>
                    putch('?', putdat);
    80200826:	03f00513          	li	a0,63
    8020082a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020082c:	000a4783          	lbu	a5,0(s4)
    80200830:	3dfd                	addiw	s11,s11,-1
    80200832:	0a05                	addi	s4,s4,1
    80200834:	0007851b          	sext.w	a0,a5
    80200838:	ffe1                	bnez	a5,80200810 <vprintfmt+0x208>
            for (; width > 0; width --) {
    8020083a:	01b05963          	blez	s11,8020084c <vprintfmt+0x244>
    8020083e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200840:	85a6                	mv	a1,s1
    80200842:	02000513          	li	a0,32
    80200846:	9902                	jalr	s2
            for (; width > 0; width --) {
    80200848:	fe0d9be3          	bnez	s11,8020083e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020084c:	6a02                	ld	s4,0(sp)
    8020084e:	bbd5                	j	80200642 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200850:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200852:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    80200856:	01174463          	blt	a4,a7,8020085e <vprintfmt+0x256>
    else if (lflag) {
    8020085a:	08088d63          	beqz	a7,802008f4 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    8020085e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    80200862:	0a044d63          	bltz	s0,8020091c <vprintfmt+0x314>
            num = getint(&ap, lflag);
    80200866:	8622                	mv	a2,s0
    80200868:	8a66                	mv	s4,s9
    8020086a:	46a9                	li	a3,10
    8020086c:	bdcd                	j	8020075e <vprintfmt+0x156>
            err = va_arg(ap, int);
    8020086e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200872:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200874:	0a21                	addi	s4,s4,8
            if (err < 0) {
    80200876:	41f7d69b          	sraiw	a3,a5,0x1f
    8020087a:	8fb5                	xor	a5,a5,a3
    8020087c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200880:	02d74163          	blt	a4,a3,802008a2 <vprintfmt+0x29a>
    80200884:	00369793          	slli	a5,a3,0x3
    80200888:	97de                	add	a5,a5,s7
    8020088a:	639c                	ld	a5,0(a5)
    8020088c:	cb99                	beqz	a5,802008a2 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    8020088e:	86be                	mv	a3,a5
    80200890:	00000617          	auipc	a2,0x0
    80200894:	71060613          	addi	a2,a2,1808 # 80200fa0 <etext+0x5c8>
    80200898:	85a6                	mv	a1,s1
    8020089a:	854a                	mv	a0,s2
    8020089c:	0ce000ef          	jal	ra,8020096a <printfmt>
    802008a0:	b34d                	j	80200642 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    802008a2:	00000617          	auipc	a2,0x0
    802008a6:	6ee60613          	addi	a2,a2,1774 # 80200f90 <etext+0x5b8>
    802008aa:	85a6                	mv	a1,s1
    802008ac:	854a                	mv	a0,s2
    802008ae:	0bc000ef          	jal	ra,8020096a <printfmt>
    802008b2:	bb41                	j	80200642 <vprintfmt+0x3a>
                p = "(null)";
    802008b4:	00000417          	auipc	s0,0x0
    802008b8:	6d440413          	addi	s0,s0,1748 # 80200f88 <etext+0x5b0>
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008bc:	85e2                	mv	a1,s8
    802008be:	8522                	mv	a0,s0
    802008c0:	e43e                	sd	a5,8(sp)
    802008c2:	cadff0ef          	jal	ra,8020056e <strnlen>
    802008c6:	40ad8dbb          	subw	s11,s11,a0
    802008ca:	01b05b63          	blez	s11,802008e0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
    802008ce:	67a2                	ld	a5,8(sp)
    802008d0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008d4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    802008d6:	85a6                	mv	a1,s1
    802008d8:	8552                	mv	a0,s4
    802008da:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008dc:	fe0d9ce3          	bnez	s11,802008d4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802008e0:	00044783          	lbu	a5,0(s0)
    802008e4:	00140a13          	addi	s4,s0,1
    802008e8:	0007851b          	sext.w	a0,a5
    802008ec:	d3a5                	beqz	a5,8020084c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    802008ee:	05e00413          	li	s0,94
    802008f2:	bf39                	j	80200810 <vprintfmt+0x208>
        return va_arg(*ap, int);
    802008f4:	000a2403          	lw	s0,0(s4)
    802008f8:	b7ad                	j	80200862 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    802008fa:	000a6603          	lwu	a2,0(s4)
    802008fe:	46a1                	li	a3,8
    80200900:	8a2e                	mv	s4,a1
    80200902:	bdb1                	j	8020075e <vprintfmt+0x156>
    80200904:	000a6603          	lwu	a2,0(s4)
    80200908:	46a9                	li	a3,10
    8020090a:	8a2e                	mv	s4,a1
    8020090c:	bd89                	j	8020075e <vprintfmt+0x156>
    8020090e:	000a6603          	lwu	a2,0(s4)
    80200912:	46c1                	li	a3,16
    80200914:	8a2e                	mv	s4,a1
    80200916:	b5a1                	j	8020075e <vprintfmt+0x156>
                    putch(ch, putdat);
    80200918:	9902                	jalr	s2
    8020091a:	bf09                	j	8020082c <vprintfmt+0x224>
                putch('-', putdat);
    8020091c:	85a6                	mv	a1,s1
    8020091e:	02d00513          	li	a0,45
    80200922:	e03e                	sd	a5,0(sp)
    80200924:	9902                	jalr	s2
                num = -(long long)num;
    80200926:	6782                	ld	a5,0(sp)
    80200928:	8a66                	mv	s4,s9
    8020092a:	40800633          	neg	a2,s0
    8020092e:	46a9                	li	a3,10
    80200930:	b53d                	j	8020075e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    80200932:	03b05163          	blez	s11,80200954 <vprintfmt+0x34c>
    80200936:	02d00693          	li	a3,45
    8020093a:	f6d79de3          	bne	a5,a3,802008b4 <vprintfmt+0x2ac>
                p = "(null)";
    8020093e:	00000417          	auipc	s0,0x0
    80200942:	64a40413          	addi	s0,s0,1610 # 80200f88 <etext+0x5b0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200946:	02800793          	li	a5,40
    8020094a:	02800513          	li	a0,40
    8020094e:	00140a13          	addi	s4,s0,1
    80200952:	bd6d                	j	8020080c <vprintfmt+0x204>
    80200954:	00000a17          	auipc	s4,0x0
    80200958:	635a0a13          	addi	s4,s4,1589 # 80200f89 <etext+0x5b1>
    8020095c:	02800513          	li	a0,40
    80200960:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    80200964:	05e00413          	li	s0,94
    80200968:	b565                	j	80200810 <vprintfmt+0x208>

000000008020096a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020096a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    8020096c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200970:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200972:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200974:	ec06                	sd	ra,24(sp)
    80200976:	f83a                	sd	a4,48(sp)
    80200978:	fc3e                	sd	a5,56(sp)
    8020097a:	e0c2                	sd	a6,64(sp)
    8020097c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    8020097e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200980:	c89ff0ef          	jal	ra,80200608 <vprintfmt>
}
    80200984:	60e2                	ld	ra,24(sp)
    80200986:	6161                	addi	sp,sp,80
    80200988:	8082                	ret

000000008020098a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    8020098a:	4781                	li	a5,0
    8020098c:	00003717          	auipc	a4,0x3
    80200990:	67473703          	ld	a4,1652(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    80200994:	88ba                	mv	a7,a4
    80200996:	852a                	mv	a0,a0
    80200998:	85be                	mv	a1,a5
    8020099a:	863e                	mv	a2,a5
    8020099c:	00000073          	ecall
    802009a0:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    802009a2:	8082                	ret

00000000802009a4 <sbi_set_timer>:
    __asm__ volatile (
    802009a4:	4781                	li	a5,0
    802009a6:	00003717          	auipc	a4,0x3
    802009aa:	67a73703          	ld	a4,1658(a4) # 80204020 <SBI_SET_TIMER>
    802009ae:	88ba                	mv	a7,a4
    802009b0:	852a                	mv	a0,a0
    802009b2:	85be                	mv	a1,a5
    802009b4:	863e                	mv	a2,a5
    802009b6:	00000073          	ecall
    802009ba:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    802009bc:	8082                	ret

00000000802009be <sbi_shutdown>:
    __asm__ volatile (
    802009be:	4781                	li	a5,0
    802009c0:	00003717          	auipc	a4,0x3
    802009c4:	64873703          	ld	a4,1608(a4) # 80204008 <SBI_SHUTDOWN>
    802009c8:	88ba                	mv	a7,a4
    802009ca:	853e                	mv	a0,a5
    802009cc:	85be                	mv	a1,a5
    802009ce:	863e                	mv	a2,a5
    802009d0:	00000073          	ecall
    802009d4:	87aa                	mv	a5,a0


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    802009d6:	8082                	ret
