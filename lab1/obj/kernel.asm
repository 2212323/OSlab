
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
    8020000e:	ffe50513          	addi	a0,a0,-2 # 80204008 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	00660613          	addi	a2,a2,6 # 80204018 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	0eb000ef          	jal	ra,8020090c <memset>

    cons_init();  // init the console
    80200026:	13a000ef          	jal	ra,80200160 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	8f658593          	addi	a1,a1,-1802 # 80200920 <etext+0x2>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	90e50513          	addi	a0,a0,-1778 # 80200940 <etext+0x22>
    8020003a:	030000ef          	jal	ra,8020006a <cprintf>

    print_kerninfo();
    8020003e:	062000ef          	jal	ra,802000a0 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	12e000ef          	jal	ra,80200170 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0e8000ef          	jal	ra,8020012e <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	120000ef          	jal	ra,8020016a <intr_enable>
    
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
    80200058:	10a000ef          	jal	ra,80200162 <cons_putc>
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
    8020006c:	02810313          	addi	t1,sp,40 # 80204028 <end+0x10>
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
    80200094:	4a6000ef          	jal	ra,8020053a <vprintfmt>
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
    802000a6:	8a650513          	addi	a0,a0,-1882 # 80200948 <etext+0x2a>
void print_kerninfo(void) {
    802000aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000ac:	fbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5a58593          	addi	a1,a1,-166 # 8020000a <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	8b050513          	addi	a0,a0,-1872 # 80200968 <etext+0x4a>
    802000c0:	fabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	85a58593          	addi	a1,a1,-1958 # 8020091e <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	8bc50513          	addi	a0,a0,-1860 # 80200988 <etext+0x6a>
    802000d4:	f97ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3058593          	addi	a1,a1,-208 # 80204008 <ticks>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	8c850513          	addi	a0,a0,-1848 # 802009a8 <etext+0x8a>
    802000e8:	f83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f2c58593          	addi	a1,a1,-212 # 80204018 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	8d450513          	addi	a0,a0,-1836 # 802009c8 <etext+0xaa>
    802000fc:	f6fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200100:	00004597          	auipc	a1,0x4
    80200104:	31758593          	addi	a1,a1,791 # 80204417 <end+0x3ff>
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
    80200126:	8c650513          	addi	a0,a0,-1850 # 802009e8 <etext+0xca>
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
    80200146:	790000ef          	jal	ra,802008d6 <sbi_set_timer>
}
    8020014a:	60a2                	ld	ra,8(sp)
    ticks = 0;
    8020014c:	00004797          	auipc	a5,0x4
    80200150:	ea07be23          	sd	zero,-324(a5) # 80204008 <ticks>
    cprintf("++ setup timer interrupts\n");
    80200154:	00001517          	auipc	a0,0x1
    80200158:	8c450513          	addi	a0,a0,-1852 # 80200a18 <etext+0xfa>
}
    8020015c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    8020015e:	b731                	j	8020006a <cprintf>

0000000080200160 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200160:	8082                	ret

0000000080200162 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200162:	0ff57513          	zext.b	a0,a0
    80200166:	7560006f          	j	802008bc <sbi_console_putchar>

000000008020016a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    8020016a:	100167f3          	csrrsi	a5,sstatus,2
    8020016e:	8082                	ret

0000000080200170 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200170:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200174:	00000797          	auipc	a5,0x0
    80200178:	2a478793          	addi	a5,a5,676 # 80200418 <__alltraps>
    8020017c:	10579073          	csrw	stvec,a5
}
    80200180:	8082                	ret

0000000080200182 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200182:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    80200184:	1141                	addi	sp,sp,-16
    80200186:	e022                	sd	s0,0(sp)
    80200188:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020018a:	00001517          	auipc	a0,0x1
    8020018e:	8ae50513          	addi	a0,a0,-1874 # 80200a38 <etext+0x11a>
void print_regs(struct pushregs *gpr) {
    80200192:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200194:	ed7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    80200198:	640c                	ld	a1,8(s0)
    8020019a:	00001517          	auipc	a0,0x1
    8020019e:	8b650513          	addi	a0,a0,-1866 # 80200a50 <etext+0x132>
    802001a2:	ec9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001a6:	680c                	ld	a1,16(s0)
    802001a8:	00001517          	auipc	a0,0x1
    802001ac:	8c050513          	addi	a0,a0,-1856 # 80200a68 <etext+0x14a>
    802001b0:	ebbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001b4:	6c0c                	ld	a1,24(s0)
    802001b6:	00001517          	auipc	a0,0x1
    802001ba:	8ca50513          	addi	a0,a0,-1846 # 80200a80 <etext+0x162>
    802001be:	eadff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001c2:	700c                	ld	a1,32(s0)
    802001c4:	00001517          	auipc	a0,0x1
    802001c8:	8d450513          	addi	a0,a0,-1836 # 80200a98 <etext+0x17a>
    802001cc:	e9fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001d0:	740c                	ld	a1,40(s0)
    802001d2:	00001517          	auipc	a0,0x1
    802001d6:	8de50513          	addi	a0,a0,-1826 # 80200ab0 <etext+0x192>
    802001da:	e91ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001de:	780c                	ld	a1,48(s0)
    802001e0:	00001517          	auipc	a0,0x1
    802001e4:	8e850513          	addi	a0,a0,-1816 # 80200ac8 <etext+0x1aa>
    802001e8:	e83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    802001ec:	7c0c                	ld	a1,56(s0)
    802001ee:	00001517          	auipc	a0,0x1
    802001f2:	8f250513          	addi	a0,a0,-1806 # 80200ae0 <etext+0x1c2>
    802001f6:	e75ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    802001fa:	602c                	ld	a1,64(s0)
    802001fc:	00001517          	auipc	a0,0x1
    80200200:	8fc50513          	addi	a0,a0,-1796 # 80200af8 <etext+0x1da>
    80200204:	e67ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200208:	642c                	ld	a1,72(s0)
    8020020a:	00001517          	auipc	a0,0x1
    8020020e:	90650513          	addi	a0,a0,-1786 # 80200b10 <etext+0x1f2>
    80200212:	e59ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    80200216:	682c                	ld	a1,80(s0)
    80200218:	00001517          	auipc	a0,0x1
    8020021c:	91050513          	addi	a0,a0,-1776 # 80200b28 <etext+0x20a>
    80200220:	e4bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200224:	6c2c                	ld	a1,88(s0)
    80200226:	00001517          	auipc	a0,0x1
    8020022a:	91a50513          	addi	a0,a0,-1766 # 80200b40 <etext+0x222>
    8020022e:	e3dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200232:	702c                	ld	a1,96(s0)
    80200234:	00001517          	auipc	a0,0x1
    80200238:	92450513          	addi	a0,a0,-1756 # 80200b58 <etext+0x23a>
    8020023c:	e2fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200240:	742c                	ld	a1,104(s0)
    80200242:	00001517          	auipc	a0,0x1
    80200246:	92e50513          	addi	a0,a0,-1746 # 80200b70 <etext+0x252>
    8020024a:	e21ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    8020024e:	782c                	ld	a1,112(s0)
    80200250:	00001517          	auipc	a0,0x1
    80200254:	93850513          	addi	a0,a0,-1736 # 80200b88 <etext+0x26a>
    80200258:	e13ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    8020025c:	7c2c                	ld	a1,120(s0)
    8020025e:	00001517          	auipc	a0,0x1
    80200262:	94250513          	addi	a0,a0,-1726 # 80200ba0 <etext+0x282>
    80200266:	e05ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    8020026a:	604c                	ld	a1,128(s0)
    8020026c:	00001517          	auipc	a0,0x1
    80200270:	94c50513          	addi	a0,a0,-1716 # 80200bb8 <etext+0x29a>
    80200274:	df7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200278:	644c                	ld	a1,136(s0)
    8020027a:	00001517          	auipc	a0,0x1
    8020027e:	95650513          	addi	a0,a0,-1706 # 80200bd0 <etext+0x2b2>
    80200282:	de9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    80200286:	684c                	ld	a1,144(s0)
    80200288:	00001517          	auipc	a0,0x1
    8020028c:	96050513          	addi	a0,a0,-1696 # 80200be8 <etext+0x2ca>
    80200290:	ddbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    80200294:	6c4c                	ld	a1,152(s0)
    80200296:	00001517          	auipc	a0,0x1
    8020029a:	96a50513          	addi	a0,a0,-1686 # 80200c00 <etext+0x2e2>
    8020029e:	dcdff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002a2:	704c                	ld	a1,160(s0)
    802002a4:	00001517          	auipc	a0,0x1
    802002a8:	97450513          	addi	a0,a0,-1676 # 80200c18 <etext+0x2fa>
    802002ac:	dbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002b0:	744c                	ld	a1,168(s0)
    802002b2:	00001517          	auipc	a0,0x1
    802002b6:	97e50513          	addi	a0,a0,-1666 # 80200c30 <etext+0x312>
    802002ba:	db1ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002be:	784c                	ld	a1,176(s0)
    802002c0:	00001517          	auipc	a0,0x1
    802002c4:	98850513          	addi	a0,a0,-1656 # 80200c48 <etext+0x32a>
    802002c8:	da3ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002cc:	7c4c                	ld	a1,184(s0)
    802002ce:	00001517          	auipc	a0,0x1
    802002d2:	99250513          	addi	a0,a0,-1646 # 80200c60 <etext+0x342>
    802002d6:	d95ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002da:	606c                	ld	a1,192(s0)
    802002dc:	00001517          	auipc	a0,0x1
    802002e0:	99c50513          	addi	a0,a0,-1636 # 80200c78 <etext+0x35a>
    802002e4:	d87ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002e8:	646c                	ld	a1,200(s0)
    802002ea:	00001517          	auipc	a0,0x1
    802002ee:	9a650513          	addi	a0,a0,-1626 # 80200c90 <etext+0x372>
    802002f2:	d79ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    802002f6:	686c                	ld	a1,208(s0)
    802002f8:	00001517          	auipc	a0,0x1
    802002fc:	9b050513          	addi	a0,a0,-1616 # 80200ca8 <etext+0x38a>
    80200300:	d6bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200304:	6c6c                	ld	a1,216(s0)
    80200306:	00001517          	auipc	a0,0x1
    8020030a:	9ba50513          	addi	a0,a0,-1606 # 80200cc0 <etext+0x3a2>
    8020030e:	d5dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200312:	706c                	ld	a1,224(s0)
    80200314:	00001517          	auipc	a0,0x1
    80200318:	9c450513          	addi	a0,a0,-1596 # 80200cd8 <etext+0x3ba>
    8020031c:	d4fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200320:	746c                	ld	a1,232(s0)
    80200322:	00001517          	auipc	a0,0x1
    80200326:	9ce50513          	addi	a0,a0,-1586 # 80200cf0 <etext+0x3d2>
    8020032a:	d41ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    8020032e:	786c                	ld	a1,240(s0)
    80200330:	00001517          	auipc	a0,0x1
    80200334:	9d850513          	addi	a0,a0,-1576 # 80200d08 <etext+0x3ea>
    80200338:	d33ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020033c:	7c6c                	ld	a1,248(s0)
}
    8020033e:	6402                	ld	s0,0(sp)
    80200340:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200342:	00001517          	auipc	a0,0x1
    80200346:	9de50513          	addi	a0,a0,-1570 # 80200d20 <etext+0x402>
}
    8020034a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020034c:	bb39                	j	8020006a <cprintf>

000000008020034e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    8020034e:	1141                	addi	sp,sp,-16
    80200350:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200352:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200354:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200356:	00001517          	auipc	a0,0x1
    8020035a:	9e250513          	addi	a0,a0,-1566 # 80200d38 <etext+0x41a>
void print_trapframe(struct trapframe *tf) {
    8020035e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200360:	d0bff0ef          	jal	ra,8020006a <cprintf>
    print_regs(&tf->gpr);
    80200364:	8522                	mv	a0,s0
    80200366:	e1dff0ef          	jal	ra,80200182 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    8020036a:	10043583          	ld	a1,256(s0)
    8020036e:	00001517          	auipc	a0,0x1
    80200372:	9e250513          	addi	a0,a0,-1566 # 80200d50 <etext+0x432>
    80200376:	cf5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    8020037a:	10843583          	ld	a1,264(s0)
    8020037e:	00001517          	auipc	a0,0x1
    80200382:	9ea50513          	addi	a0,a0,-1558 # 80200d68 <etext+0x44a>
    80200386:	ce5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    8020038a:	11043583          	ld	a1,272(s0)
    8020038e:	00001517          	auipc	a0,0x1
    80200392:	9f250513          	addi	a0,a0,-1550 # 80200d80 <etext+0x462>
    80200396:	cd5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    8020039a:	11843583          	ld	a1,280(s0)
}
    8020039e:	6402                	ld	s0,0(sp)
    802003a0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003a2:	00001517          	auipc	a0,0x1
    802003a6:	9f650513          	addi	a0,a0,-1546 # 80200d98 <etext+0x47a>
}
    802003aa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003ac:	b97d                	j	8020006a <cprintf>

00000000802003ae <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003ae:	11853783          	ld	a5,280(a0)
    802003b2:	472d                	li	a4,11
    802003b4:	0786                	slli	a5,a5,0x1
    802003b6:	8385                	srli	a5,a5,0x1
    802003b8:	04f76563          	bltu	a4,a5,80200402 <interrupt_handler+0x54>
    802003bc:	00001717          	auipc	a4,0x1
    802003c0:	a9470713          	addi	a4,a4,-1388 # 80200e50 <etext+0x532>
    802003c4:	078a                	slli	a5,a5,0x2
    802003c6:	97ba                	add	a5,a5,a4
    802003c8:	439c                	lw	a5,0(a5)
    802003ca:	97ba                	add	a5,a5,a4
    802003cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003ce:	00001517          	auipc	a0,0x1
    802003d2:	a4250513          	addi	a0,a0,-1470 # 80200e10 <etext+0x4f2>
    802003d6:	b951                	j	8020006a <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003d8:	00001517          	auipc	a0,0x1
    802003dc:	a1850513          	addi	a0,a0,-1512 # 80200df0 <etext+0x4d2>
    802003e0:	b169                	j	8020006a <cprintf>
            cprintf("User software interrupt\n");
    802003e2:	00001517          	auipc	a0,0x1
    802003e6:	9ce50513          	addi	a0,a0,-1586 # 80200db0 <etext+0x492>
    802003ea:	b141                	j	8020006a <cprintf>
            cprintf("Supervisor software interrupt\n");
    802003ec:	00001517          	auipc	a0,0x1
    802003f0:	9e450513          	addi	a0,a0,-1564 # 80200dd0 <etext+0x4b2>
    802003f4:	b99d                	j	8020006a <cprintf>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    802003f6:	8082                	ret
            cprintf("Supervisor external interrupt\n");
    802003f8:	00001517          	auipc	a0,0x1
    802003fc:	a3850513          	addi	a0,a0,-1480 # 80200e30 <etext+0x512>
    80200400:	b1ad                	j	8020006a <cprintf>
            print_trapframe(tf);
    80200402:	b7b1                	j	8020034e <print_trapframe>

0000000080200404 <trap>:
    }
}

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    80200404:	11853783          	ld	a5,280(a0)
    80200408:	0007c763          	bltz	a5,80200416 <trap+0x12>
    switch (tf->cause) {
    8020040c:	472d                	li	a4,11
    8020040e:	00f76363          	bltu	a4,a5,80200414 <trap+0x10>
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) { trap_dispatch(tf); }
    80200412:	8082                	ret
            print_trapframe(tf);
    80200414:	bf2d                	j	8020034e <print_trapframe>
        interrupt_handler(tf);
    80200416:	bf61                	j	802003ae <interrupt_handler>

0000000080200418 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    80200418:	14011073          	csrw	sscratch,sp
    8020041c:	712d                	addi	sp,sp,-288
    8020041e:	e002                	sd	zero,0(sp)
    80200420:	e406                	sd	ra,8(sp)
    80200422:	ec0e                	sd	gp,24(sp)
    80200424:	f012                	sd	tp,32(sp)
    80200426:	f416                	sd	t0,40(sp)
    80200428:	f81a                	sd	t1,48(sp)
    8020042a:	fc1e                	sd	t2,56(sp)
    8020042c:	e0a2                	sd	s0,64(sp)
    8020042e:	e4a6                	sd	s1,72(sp)
    80200430:	e8aa                	sd	a0,80(sp)
    80200432:	ecae                	sd	a1,88(sp)
    80200434:	f0b2                	sd	a2,96(sp)
    80200436:	f4b6                	sd	a3,104(sp)
    80200438:	f8ba                	sd	a4,112(sp)
    8020043a:	fcbe                	sd	a5,120(sp)
    8020043c:	e142                	sd	a6,128(sp)
    8020043e:	e546                	sd	a7,136(sp)
    80200440:	e94a                	sd	s2,144(sp)
    80200442:	ed4e                	sd	s3,152(sp)
    80200444:	f152                	sd	s4,160(sp)
    80200446:	f556                	sd	s5,168(sp)
    80200448:	f95a                	sd	s6,176(sp)
    8020044a:	fd5e                	sd	s7,184(sp)
    8020044c:	e1e2                	sd	s8,192(sp)
    8020044e:	e5e6                	sd	s9,200(sp)
    80200450:	e9ea                	sd	s10,208(sp)
    80200452:	edee                	sd	s11,216(sp)
    80200454:	f1f2                	sd	t3,224(sp)
    80200456:	f5f6                	sd	t4,232(sp)
    80200458:	f9fa                	sd	t5,240(sp)
    8020045a:	fdfe                	sd	t6,248(sp)
    8020045c:	14001473          	csrrw	s0,sscratch,zero
    80200460:	100024f3          	csrr	s1,sstatus
    80200464:	14102973          	csrr	s2,sepc
    80200468:	143029f3          	csrr	s3,stval
    8020046c:	14202a73          	csrr	s4,scause
    80200470:	e822                	sd	s0,16(sp)
    80200472:	e226                	sd	s1,256(sp)
    80200474:	e64a                	sd	s2,264(sp)
    80200476:	ea4e                	sd	s3,272(sp)
    80200478:	ee52                	sd	s4,280(sp)

    move  a0, sp
    8020047a:	850a                	mv	a0,sp
    jal trap
    8020047c:	f89ff0ef          	jal	ra,80200404 <trap>

0000000080200480 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    80200480:	6492                	ld	s1,256(sp)
    80200482:	6932                	ld	s2,264(sp)
    80200484:	10049073          	csrw	sstatus,s1
    80200488:	14191073          	csrw	sepc,s2
    8020048c:	60a2                	ld	ra,8(sp)
    8020048e:	61e2                	ld	gp,24(sp)
    80200490:	7202                	ld	tp,32(sp)
    80200492:	72a2                	ld	t0,40(sp)
    80200494:	7342                	ld	t1,48(sp)
    80200496:	73e2                	ld	t2,56(sp)
    80200498:	6406                	ld	s0,64(sp)
    8020049a:	64a6                	ld	s1,72(sp)
    8020049c:	6546                	ld	a0,80(sp)
    8020049e:	65e6                	ld	a1,88(sp)
    802004a0:	7606                	ld	a2,96(sp)
    802004a2:	76a6                	ld	a3,104(sp)
    802004a4:	7746                	ld	a4,112(sp)
    802004a6:	77e6                	ld	a5,120(sp)
    802004a8:	680a                	ld	a6,128(sp)
    802004aa:	68aa                	ld	a7,136(sp)
    802004ac:	694a                	ld	s2,144(sp)
    802004ae:	69ea                	ld	s3,152(sp)
    802004b0:	7a0a                	ld	s4,160(sp)
    802004b2:	7aaa                	ld	s5,168(sp)
    802004b4:	7b4a                	ld	s6,176(sp)
    802004b6:	7bea                	ld	s7,184(sp)
    802004b8:	6c0e                	ld	s8,192(sp)
    802004ba:	6cae                	ld	s9,200(sp)
    802004bc:	6d4e                	ld	s10,208(sp)
    802004be:	6dee                	ld	s11,216(sp)
    802004c0:	7e0e                	ld	t3,224(sp)
    802004c2:	7eae                	ld	t4,232(sp)
    802004c4:	7f4e                	ld	t5,240(sp)
    802004c6:	7fee                	ld	t6,248(sp)
    802004c8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    802004ca:	10200073          	sret

00000000802004ce <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    802004ce:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802004d2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    802004d4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802004d8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    802004da:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    802004de:	f022                	sd	s0,32(sp)
    802004e0:	ec26                	sd	s1,24(sp)
    802004e2:	e84a                	sd	s2,16(sp)
    802004e4:	f406                	sd	ra,40(sp)
    802004e6:	e44e                	sd	s3,8(sp)
    802004e8:	84aa                	mv	s1,a0
    802004ea:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    802004ec:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    802004f0:	2a01                	sext.w	s4,s4
    if (num >= base) {
    802004f2:	03067e63          	bgeu	a2,a6,8020052e <printnum+0x60>
    802004f6:	89be                	mv	s3,a5
        while (-- width > 0)
    802004f8:	00805763          	blez	s0,80200506 <printnum+0x38>
    802004fc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    802004fe:	85ca                	mv	a1,s2
    80200500:	854e                	mv	a0,s3
    80200502:	9482                	jalr	s1
        while (-- width > 0)
    80200504:	fc65                	bnez	s0,802004fc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    80200506:	1a02                	slli	s4,s4,0x20
    80200508:	00001797          	auipc	a5,0x1
    8020050c:	97878793          	addi	a5,a5,-1672 # 80200e80 <etext+0x562>
    80200510:	020a5a13          	srli	s4,s4,0x20
    80200514:	9a3e                	add	s4,s4,a5
}
    80200516:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200518:	000a4503          	lbu	a0,0(s4)
}
    8020051c:	70a2                	ld	ra,40(sp)
    8020051e:	69a2                	ld	s3,8(sp)
    80200520:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200522:	85ca                	mv	a1,s2
    80200524:	87a6                	mv	a5,s1
}
    80200526:	6942                	ld	s2,16(sp)
    80200528:	64e2                	ld	s1,24(sp)
    8020052a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    8020052c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    8020052e:	03065633          	divu	a2,a2,a6
    80200532:	8722                	mv	a4,s0
    80200534:	f9bff0ef          	jal	ra,802004ce <printnum>
    80200538:	b7f9                	j	80200506 <printnum+0x38>

000000008020053a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    8020053a:	7119                	addi	sp,sp,-128
    8020053c:	f4a6                	sd	s1,104(sp)
    8020053e:	f0ca                	sd	s2,96(sp)
    80200540:	ecce                	sd	s3,88(sp)
    80200542:	e8d2                	sd	s4,80(sp)
    80200544:	e4d6                	sd	s5,72(sp)
    80200546:	e0da                	sd	s6,64(sp)
    80200548:	fc5e                	sd	s7,56(sp)
    8020054a:	f06a                	sd	s10,32(sp)
    8020054c:	fc86                	sd	ra,120(sp)
    8020054e:	f8a2                	sd	s0,112(sp)
    80200550:	f862                	sd	s8,48(sp)
    80200552:	f466                	sd	s9,40(sp)
    80200554:	ec6e                	sd	s11,24(sp)
    80200556:	892a                	mv	s2,a0
    80200558:	84ae                	mv	s1,a1
    8020055a:	8d32                	mv	s10,a2
    8020055c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020055e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200562:	5b7d                	li	s6,-1
    80200564:	00001a97          	auipc	s5,0x1
    80200568:	950a8a93          	addi	s5,s5,-1712 # 80200eb4 <etext+0x596>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020056c:	00001b97          	auipc	s7,0x1
    80200570:	b24b8b93          	addi	s7,s7,-1244 # 80201090 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200574:	000d4503          	lbu	a0,0(s10)
    80200578:	001d0413          	addi	s0,s10,1
    8020057c:	01350a63          	beq	a0,s3,80200590 <vprintfmt+0x56>
            if (ch == '\0') {
    80200580:	c121                	beqz	a0,802005c0 <vprintfmt+0x86>
            putch(ch, putdat);
    80200582:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200584:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    80200586:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200588:	fff44503          	lbu	a0,-1(s0)
    8020058c:	ff351ae3          	bne	a0,s3,80200580 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    80200590:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200594:	02000793          	li	a5,32
        lflag = altflag = 0;
    80200598:	4c81                	li	s9,0
    8020059a:	4881                	li	a7,0
        width = precision = -1;
    8020059c:	5c7d                	li	s8,-1
    8020059e:	5dfd                	li	s11,-1
    802005a0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    802005a4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    802005a6:	fdd6059b          	addiw	a1,a2,-35
    802005aa:	0ff5f593          	zext.b	a1,a1
    802005ae:	00140d13          	addi	s10,s0,1
    802005b2:	04b56263          	bltu	a0,a1,802005f6 <vprintfmt+0xbc>
    802005b6:	058a                	slli	a1,a1,0x2
    802005b8:	95d6                	add	a1,a1,s5
    802005ba:	4194                	lw	a3,0(a1)
    802005bc:	96d6                	add	a3,a3,s5
    802005be:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    802005c0:	70e6                	ld	ra,120(sp)
    802005c2:	7446                	ld	s0,112(sp)
    802005c4:	74a6                	ld	s1,104(sp)
    802005c6:	7906                	ld	s2,96(sp)
    802005c8:	69e6                	ld	s3,88(sp)
    802005ca:	6a46                	ld	s4,80(sp)
    802005cc:	6aa6                	ld	s5,72(sp)
    802005ce:	6b06                	ld	s6,64(sp)
    802005d0:	7be2                	ld	s7,56(sp)
    802005d2:	7c42                	ld	s8,48(sp)
    802005d4:	7ca2                	ld	s9,40(sp)
    802005d6:	7d02                	ld	s10,32(sp)
    802005d8:	6de2                	ld	s11,24(sp)
    802005da:	6109                	addi	sp,sp,128
    802005dc:	8082                	ret
            padc = '0';
    802005de:	87b2                	mv	a5,a2
            goto reswitch;
    802005e0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802005e4:	846a                	mv	s0,s10
    802005e6:	00140d13          	addi	s10,s0,1
    802005ea:	fdd6059b          	addiw	a1,a2,-35
    802005ee:	0ff5f593          	zext.b	a1,a1
    802005f2:	fcb572e3          	bgeu	a0,a1,802005b6 <vprintfmt+0x7c>
            putch('%', putdat);
    802005f6:	85a6                	mv	a1,s1
    802005f8:	02500513          	li	a0,37
    802005fc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802005fe:	fff44783          	lbu	a5,-1(s0)
    80200602:	8d22                	mv	s10,s0
    80200604:	f73788e3          	beq	a5,s3,80200574 <vprintfmt+0x3a>
    80200608:	ffed4783          	lbu	a5,-2(s10)
    8020060c:	1d7d                	addi	s10,s10,-1
    8020060e:	ff379de3          	bne	a5,s3,80200608 <vprintfmt+0xce>
    80200612:	b78d                	j	80200574 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    80200614:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    80200618:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    8020061c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    8020061e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    80200622:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200626:	02d86463          	bltu	a6,a3,8020064e <vprintfmt+0x114>
                ch = *fmt;
    8020062a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    8020062e:	002c169b          	slliw	a3,s8,0x2
    80200632:	0186873b          	addw	a4,a3,s8
    80200636:	0017171b          	slliw	a4,a4,0x1
    8020063a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    8020063c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    80200640:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200642:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    80200646:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    8020064a:	fed870e3          	bgeu	a6,a3,8020062a <vprintfmt+0xf0>
            if (width < 0)
    8020064e:	f40ddce3          	bgez	s11,802005a6 <vprintfmt+0x6c>
                width = precision, precision = -1;
    80200652:	8de2                	mv	s11,s8
    80200654:	5c7d                	li	s8,-1
    80200656:	bf81                	j	802005a6 <vprintfmt+0x6c>
            if (width < 0)
    80200658:	fffdc693          	not	a3,s11
    8020065c:	96fd                	srai	a3,a3,0x3f
    8020065e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    80200662:	00144603          	lbu	a2,1(s0)
    80200666:	2d81                	sext.w	s11,s11
    80200668:	846a                	mv	s0,s10
            goto reswitch;
    8020066a:	bf35                	j	802005a6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    8020066c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    80200670:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200674:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200676:	846a                	mv	s0,s10
            goto process_precision;
    80200678:	bfd9                	j	8020064e <vprintfmt+0x114>
    if (lflag >= 2) {
    8020067a:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020067c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200680:	01174463          	blt	a4,a7,80200688 <vprintfmt+0x14e>
    else if (lflag) {
    80200684:	1a088e63          	beqz	a7,80200840 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    80200688:	000a3603          	ld	a2,0(s4)
    8020068c:	46c1                	li	a3,16
    8020068e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    80200690:	2781                	sext.w	a5,a5
    80200692:	876e                	mv	a4,s11
    80200694:	85a6                	mv	a1,s1
    80200696:	854a                	mv	a0,s2
    80200698:	e37ff0ef          	jal	ra,802004ce <printnum>
            break;
    8020069c:	bde1                	j	80200574 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    8020069e:	000a2503          	lw	a0,0(s4)
    802006a2:	85a6                	mv	a1,s1
    802006a4:	0a21                	addi	s4,s4,8
    802006a6:	9902                	jalr	s2
            break;
    802006a8:	b5f1                	j	80200574 <vprintfmt+0x3a>
    if (lflag >= 2) {
    802006aa:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802006ac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802006b0:	01174463          	blt	a4,a7,802006b8 <vprintfmt+0x17e>
    else if (lflag) {
    802006b4:	18088163          	beqz	a7,80200836 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    802006b8:	000a3603          	ld	a2,0(s4)
    802006bc:	46a9                	li	a3,10
    802006be:	8a2e                	mv	s4,a1
    802006c0:	bfc1                	j	80200690 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    802006c2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    802006c6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    802006c8:	846a                	mv	s0,s10
            goto reswitch;
    802006ca:	bdf1                	j	802005a6 <vprintfmt+0x6c>
            putch(ch, putdat);
    802006cc:	85a6                	mv	a1,s1
    802006ce:	02500513          	li	a0,37
    802006d2:	9902                	jalr	s2
            break;
    802006d4:	b545                	j	80200574 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    802006d6:	00144603          	lbu	a2,1(s0)
            lflag ++;
    802006da:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    802006dc:	846a                	mv	s0,s10
            goto reswitch;
    802006de:	b5e1                	j	802005a6 <vprintfmt+0x6c>
    if (lflag >= 2) {
    802006e0:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802006e2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802006e6:	01174463          	blt	a4,a7,802006ee <vprintfmt+0x1b4>
    else if (lflag) {
    802006ea:	14088163          	beqz	a7,8020082c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    802006ee:	000a3603          	ld	a2,0(s4)
    802006f2:	46a1                	li	a3,8
    802006f4:	8a2e                	mv	s4,a1
    802006f6:	bf69                	j	80200690 <vprintfmt+0x156>
            putch('0', putdat);
    802006f8:	03000513          	li	a0,48
    802006fc:	85a6                	mv	a1,s1
    802006fe:	e03e                	sd	a5,0(sp)
    80200700:	9902                	jalr	s2
            putch('x', putdat);
    80200702:	85a6                	mv	a1,s1
    80200704:	07800513          	li	a0,120
    80200708:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    8020070a:	0a21                	addi	s4,s4,8
            goto number;
    8020070c:	6782                	ld	a5,0(sp)
    8020070e:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    80200710:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    80200714:	bfb5                	j	80200690 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200716:	000a3403          	ld	s0,0(s4)
    8020071a:	008a0713          	addi	a4,s4,8
    8020071e:	e03a                	sd	a4,0(sp)
    80200720:	14040263          	beqz	s0,80200864 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    80200724:	0fb05763          	blez	s11,80200812 <vprintfmt+0x2d8>
    80200728:	02d00693          	li	a3,45
    8020072c:	0cd79163          	bne	a5,a3,802007ee <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200730:	00044783          	lbu	a5,0(s0)
    80200734:	0007851b          	sext.w	a0,a5
    80200738:	cf85                	beqz	a5,80200770 <vprintfmt+0x236>
    8020073a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020073e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200742:	000c4563          	bltz	s8,8020074c <vprintfmt+0x212>
    80200746:	3c7d                	addiw	s8,s8,-1
    80200748:	036c0263          	beq	s8,s6,8020076c <vprintfmt+0x232>
                    putch('?', putdat);
    8020074c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020074e:	0e0c8e63          	beqz	s9,8020084a <vprintfmt+0x310>
    80200752:	3781                	addiw	a5,a5,-32
    80200754:	0ef47b63          	bgeu	s0,a5,8020084a <vprintfmt+0x310>
                    putch('?', putdat);
    80200758:	03f00513          	li	a0,63
    8020075c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020075e:	000a4783          	lbu	a5,0(s4)
    80200762:	3dfd                	addiw	s11,s11,-1
    80200764:	0a05                	addi	s4,s4,1
    80200766:	0007851b          	sext.w	a0,a5
    8020076a:	ffe1                	bnez	a5,80200742 <vprintfmt+0x208>
            for (; width > 0; width --) {
    8020076c:	01b05963          	blez	s11,8020077e <vprintfmt+0x244>
    80200770:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200772:	85a6                	mv	a1,s1
    80200774:	02000513          	li	a0,32
    80200778:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020077a:	fe0d9be3          	bnez	s11,80200770 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020077e:	6a02                	ld	s4,0(sp)
    80200780:	bbd5                	j	80200574 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200782:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200784:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    80200788:	01174463          	blt	a4,a7,80200790 <vprintfmt+0x256>
    else if (lflag) {
    8020078c:	08088d63          	beqz	a7,80200826 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    80200790:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    80200794:	0a044d63          	bltz	s0,8020084e <vprintfmt+0x314>
            num = getint(&ap, lflag);
    80200798:	8622                	mv	a2,s0
    8020079a:	8a66                	mv	s4,s9
    8020079c:	46a9                	li	a3,10
    8020079e:	bdcd                	j	80200690 <vprintfmt+0x156>
            err = va_arg(ap, int);
    802007a0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802007a4:	4719                	li	a4,6
            err = va_arg(ap, int);
    802007a6:	0a21                	addi	s4,s4,8
            if (err < 0) {
    802007a8:	41f7d69b          	sraiw	a3,a5,0x1f
    802007ac:	8fb5                	xor	a5,a5,a3
    802007ae:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802007b2:	02d74163          	blt	a4,a3,802007d4 <vprintfmt+0x29a>
    802007b6:	00369793          	slli	a5,a3,0x3
    802007ba:	97de                	add	a5,a5,s7
    802007bc:	639c                	ld	a5,0(a5)
    802007be:	cb99                	beqz	a5,802007d4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    802007c0:	86be                	mv	a3,a5
    802007c2:	00000617          	auipc	a2,0x0
    802007c6:	6ee60613          	addi	a2,a2,1774 # 80200eb0 <etext+0x592>
    802007ca:	85a6                	mv	a1,s1
    802007cc:	854a                	mv	a0,s2
    802007ce:	0ce000ef          	jal	ra,8020089c <printfmt>
    802007d2:	b34d                	j	80200574 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    802007d4:	00000617          	auipc	a2,0x0
    802007d8:	6cc60613          	addi	a2,a2,1740 # 80200ea0 <etext+0x582>
    802007dc:	85a6                	mv	a1,s1
    802007de:	854a                	mv	a0,s2
    802007e0:	0bc000ef          	jal	ra,8020089c <printfmt>
    802007e4:	bb41                	j	80200574 <vprintfmt+0x3a>
                p = "(null)";
    802007e6:	00000417          	auipc	s0,0x0
    802007ea:	6b240413          	addi	s0,s0,1714 # 80200e98 <etext+0x57a>
                for (width -= strnlen(p, precision); width > 0; width --) {
    802007ee:	85e2                	mv	a1,s8
    802007f0:	8522                	mv	a0,s0
    802007f2:	e43e                	sd	a5,8(sp)
    802007f4:	0fc000ef          	jal	ra,802008f0 <strnlen>
    802007f8:	40ad8dbb          	subw	s11,s11,a0
    802007fc:	01b05b63          	blez	s11,80200812 <vprintfmt+0x2d8>
                    putch(padc, putdat);
    80200800:	67a2                	ld	a5,8(sp)
    80200802:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200806:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200808:	85a6                	mv	a1,s1
    8020080a:	8552                	mv	a0,s4
    8020080c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020080e:	fe0d9ce3          	bnez	s11,80200806 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200812:	00044783          	lbu	a5,0(s0)
    80200816:	00140a13          	addi	s4,s0,1
    8020081a:	0007851b          	sext.w	a0,a5
    8020081e:	d3a5                	beqz	a5,8020077e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    80200820:	05e00413          	li	s0,94
    80200824:	bf39                	j	80200742 <vprintfmt+0x208>
        return va_arg(*ap, int);
    80200826:	000a2403          	lw	s0,0(s4)
    8020082a:	b7ad                	j	80200794 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    8020082c:	000a6603          	lwu	a2,0(s4)
    80200830:	46a1                	li	a3,8
    80200832:	8a2e                	mv	s4,a1
    80200834:	bdb1                	j	80200690 <vprintfmt+0x156>
    80200836:	000a6603          	lwu	a2,0(s4)
    8020083a:	46a9                	li	a3,10
    8020083c:	8a2e                	mv	s4,a1
    8020083e:	bd89                	j	80200690 <vprintfmt+0x156>
    80200840:	000a6603          	lwu	a2,0(s4)
    80200844:	46c1                	li	a3,16
    80200846:	8a2e                	mv	s4,a1
    80200848:	b5a1                	j	80200690 <vprintfmt+0x156>
                    putch(ch, putdat);
    8020084a:	9902                	jalr	s2
    8020084c:	bf09                	j	8020075e <vprintfmt+0x224>
                putch('-', putdat);
    8020084e:	85a6                	mv	a1,s1
    80200850:	02d00513          	li	a0,45
    80200854:	e03e                	sd	a5,0(sp)
    80200856:	9902                	jalr	s2
                num = -(long long)num;
    80200858:	6782                	ld	a5,0(sp)
    8020085a:	8a66                	mv	s4,s9
    8020085c:	40800633          	neg	a2,s0
    80200860:	46a9                	li	a3,10
    80200862:	b53d                	j	80200690 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    80200864:	03b05163          	blez	s11,80200886 <vprintfmt+0x34c>
    80200868:	02d00693          	li	a3,45
    8020086c:	f6d79de3          	bne	a5,a3,802007e6 <vprintfmt+0x2ac>
                p = "(null)";
    80200870:	00000417          	auipc	s0,0x0
    80200874:	62840413          	addi	s0,s0,1576 # 80200e98 <etext+0x57a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200878:	02800793          	li	a5,40
    8020087c:	02800513          	li	a0,40
    80200880:	00140a13          	addi	s4,s0,1
    80200884:	bd6d                	j	8020073e <vprintfmt+0x204>
    80200886:	00000a17          	auipc	s4,0x0
    8020088a:	613a0a13          	addi	s4,s4,1555 # 80200e99 <etext+0x57b>
    8020088e:	02800513          	li	a0,40
    80200892:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    80200896:	05e00413          	li	s0,94
    8020089a:	b565                	j	80200742 <vprintfmt+0x208>

000000008020089c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020089c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    8020089e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802008a2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802008a4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802008a6:	ec06                	sd	ra,24(sp)
    802008a8:	f83a                	sd	a4,48(sp)
    802008aa:	fc3e                	sd	a5,56(sp)
    802008ac:	e0c2                	sd	a6,64(sp)
    802008ae:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    802008b0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802008b2:	c89ff0ef          	jal	ra,8020053a <vprintfmt>
}
    802008b6:	60e2                	ld	ra,24(sp)
    802008b8:	6161                	addi	sp,sp,80
    802008ba:	8082                	ret

00000000802008bc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    802008bc:	4781                	li	a5,0
    802008be:	00003717          	auipc	a4,0x3
    802008c2:	74273703          	ld	a4,1858(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    802008c6:	88ba                	mv	a7,a4
    802008c8:	852a                	mv	a0,a0
    802008ca:	85be                	mv	a1,a5
    802008cc:	863e                	mv	a2,a5
    802008ce:	00000073          	ecall
    802008d2:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    802008d4:	8082                	ret

00000000802008d6 <sbi_set_timer>:
    __asm__ volatile (
    802008d6:	4781                	li	a5,0
    802008d8:	00003717          	auipc	a4,0x3
    802008dc:	73873703          	ld	a4,1848(a4) # 80204010 <SBI_SET_TIMER>
    802008e0:	88ba                	mv	a7,a4
    802008e2:	852a                	mv	a0,a0
    802008e4:	85be                	mv	a1,a5
    802008e6:	863e                	mv	a2,a5
    802008e8:	00000073          	ecall
    802008ec:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    802008ee:	8082                	ret

00000000802008f0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    802008f0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    802008f2:	e589                	bnez	a1,802008fc <strnlen+0xc>
    802008f4:	a811                	j	80200908 <strnlen+0x18>
        cnt ++;
    802008f6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802008f8:	00f58863          	beq	a1,a5,80200908 <strnlen+0x18>
    802008fc:	00f50733          	add	a4,a0,a5
    80200900:	00074703          	lbu	a4,0(a4)
    80200904:	fb6d                	bnez	a4,802008f6 <strnlen+0x6>
    80200906:	85be                	mv	a1,a5
    }
    return cnt;
}
    80200908:	852e                	mv	a0,a1
    8020090a:	8082                	ret

000000008020090c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    8020090c:	ca01                	beqz	a2,8020091c <memset+0x10>
    8020090e:	962a                	add	a2,a2,a0
    char *p = s;
    80200910:	87aa                	mv	a5,a0
        *p ++ = c;
    80200912:	0785                	addi	a5,a5,1
    80200914:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    80200918:	fec79de3          	bne	a5,a2,80200912 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    8020091c:	8082                	ret
