
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
    80200000:	00003117          	auipc	sp,0x3
    80200004:	00010113          	mv	sp,sp
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
    8020000a:	00003517          	auipc	a0,0x3
    8020000e:	ffe50513          	addi	a0,a0,-2 # 80203008 <edata>
    80200012:	00003617          	auipc	a2,0x3
    80200016:	ff660613          	addi	a2,a2,-10 # 80203008 <edata>
    8020001a:	1141                	addi	sp,sp,-16
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
    80200020:	e406                	sd	ra,8(sp)
    80200022:	0b4000ef          	jal	ra,802000d6 <memset>
    80200026:	00000597          	auipc	a1,0x0
    8020002a:	4ca58593          	addi	a1,a1,1226 # 802004f0 <sbi_console_putchar+0x1a>
    8020002e:	00000517          	auipc	a0,0x0
    80200032:	4e250513          	addi	a0,a0,1250 # 80200510 <sbi_console_putchar+0x3a>
    80200036:	048000ef          	jal	ra,8020007e <cprintf>
    8020003a:	00000597          	auipc	a1,0x0
    8020003e:	4b658593          	addi	a1,a1,1206 # 802004f0 <sbi_console_putchar+0x1a>
    80200042:	00000517          	auipc	a0,0x0
    80200046:	4ce50513          	addi	a0,a0,1230 # 80200510 <sbi_console_putchar+0x3a>
    8020004a:	034000ef          	jal	ra,8020007e <cprintf>
    8020004e:	00000597          	auipc	a1,0x0
    80200052:	4a258593          	addi	a1,a1,1186 # 802004f0 <sbi_console_putchar+0x1a>
    80200056:	00000517          	auipc	a0,0x0
    8020005a:	4ba50513          	addi	a0,a0,1210 # 80200510 <sbi_console_putchar+0x3a>
    8020005e:	020000ef          	jal	ra,8020007e <cprintf>
    80200062:	a001                	j	80200062 <kern_init+0x58>

0000000080200064 <cputch>:
    80200064:	1141                	addi	sp,sp,-16
    80200066:	e022                	sd	s0,0(sp)
    80200068:	e406                	sd	ra,8(sp)
    8020006a:	842e                	mv	s0,a1
    8020006c:	048000ef          	jal	ra,802000b4 <cons_putc>
    80200070:	401c                	lw	a5,0(s0)
    80200072:	60a2                	ld	ra,8(sp)
    80200074:	2785                	addiw	a5,a5,1
    80200076:	c01c                	sw	a5,0(s0)
    80200078:	6402                	ld	s0,0(sp)
    8020007a:	0141                	addi	sp,sp,16
    8020007c:	8082                	ret

000000008020007e <cprintf>:
    8020007e:	711d                	addi	sp,sp,-96
    80200080:	02810313          	addi	t1,sp,40 # 80203028 <edata+0x20>
    80200084:	8e2a                	mv	t3,a0
    80200086:	f42e                	sd	a1,40(sp)
    80200088:	f832                	sd	a2,48(sp)
    8020008a:	fc36                	sd	a3,56(sp)
    8020008c:	00000517          	auipc	a0,0x0
    80200090:	fd850513          	addi	a0,a0,-40 # 80200064 <cputch>
    80200094:	004c                	addi	a1,sp,4
    80200096:	869a                	mv	a3,t1
    80200098:	8672                	mv	a2,t3
    8020009a:	ec06                	sd	ra,24(sp)
    8020009c:	e0ba                	sd	a4,64(sp)
    8020009e:	e4be                	sd	a5,72(sp)
    802000a0:	e8c2                	sd	a6,80(sp)
    802000a2:	ecc6                	sd	a7,88(sp)
    802000a4:	e41a                	sd	t1,8(sp)
    802000a6:	c202                	sw	zero,4(sp)
    802000a8:	0ac000ef          	jal	ra,80200154 <vprintfmt>
    802000ac:	60e2                	ld	ra,24(sp)
    802000ae:	4512                	lw	a0,4(sp)
    802000b0:	6125                	addi	sp,sp,96
    802000b2:	8082                	ret

00000000802000b4 <cons_putc>:
    802000b4:	0ff57513          	zext.b	a0,a0
    802000b8:	a939                	j	802004d6 <sbi_console_putchar>

00000000802000ba <strnlen>:
    802000ba:	4781                	li	a5,0
    802000bc:	e589                	bnez	a1,802000c6 <strnlen+0xc>
    802000be:	a811                	j	802000d2 <strnlen+0x18>
    802000c0:	0785                	addi	a5,a5,1
    802000c2:	00f58863          	beq	a1,a5,802000d2 <strnlen+0x18>
    802000c6:	00f50733          	add	a4,a0,a5
    802000ca:	00074703          	lbu	a4,0(a4)
    802000ce:	fb6d                	bnez	a4,802000c0 <strnlen+0x6>
    802000d0:	85be                	mv	a1,a5
    802000d2:	852e                	mv	a0,a1
    802000d4:	8082                	ret

00000000802000d6 <memset>:
    802000d6:	ca01                	beqz	a2,802000e6 <memset+0x10>
    802000d8:	962a                	add	a2,a2,a0
    802000da:	87aa                	mv	a5,a0
    802000dc:	0785                	addi	a5,a5,1
    802000de:	feb78fa3          	sb	a1,-1(a5)
    802000e2:	fec79de3          	bne	a5,a2,802000dc <memset+0x6>
    802000e6:	8082                	ret

00000000802000e8 <printnum>:
    802000e8:	02069813          	slli	a6,a3,0x20
    802000ec:	7179                	addi	sp,sp,-48
    802000ee:	02085813          	srli	a6,a6,0x20
    802000f2:	e052                	sd	s4,0(sp)
    802000f4:	03067a33          	remu	s4,a2,a6
    802000f8:	f022                	sd	s0,32(sp)
    802000fa:	ec26                	sd	s1,24(sp)
    802000fc:	e84a                	sd	s2,16(sp)
    802000fe:	f406                	sd	ra,40(sp)
    80200100:	e44e                	sd	s3,8(sp)
    80200102:	84aa                	mv	s1,a0
    80200104:	892e                	mv	s2,a1
    80200106:	fff7041b          	addiw	s0,a4,-1
    8020010a:	2a01                	sext.w	s4,s4
    8020010c:	03067e63          	bgeu	a2,a6,80200148 <printnum+0x60>
    80200110:	89be                	mv	s3,a5
    80200112:	00805763          	blez	s0,80200120 <printnum+0x38>
    80200116:	347d                	addiw	s0,s0,-1
    80200118:	85ca                	mv	a1,s2
    8020011a:	854e                	mv	a0,s3
    8020011c:	9482                	jalr	s1
    8020011e:	fc65                	bnez	s0,80200116 <printnum+0x2e>
    80200120:	1a02                	slli	s4,s4,0x20
    80200122:	00000797          	auipc	a5,0x0
    80200126:	3f678793          	addi	a5,a5,1014 # 80200518 <sbi_console_putchar+0x42>
    8020012a:	020a5a13          	srli	s4,s4,0x20
    8020012e:	9a3e                	add	s4,s4,a5
    80200130:	7402                	ld	s0,32(sp)
    80200132:	000a4503          	lbu	a0,0(s4)
    80200136:	70a2                	ld	ra,40(sp)
    80200138:	69a2                	ld	s3,8(sp)
    8020013a:	6a02                	ld	s4,0(sp)
    8020013c:	85ca                	mv	a1,s2
    8020013e:	87a6                	mv	a5,s1
    80200140:	6942                	ld	s2,16(sp)
    80200142:	64e2                	ld	s1,24(sp)
    80200144:	6145                	addi	sp,sp,48
    80200146:	8782                	jr	a5
    80200148:	03065633          	divu	a2,a2,a6
    8020014c:	8722                	mv	a4,s0
    8020014e:	f9bff0ef          	jal	ra,802000e8 <printnum>
    80200152:	b7f9                	j	80200120 <printnum+0x38>

0000000080200154 <vprintfmt>:
    80200154:	7119                	addi	sp,sp,-128
    80200156:	f4a6                	sd	s1,104(sp)
    80200158:	f0ca                	sd	s2,96(sp)
    8020015a:	ecce                	sd	s3,88(sp)
    8020015c:	e8d2                	sd	s4,80(sp)
    8020015e:	e4d6                	sd	s5,72(sp)
    80200160:	e0da                	sd	s6,64(sp)
    80200162:	fc5e                	sd	s7,56(sp)
    80200164:	f06a                	sd	s10,32(sp)
    80200166:	fc86                	sd	ra,120(sp)
    80200168:	f8a2                	sd	s0,112(sp)
    8020016a:	f862                	sd	s8,48(sp)
    8020016c:	f466                	sd	s9,40(sp)
    8020016e:	ec6e                	sd	s11,24(sp)
    80200170:	892a                	mv	s2,a0
    80200172:	84ae                	mv	s1,a1
    80200174:	8d32                	mv	s10,a2
    80200176:	8a36                	mv	s4,a3
    80200178:	02500993          	li	s3,37
    8020017c:	5b7d                	li	s6,-1
    8020017e:	00000a97          	auipc	s5,0x0
    80200182:	3cea8a93          	addi	s5,s5,974 # 8020054c <sbi_console_putchar+0x76>
    80200186:	00000b97          	auipc	s7,0x0
    8020018a:	5a2b8b93          	addi	s7,s7,1442 # 80200728 <error_string>
    8020018e:	000d4503          	lbu	a0,0(s10)
    80200192:	001d0413          	addi	s0,s10,1
    80200196:	01350a63          	beq	a0,s3,802001aa <vprintfmt+0x56>
    8020019a:	c121                	beqz	a0,802001da <vprintfmt+0x86>
    8020019c:	85a6                	mv	a1,s1
    8020019e:	0405                	addi	s0,s0,1
    802001a0:	9902                	jalr	s2
    802001a2:	fff44503          	lbu	a0,-1(s0)
    802001a6:	ff351ae3          	bne	a0,s3,8020019a <vprintfmt+0x46>
    802001aa:	00044603          	lbu	a2,0(s0)
    802001ae:	02000793          	li	a5,32
    802001b2:	4c81                	li	s9,0
    802001b4:	4881                	li	a7,0
    802001b6:	5c7d                	li	s8,-1
    802001b8:	5dfd                	li	s11,-1
    802001ba:	05500513          	li	a0,85
    802001be:	4825                	li	a6,9
    802001c0:	fdd6059b          	addiw	a1,a2,-35
    802001c4:	0ff5f593          	zext.b	a1,a1
    802001c8:	00140d13          	addi	s10,s0,1
    802001cc:	04b56263          	bltu	a0,a1,80200210 <vprintfmt+0xbc>
    802001d0:	058a                	slli	a1,a1,0x2
    802001d2:	95d6                	add	a1,a1,s5
    802001d4:	4194                	lw	a3,0(a1)
    802001d6:	96d6                	add	a3,a3,s5
    802001d8:	8682                	jr	a3
    802001da:	70e6                	ld	ra,120(sp)
    802001dc:	7446                	ld	s0,112(sp)
    802001de:	74a6                	ld	s1,104(sp)
    802001e0:	7906                	ld	s2,96(sp)
    802001e2:	69e6                	ld	s3,88(sp)
    802001e4:	6a46                	ld	s4,80(sp)
    802001e6:	6aa6                	ld	s5,72(sp)
    802001e8:	6b06                	ld	s6,64(sp)
    802001ea:	7be2                	ld	s7,56(sp)
    802001ec:	7c42                	ld	s8,48(sp)
    802001ee:	7ca2                	ld	s9,40(sp)
    802001f0:	7d02                	ld	s10,32(sp)
    802001f2:	6de2                	ld	s11,24(sp)
    802001f4:	6109                	addi	sp,sp,128
    802001f6:	8082                	ret
    802001f8:	87b2                	mv	a5,a2
    802001fa:	00144603          	lbu	a2,1(s0)
    802001fe:	846a                	mv	s0,s10
    80200200:	00140d13          	addi	s10,s0,1
    80200204:	fdd6059b          	addiw	a1,a2,-35
    80200208:	0ff5f593          	zext.b	a1,a1
    8020020c:	fcb572e3          	bgeu	a0,a1,802001d0 <vprintfmt+0x7c>
    80200210:	85a6                	mv	a1,s1
    80200212:	02500513          	li	a0,37
    80200216:	9902                	jalr	s2
    80200218:	fff44783          	lbu	a5,-1(s0)
    8020021c:	8d22                	mv	s10,s0
    8020021e:	f73788e3          	beq	a5,s3,8020018e <vprintfmt+0x3a>
    80200222:	ffed4783          	lbu	a5,-2(s10)
    80200226:	1d7d                	addi	s10,s10,-1
    80200228:	ff379de3          	bne	a5,s3,80200222 <vprintfmt+0xce>
    8020022c:	b78d                	j	8020018e <vprintfmt+0x3a>
    8020022e:	fd060c1b          	addiw	s8,a2,-48
    80200232:	00144603          	lbu	a2,1(s0)
    80200236:	846a                	mv	s0,s10
    80200238:	fd06069b          	addiw	a3,a2,-48
    8020023c:	0006059b          	sext.w	a1,a2
    80200240:	02d86463          	bltu	a6,a3,80200268 <vprintfmt+0x114>
    80200244:	00144603          	lbu	a2,1(s0)
    80200248:	002c169b          	slliw	a3,s8,0x2
    8020024c:	0186873b          	addw	a4,a3,s8
    80200250:	0017171b          	slliw	a4,a4,0x1
    80200254:	9f2d                	addw	a4,a4,a1
    80200256:	fd06069b          	addiw	a3,a2,-48
    8020025a:	0405                	addi	s0,s0,1
    8020025c:	fd070c1b          	addiw	s8,a4,-48
    80200260:	0006059b          	sext.w	a1,a2
    80200264:	fed870e3          	bgeu	a6,a3,80200244 <vprintfmt+0xf0>
    80200268:	f40ddce3          	bgez	s11,802001c0 <vprintfmt+0x6c>
    8020026c:	8de2                	mv	s11,s8
    8020026e:	5c7d                	li	s8,-1
    80200270:	bf81                	j	802001c0 <vprintfmt+0x6c>
    80200272:	fffdc693          	not	a3,s11
    80200276:	96fd                	srai	a3,a3,0x3f
    80200278:	00ddfdb3          	and	s11,s11,a3
    8020027c:	00144603          	lbu	a2,1(s0)
    80200280:	2d81                	sext.w	s11,s11
    80200282:	846a                	mv	s0,s10
    80200284:	bf35                	j	802001c0 <vprintfmt+0x6c>
    80200286:	000a2c03          	lw	s8,0(s4)
    8020028a:	00144603          	lbu	a2,1(s0)
    8020028e:	0a21                	addi	s4,s4,8
    80200290:	846a                	mv	s0,s10
    80200292:	bfd9                	j	80200268 <vprintfmt+0x114>
    80200294:	4705                	li	a4,1
    80200296:	008a0593          	addi	a1,s4,8
    8020029a:	01174463          	blt	a4,a7,802002a2 <vprintfmt+0x14e>
    8020029e:	1a088e63          	beqz	a7,8020045a <vprintfmt+0x306>
    802002a2:	000a3603          	ld	a2,0(s4)
    802002a6:	46c1                	li	a3,16
    802002a8:	8a2e                	mv	s4,a1
    802002aa:	2781                	sext.w	a5,a5
    802002ac:	876e                	mv	a4,s11
    802002ae:	85a6                	mv	a1,s1
    802002b0:	854a                	mv	a0,s2
    802002b2:	e37ff0ef          	jal	ra,802000e8 <printnum>
    802002b6:	bde1                	j	8020018e <vprintfmt+0x3a>
    802002b8:	000a2503          	lw	a0,0(s4)
    802002bc:	85a6                	mv	a1,s1
    802002be:	0a21                	addi	s4,s4,8
    802002c0:	9902                	jalr	s2
    802002c2:	b5f1                	j	8020018e <vprintfmt+0x3a>
    802002c4:	4705                	li	a4,1
    802002c6:	008a0593          	addi	a1,s4,8
    802002ca:	01174463          	blt	a4,a7,802002d2 <vprintfmt+0x17e>
    802002ce:	18088163          	beqz	a7,80200450 <vprintfmt+0x2fc>
    802002d2:	000a3603          	ld	a2,0(s4)
    802002d6:	46a9                	li	a3,10
    802002d8:	8a2e                	mv	s4,a1
    802002da:	bfc1                	j	802002aa <vprintfmt+0x156>
    802002dc:	00144603          	lbu	a2,1(s0)
    802002e0:	4c85                	li	s9,1
    802002e2:	846a                	mv	s0,s10
    802002e4:	bdf1                	j	802001c0 <vprintfmt+0x6c>
    802002e6:	85a6                	mv	a1,s1
    802002e8:	02500513          	li	a0,37
    802002ec:	9902                	jalr	s2
    802002ee:	b545                	j	8020018e <vprintfmt+0x3a>
    802002f0:	00144603          	lbu	a2,1(s0)
    802002f4:	2885                	addiw	a7,a7,1
    802002f6:	846a                	mv	s0,s10
    802002f8:	b5e1                	j	802001c0 <vprintfmt+0x6c>
    802002fa:	4705                	li	a4,1
    802002fc:	008a0593          	addi	a1,s4,8
    80200300:	01174463          	blt	a4,a7,80200308 <vprintfmt+0x1b4>
    80200304:	14088163          	beqz	a7,80200446 <vprintfmt+0x2f2>
    80200308:	000a3603          	ld	a2,0(s4)
    8020030c:	46a1                	li	a3,8
    8020030e:	8a2e                	mv	s4,a1
    80200310:	bf69                	j	802002aa <vprintfmt+0x156>
    80200312:	03000513          	li	a0,48
    80200316:	85a6                	mv	a1,s1
    80200318:	e03e                	sd	a5,0(sp)
    8020031a:	9902                	jalr	s2
    8020031c:	85a6                	mv	a1,s1
    8020031e:	07800513          	li	a0,120
    80200322:	9902                	jalr	s2
    80200324:	0a21                	addi	s4,s4,8
    80200326:	6782                	ld	a5,0(sp)
    80200328:	46c1                	li	a3,16
    8020032a:	ff8a3603          	ld	a2,-8(s4)
    8020032e:	bfb5                	j	802002aa <vprintfmt+0x156>
    80200330:	000a3403          	ld	s0,0(s4)
    80200334:	008a0713          	addi	a4,s4,8
    80200338:	e03a                	sd	a4,0(sp)
    8020033a:	14040263          	beqz	s0,8020047e <vprintfmt+0x32a>
    8020033e:	0fb05763          	blez	s11,8020042c <vprintfmt+0x2d8>
    80200342:	02d00693          	li	a3,45
    80200346:	0cd79163          	bne	a5,a3,80200408 <vprintfmt+0x2b4>
    8020034a:	00044783          	lbu	a5,0(s0)
    8020034e:	0007851b          	sext.w	a0,a5
    80200352:	cf85                	beqz	a5,8020038a <vprintfmt+0x236>
    80200354:	00140a13          	addi	s4,s0,1
    80200358:	05e00413          	li	s0,94
    8020035c:	000c4563          	bltz	s8,80200366 <vprintfmt+0x212>
    80200360:	3c7d                	addiw	s8,s8,-1
    80200362:	036c0263          	beq	s8,s6,80200386 <vprintfmt+0x232>
    80200366:	85a6                	mv	a1,s1
    80200368:	0e0c8e63          	beqz	s9,80200464 <vprintfmt+0x310>
    8020036c:	3781                	addiw	a5,a5,-32
    8020036e:	0ef47b63          	bgeu	s0,a5,80200464 <vprintfmt+0x310>
    80200372:	03f00513          	li	a0,63
    80200376:	9902                	jalr	s2
    80200378:	000a4783          	lbu	a5,0(s4)
    8020037c:	3dfd                	addiw	s11,s11,-1
    8020037e:	0a05                	addi	s4,s4,1
    80200380:	0007851b          	sext.w	a0,a5
    80200384:	ffe1                	bnez	a5,8020035c <vprintfmt+0x208>
    80200386:	01b05963          	blez	s11,80200398 <vprintfmt+0x244>
    8020038a:	3dfd                	addiw	s11,s11,-1
    8020038c:	85a6                	mv	a1,s1
    8020038e:	02000513          	li	a0,32
    80200392:	9902                	jalr	s2
    80200394:	fe0d9be3          	bnez	s11,8020038a <vprintfmt+0x236>
    80200398:	6a02                	ld	s4,0(sp)
    8020039a:	bbd5                	j	8020018e <vprintfmt+0x3a>
    8020039c:	4705                	li	a4,1
    8020039e:	008a0c93          	addi	s9,s4,8
    802003a2:	01174463          	blt	a4,a7,802003aa <vprintfmt+0x256>
    802003a6:	08088d63          	beqz	a7,80200440 <vprintfmt+0x2ec>
    802003aa:	000a3403          	ld	s0,0(s4)
    802003ae:	0a044d63          	bltz	s0,80200468 <vprintfmt+0x314>
    802003b2:	8622                	mv	a2,s0
    802003b4:	8a66                	mv	s4,s9
    802003b6:	46a9                	li	a3,10
    802003b8:	bdcd                	j	802002aa <vprintfmt+0x156>
    802003ba:	000a2783          	lw	a5,0(s4)
    802003be:	4719                	li	a4,6
    802003c0:	0a21                	addi	s4,s4,8
    802003c2:	41f7d69b          	sraiw	a3,a5,0x1f
    802003c6:	8fb5                	xor	a5,a5,a3
    802003c8:	40d786bb          	subw	a3,a5,a3
    802003cc:	02d74163          	blt	a4,a3,802003ee <vprintfmt+0x29a>
    802003d0:	00369793          	slli	a5,a3,0x3
    802003d4:	97de                	add	a5,a5,s7
    802003d6:	639c                	ld	a5,0(a5)
    802003d8:	cb99                	beqz	a5,802003ee <vprintfmt+0x29a>
    802003da:	86be                	mv	a3,a5
    802003dc:	00000617          	auipc	a2,0x0
    802003e0:	16c60613          	addi	a2,a2,364 # 80200548 <sbi_console_putchar+0x72>
    802003e4:	85a6                	mv	a1,s1
    802003e6:	854a                	mv	a0,s2
    802003e8:	0ce000ef          	jal	ra,802004b6 <printfmt>
    802003ec:	b34d                	j	8020018e <vprintfmt+0x3a>
    802003ee:	00000617          	auipc	a2,0x0
    802003f2:	14a60613          	addi	a2,a2,330 # 80200538 <sbi_console_putchar+0x62>
    802003f6:	85a6                	mv	a1,s1
    802003f8:	854a                	mv	a0,s2
    802003fa:	0bc000ef          	jal	ra,802004b6 <printfmt>
    802003fe:	bb41                	j	8020018e <vprintfmt+0x3a>
    80200400:	00000417          	auipc	s0,0x0
    80200404:	13040413          	addi	s0,s0,304 # 80200530 <sbi_console_putchar+0x5a>
    80200408:	85e2                	mv	a1,s8
    8020040a:	8522                	mv	a0,s0
    8020040c:	e43e                	sd	a5,8(sp)
    8020040e:	cadff0ef          	jal	ra,802000ba <strnlen>
    80200412:	40ad8dbb          	subw	s11,s11,a0
    80200416:	01b05b63          	blez	s11,8020042c <vprintfmt+0x2d8>
    8020041a:	67a2                	ld	a5,8(sp)
    8020041c:	00078a1b          	sext.w	s4,a5
    80200420:	3dfd                	addiw	s11,s11,-1
    80200422:	85a6                	mv	a1,s1
    80200424:	8552                	mv	a0,s4
    80200426:	9902                	jalr	s2
    80200428:	fe0d9ce3          	bnez	s11,80200420 <vprintfmt+0x2cc>
    8020042c:	00044783          	lbu	a5,0(s0)
    80200430:	00140a13          	addi	s4,s0,1
    80200434:	0007851b          	sext.w	a0,a5
    80200438:	d3a5                	beqz	a5,80200398 <vprintfmt+0x244>
    8020043a:	05e00413          	li	s0,94
    8020043e:	bf39                	j	8020035c <vprintfmt+0x208>
    80200440:	000a2403          	lw	s0,0(s4)
    80200444:	b7ad                	j	802003ae <vprintfmt+0x25a>
    80200446:	000a6603          	lwu	a2,0(s4)
    8020044a:	46a1                	li	a3,8
    8020044c:	8a2e                	mv	s4,a1
    8020044e:	bdb1                	j	802002aa <vprintfmt+0x156>
    80200450:	000a6603          	lwu	a2,0(s4)
    80200454:	46a9                	li	a3,10
    80200456:	8a2e                	mv	s4,a1
    80200458:	bd89                	j	802002aa <vprintfmt+0x156>
    8020045a:	000a6603          	lwu	a2,0(s4)
    8020045e:	46c1                	li	a3,16
    80200460:	8a2e                	mv	s4,a1
    80200462:	b5a1                	j	802002aa <vprintfmt+0x156>
    80200464:	9902                	jalr	s2
    80200466:	bf09                	j	80200378 <vprintfmt+0x224>
    80200468:	85a6                	mv	a1,s1
    8020046a:	02d00513          	li	a0,45
    8020046e:	e03e                	sd	a5,0(sp)
    80200470:	9902                	jalr	s2
    80200472:	6782                	ld	a5,0(sp)
    80200474:	8a66                	mv	s4,s9
    80200476:	40800633          	neg	a2,s0
    8020047a:	46a9                	li	a3,10
    8020047c:	b53d                	j	802002aa <vprintfmt+0x156>
    8020047e:	03b05163          	blez	s11,802004a0 <vprintfmt+0x34c>
    80200482:	02d00693          	li	a3,45
    80200486:	f6d79de3          	bne	a5,a3,80200400 <vprintfmt+0x2ac>
    8020048a:	00000417          	auipc	s0,0x0
    8020048e:	0a640413          	addi	s0,s0,166 # 80200530 <sbi_console_putchar+0x5a>
    80200492:	02800793          	li	a5,40
    80200496:	02800513          	li	a0,40
    8020049a:	00140a13          	addi	s4,s0,1
    8020049e:	bd6d                	j	80200358 <vprintfmt+0x204>
    802004a0:	00000a17          	auipc	s4,0x0
    802004a4:	091a0a13          	addi	s4,s4,145 # 80200531 <sbi_console_putchar+0x5b>
    802004a8:	02800513          	li	a0,40
    802004ac:	02800793          	li	a5,40
    802004b0:	05e00413          	li	s0,94
    802004b4:	b565                	j	8020035c <vprintfmt+0x208>

00000000802004b6 <printfmt>:
    802004b6:	715d                	addi	sp,sp,-80
    802004b8:	02810313          	addi	t1,sp,40
    802004bc:	f436                	sd	a3,40(sp)
    802004be:	869a                	mv	a3,t1
    802004c0:	ec06                	sd	ra,24(sp)
    802004c2:	f83a                	sd	a4,48(sp)
    802004c4:	fc3e                	sd	a5,56(sp)
    802004c6:	e0c2                	sd	a6,64(sp)
    802004c8:	e4c6                	sd	a7,72(sp)
    802004ca:	e41a                	sd	t1,8(sp)
    802004cc:	c89ff0ef          	jal	ra,80200154 <vprintfmt>
    802004d0:	60e2                	ld	ra,24(sp)
    802004d2:	6161                	addi	sp,sp,80
    802004d4:	8082                	ret

00000000802004d6 <sbi_console_putchar>:
    802004d6:	4781                	li	a5,0
    802004d8:	00003717          	auipc	a4,0x3
    802004dc:	b2873703          	ld	a4,-1240(a4) # 80203000 <SBI_CONSOLE_PUTCHAR>
    802004e0:	88ba                	mv	a7,a4
    802004e2:	852a                	mv	a0,a0
    802004e4:	85be                	mv	a1,a5
    802004e6:	863e                	mv	a2,a5
    802004e8:	00000073          	ecall
    802004ec:	87aa                	mv	a5,a0
    802004ee:	8082                	ret
