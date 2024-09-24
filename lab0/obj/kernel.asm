
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
    80200022:	4bc000ef          	jal	ra,802004de <memset>
    80200026:	00000597          	auipc	a1,0x0
    8020002a:	4ca58593          	addi	a1,a1,1226 # 802004f0 <memset+0x12>
    8020002e:	00000517          	auipc	a0,0x0
    80200032:	4e250513          	addi	a0,a0,1250 # 80200510 <memset+0x32>
    80200036:	048000ef          	jal	ra,8020007e <cprintf>
    8020003a:	00000597          	auipc	a1,0x0
    8020003e:	4b658593          	addi	a1,a1,1206 # 802004f0 <memset+0x12>
    80200042:	00000517          	auipc	a0,0x0
    80200046:	4ce50513          	addi	a0,a0,1230 # 80200510 <memset+0x32>
    8020004a:	034000ef          	jal	ra,8020007e <cprintf>
    8020004e:	00000597          	auipc	a1,0x0
    80200052:	4a258593          	addi	a1,a1,1186 # 802004f0 <memset+0x12>
    80200056:	00000517          	auipc	a0,0x0
    8020005a:	4ba50513          	addi	a0,a0,1210 # 80200510 <memset+0x32>
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
    802000a8:	07e000ef          	jal	ra,80200126 <vprintfmt>
    802000ac:	60e2                	ld	ra,24(sp)
    802000ae:	4512                	lw	a0,4(sp)
    802000b0:	6125                	addi	sp,sp,96
    802000b2:	8082                	ret

00000000802000b4 <cons_putc>:
    802000b4:	0ff57513          	andi	a0,a0,255
    802000b8:	aec5                	j	802004a8 <sbi_console_putchar>

00000000802000ba <printnum>:
    802000ba:	02069813          	slli	a6,a3,0x20
    802000be:	7179                	addi	sp,sp,-48
    802000c0:	02085813          	srli	a6,a6,0x20
    802000c4:	e052                	sd	s4,0(sp)
    802000c6:	03067a33          	remu	s4,a2,a6
    802000ca:	f022                	sd	s0,32(sp)
    802000cc:	ec26                	sd	s1,24(sp)
    802000ce:	e84a                	sd	s2,16(sp)
    802000d0:	f406                	sd	ra,40(sp)
    802000d2:	e44e                	sd	s3,8(sp)
    802000d4:	84aa                	mv	s1,a0
    802000d6:	892e                	mv	s2,a1
    802000d8:	fff7041b          	addiw	s0,a4,-1
    802000dc:	2a01                	sext.w	s4,s4
    802000de:	03067e63          	bgeu	a2,a6,8020011a <printnum+0x60>
    802000e2:	89be                	mv	s3,a5
    802000e4:	00805763          	blez	s0,802000f2 <printnum+0x38>
    802000e8:	347d                	addiw	s0,s0,-1
    802000ea:	85ca                	mv	a1,s2
    802000ec:	854e                	mv	a0,s3
    802000ee:	9482                	jalr	s1
    802000f0:	fc65                	bnez	s0,802000e8 <printnum+0x2e>
    802000f2:	1a02                	slli	s4,s4,0x20
    802000f4:	00000797          	auipc	a5,0x0
    802000f8:	42478793          	addi	a5,a5,1060 # 80200518 <memset+0x3a>
    802000fc:	020a5a13          	srli	s4,s4,0x20
    80200100:	9a3e                	add	s4,s4,a5
    80200102:	7402                	ld	s0,32(sp)
    80200104:	000a4503          	lbu	a0,0(s4)
    80200108:	70a2                	ld	ra,40(sp)
    8020010a:	69a2                	ld	s3,8(sp)
    8020010c:	6a02                	ld	s4,0(sp)
    8020010e:	85ca                	mv	a1,s2
    80200110:	87a6                	mv	a5,s1
    80200112:	6942                	ld	s2,16(sp)
    80200114:	64e2                	ld	s1,24(sp)
    80200116:	6145                	addi	sp,sp,48
    80200118:	8782                	jr	a5
    8020011a:	03065633          	divu	a2,a2,a6
    8020011e:	8722                	mv	a4,s0
    80200120:	f9bff0ef          	jal	ra,802000ba <printnum>
    80200124:	b7f9                	j	802000f2 <printnum+0x38>

0000000080200126 <vprintfmt>:
    80200126:	7119                	addi	sp,sp,-128
    80200128:	f4a6                	sd	s1,104(sp)
    8020012a:	f0ca                	sd	s2,96(sp)
    8020012c:	ecce                	sd	s3,88(sp)
    8020012e:	e8d2                	sd	s4,80(sp)
    80200130:	e4d6                	sd	s5,72(sp)
    80200132:	e0da                	sd	s6,64(sp)
    80200134:	fc5e                	sd	s7,56(sp)
    80200136:	f06a                	sd	s10,32(sp)
    80200138:	fc86                	sd	ra,120(sp)
    8020013a:	f8a2                	sd	s0,112(sp)
    8020013c:	f862                	sd	s8,48(sp)
    8020013e:	f466                	sd	s9,40(sp)
    80200140:	ec6e                	sd	s11,24(sp)
    80200142:	892a                	mv	s2,a0
    80200144:	84ae                	mv	s1,a1
    80200146:	8d32                	mv	s10,a2
    80200148:	8a36                	mv	s4,a3
    8020014a:	02500993          	li	s3,37
    8020014e:	5b7d                	li	s6,-1
    80200150:	00000a97          	auipc	s5,0x0
    80200154:	3fca8a93          	addi	s5,s5,1020 # 8020054c <memset+0x6e>
    80200158:	00000b97          	auipc	s7,0x0
    8020015c:	5d0b8b93          	addi	s7,s7,1488 # 80200728 <error_string>
    80200160:	000d4503          	lbu	a0,0(s10)
    80200164:	001d0413          	addi	s0,s10,1
    80200168:	01350a63          	beq	a0,s3,8020017c <vprintfmt+0x56>
    8020016c:	c121                	beqz	a0,802001ac <vprintfmt+0x86>
    8020016e:	85a6                	mv	a1,s1
    80200170:	0405                	addi	s0,s0,1
    80200172:	9902                	jalr	s2
    80200174:	fff44503          	lbu	a0,-1(s0)
    80200178:	ff351ae3          	bne	a0,s3,8020016c <vprintfmt+0x46>
    8020017c:	00044603          	lbu	a2,0(s0)
    80200180:	02000793          	li	a5,32
    80200184:	4c81                	li	s9,0
    80200186:	4881                	li	a7,0
    80200188:	5c7d                	li	s8,-1
    8020018a:	5dfd                	li	s11,-1
    8020018c:	05500513          	li	a0,85
    80200190:	4825                	li	a6,9
    80200192:	fdd6059b          	addiw	a1,a2,-35
    80200196:	0ff5f593          	andi	a1,a1,255
    8020019a:	00140d13          	addi	s10,s0,1
    8020019e:	04b56263          	bltu	a0,a1,802001e2 <vprintfmt+0xbc>
    802001a2:	058a                	slli	a1,a1,0x2
    802001a4:	95d6                	add	a1,a1,s5
    802001a6:	4194                	lw	a3,0(a1)
    802001a8:	96d6                	add	a3,a3,s5
    802001aa:	8682                	jr	a3
    802001ac:	70e6                	ld	ra,120(sp)
    802001ae:	7446                	ld	s0,112(sp)
    802001b0:	74a6                	ld	s1,104(sp)
    802001b2:	7906                	ld	s2,96(sp)
    802001b4:	69e6                	ld	s3,88(sp)
    802001b6:	6a46                	ld	s4,80(sp)
    802001b8:	6aa6                	ld	s5,72(sp)
    802001ba:	6b06                	ld	s6,64(sp)
    802001bc:	7be2                	ld	s7,56(sp)
    802001be:	7c42                	ld	s8,48(sp)
    802001c0:	7ca2                	ld	s9,40(sp)
    802001c2:	7d02                	ld	s10,32(sp)
    802001c4:	6de2                	ld	s11,24(sp)
    802001c6:	6109                	addi	sp,sp,128
    802001c8:	8082                	ret
    802001ca:	87b2                	mv	a5,a2
    802001cc:	00144603          	lbu	a2,1(s0)
    802001d0:	846a                	mv	s0,s10
    802001d2:	00140d13          	addi	s10,s0,1
    802001d6:	fdd6059b          	addiw	a1,a2,-35
    802001da:	0ff5f593          	andi	a1,a1,255
    802001de:	fcb572e3          	bgeu	a0,a1,802001a2 <vprintfmt+0x7c>
    802001e2:	85a6                	mv	a1,s1
    802001e4:	02500513          	li	a0,37
    802001e8:	9902                	jalr	s2
    802001ea:	fff44783          	lbu	a5,-1(s0)
    802001ee:	8d22                	mv	s10,s0
    802001f0:	f73788e3          	beq	a5,s3,80200160 <vprintfmt+0x3a>
    802001f4:	ffed4783          	lbu	a5,-2(s10)
    802001f8:	1d7d                	addi	s10,s10,-1
    802001fa:	ff379de3          	bne	a5,s3,802001f4 <vprintfmt+0xce>
    802001fe:	b78d                	j	80200160 <vprintfmt+0x3a>
    80200200:	fd060c1b          	addiw	s8,a2,-48
    80200204:	00144603          	lbu	a2,1(s0)
    80200208:	846a                	mv	s0,s10
    8020020a:	fd06069b          	addiw	a3,a2,-48
    8020020e:	0006059b          	sext.w	a1,a2
    80200212:	02d86463          	bltu	a6,a3,8020023a <vprintfmt+0x114>
    80200216:	00144603          	lbu	a2,1(s0)
    8020021a:	002c169b          	slliw	a3,s8,0x2
    8020021e:	0186873b          	addw	a4,a3,s8
    80200222:	0017171b          	slliw	a4,a4,0x1
    80200226:	9f2d                	addw	a4,a4,a1
    80200228:	fd06069b          	addiw	a3,a2,-48
    8020022c:	0405                	addi	s0,s0,1
    8020022e:	fd070c1b          	addiw	s8,a4,-48
    80200232:	0006059b          	sext.w	a1,a2
    80200236:	fed870e3          	bgeu	a6,a3,80200216 <vprintfmt+0xf0>
    8020023a:	f40ddce3          	bgez	s11,80200192 <vprintfmt+0x6c>
    8020023e:	8de2                	mv	s11,s8
    80200240:	5c7d                	li	s8,-1
    80200242:	bf81                	j	80200192 <vprintfmt+0x6c>
    80200244:	fffdc693          	not	a3,s11
    80200248:	96fd                	srai	a3,a3,0x3f
    8020024a:	00ddfdb3          	and	s11,s11,a3
    8020024e:	00144603          	lbu	a2,1(s0)
    80200252:	2d81                	sext.w	s11,s11
    80200254:	846a                	mv	s0,s10
    80200256:	bf35                	j	80200192 <vprintfmt+0x6c>
    80200258:	000a2c03          	lw	s8,0(s4)
    8020025c:	00144603          	lbu	a2,1(s0)
    80200260:	0a21                	addi	s4,s4,8
    80200262:	846a                	mv	s0,s10
    80200264:	bfd9                	j	8020023a <vprintfmt+0x114>
    80200266:	4705                	li	a4,1
    80200268:	008a0593          	addi	a1,s4,8
    8020026c:	01174463          	blt	a4,a7,80200274 <vprintfmt+0x14e>
    80200270:	1a088e63          	beqz	a7,8020042c <vprintfmt+0x306>
    80200274:	000a3603          	ld	a2,0(s4)
    80200278:	46c1                	li	a3,16
    8020027a:	8a2e                	mv	s4,a1
    8020027c:	2781                	sext.w	a5,a5
    8020027e:	876e                	mv	a4,s11
    80200280:	85a6                	mv	a1,s1
    80200282:	854a                	mv	a0,s2
    80200284:	e37ff0ef          	jal	ra,802000ba <printnum>
    80200288:	bde1                	j	80200160 <vprintfmt+0x3a>
    8020028a:	000a2503          	lw	a0,0(s4)
    8020028e:	85a6                	mv	a1,s1
    80200290:	0a21                	addi	s4,s4,8
    80200292:	9902                	jalr	s2
    80200294:	b5f1                	j	80200160 <vprintfmt+0x3a>
    80200296:	4705                	li	a4,1
    80200298:	008a0593          	addi	a1,s4,8
    8020029c:	01174463          	blt	a4,a7,802002a4 <vprintfmt+0x17e>
    802002a0:	18088163          	beqz	a7,80200422 <vprintfmt+0x2fc>
    802002a4:	000a3603          	ld	a2,0(s4)
    802002a8:	46a9                	li	a3,10
    802002aa:	8a2e                	mv	s4,a1
    802002ac:	bfc1                	j	8020027c <vprintfmt+0x156>
    802002ae:	00144603          	lbu	a2,1(s0)
    802002b2:	4c85                	li	s9,1
    802002b4:	846a                	mv	s0,s10
    802002b6:	bdf1                	j	80200192 <vprintfmt+0x6c>
    802002b8:	85a6                	mv	a1,s1
    802002ba:	02500513          	li	a0,37
    802002be:	9902                	jalr	s2
    802002c0:	b545                	j	80200160 <vprintfmt+0x3a>
    802002c2:	00144603          	lbu	a2,1(s0)
    802002c6:	2885                	addiw	a7,a7,1
    802002c8:	846a                	mv	s0,s10
    802002ca:	b5e1                	j	80200192 <vprintfmt+0x6c>
    802002cc:	4705                	li	a4,1
    802002ce:	008a0593          	addi	a1,s4,8
    802002d2:	01174463          	blt	a4,a7,802002da <vprintfmt+0x1b4>
    802002d6:	14088163          	beqz	a7,80200418 <vprintfmt+0x2f2>
    802002da:	000a3603          	ld	a2,0(s4)
    802002de:	46a1                	li	a3,8
    802002e0:	8a2e                	mv	s4,a1
    802002e2:	bf69                	j	8020027c <vprintfmt+0x156>
    802002e4:	03000513          	li	a0,48
    802002e8:	85a6                	mv	a1,s1
    802002ea:	e03e                	sd	a5,0(sp)
    802002ec:	9902                	jalr	s2
    802002ee:	85a6                	mv	a1,s1
    802002f0:	07800513          	li	a0,120
    802002f4:	9902                	jalr	s2
    802002f6:	0a21                	addi	s4,s4,8
    802002f8:	6782                	ld	a5,0(sp)
    802002fa:	46c1                	li	a3,16
    802002fc:	ff8a3603          	ld	a2,-8(s4)
    80200300:	bfb5                	j	8020027c <vprintfmt+0x156>
    80200302:	000a3403          	ld	s0,0(s4)
    80200306:	008a0713          	addi	a4,s4,8
    8020030a:	e03a                	sd	a4,0(sp)
    8020030c:	14040263          	beqz	s0,80200450 <vprintfmt+0x32a>
    80200310:	0fb05763          	blez	s11,802003fe <vprintfmt+0x2d8>
    80200314:	02d00693          	li	a3,45
    80200318:	0cd79163          	bne	a5,a3,802003da <vprintfmt+0x2b4>
    8020031c:	00044783          	lbu	a5,0(s0)
    80200320:	0007851b          	sext.w	a0,a5
    80200324:	cf85                	beqz	a5,8020035c <vprintfmt+0x236>
    80200326:	00140a13          	addi	s4,s0,1
    8020032a:	05e00413          	li	s0,94
    8020032e:	000c4563          	bltz	s8,80200338 <vprintfmt+0x212>
    80200332:	3c7d                	addiw	s8,s8,-1
    80200334:	036c0263          	beq	s8,s6,80200358 <vprintfmt+0x232>
    80200338:	85a6                	mv	a1,s1
    8020033a:	0e0c8e63          	beqz	s9,80200436 <vprintfmt+0x310>
    8020033e:	3781                	addiw	a5,a5,-32
    80200340:	0ef47b63          	bgeu	s0,a5,80200436 <vprintfmt+0x310>
    80200344:	03f00513          	li	a0,63
    80200348:	9902                	jalr	s2
    8020034a:	000a4783          	lbu	a5,0(s4)
    8020034e:	3dfd                	addiw	s11,s11,-1
    80200350:	0a05                	addi	s4,s4,1
    80200352:	0007851b          	sext.w	a0,a5
    80200356:	ffe1                	bnez	a5,8020032e <vprintfmt+0x208>
    80200358:	01b05963          	blez	s11,8020036a <vprintfmt+0x244>
    8020035c:	3dfd                	addiw	s11,s11,-1
    8020035e:	85a6                	mv	a1,s1
    80200360:	02000513          	li	a0,32
    80200364:	9902                	jalr	s2
    80200366:	fe0d9be3          	bnez	s11,8020035c <vprintfmt+0x236>
    8020036a:	6a02                	ld	s4,0(sp)
    8020036c:	bbd5                	j	80200160 <vprintfmt+0x3a>
    8020036e:	4705                	li	a4,1
    80200370:	008a0c93          	addi	s9,s4,8
    80200374:	01174463          	blt	a4,a7,8020037c <vprintfmt+0x256>
    80200378:	08088d63          	beqz	a7,80200412 <vprintfmt+0x2ec>
    8020037c:	000a3403          	ld	s0,0(s4)
    80200380:	0a044d63          	bltz	s0,8020043a <vprintfmt+0x314>
    80200384:	8622                	mv	a2,s0
    80200386:	8a66                	mv	s4,s9
    80200388:	46a9                	li	a3,10
    8020038a:	bdcd                	j	8020027c <vprintfmt+0x156>
    8020038c:	000a2783          	lw	a5,0(s4)
    80200390:	4719                	li	a4,6
    80200392:	0a21                	addi	s4,s4,8
    80200394:	41f7d69b          	sraiw	a3,a5,0x1f
    80200398:	8fb5                	xor	a5,a5,a3
    8020039a:	40d786bb          	subw	a3,a5,a3
    8020039e:	02d74163          	blt	a4,a3,802003c0 <vprintfmt+0x29a>
    802003a2:	00369793          	slli	a5,a3,0x3
    802003a6:	97de                	add	a5,a5,s7
    802003a8:	639c                	ld	a5,0(a5)
    802003aa:	cb99                	beqz	a5,802003c0 <vprintfmt+0x29a>
    802003ac:	86be                	mv	a3,a5
    802003ae:	00000617          	auipc	a2,0x0
    802003b2:	19a60613          	addi	a2,a2,410 # 80200548 <memset+0x6a>
    802003b6:	85a6                	mv	a1,s1
    802003b8:	854a                	mv	a0,s2
    802003ba:	0ce000ef          	jal	ra,80200488 <printfmt>
    802003be:	b34d                	j	80200160 <vprintfmt+0x3a>
    802003c0:	00000617          	auipc	a2,0x0
    802003c4:	17860613          	addi	a2,a2,376 # 80200538 <memset+0x5a>
    802003c8:	85a6                	mv	a1,s1
    802003ca:	854a                	mv	a0,s2
    802003cc:	0bc000ef          	jal	ra,80200488 <printfmt>
    802003d0:	bb41                	j	80200160 <vprintfmt+0x3a>
    802003d2:	00000417          	auipc	s0,0x0
    802003d6:	15e40413          	addi	s0,s0,350 # 80200530 <memset+0x52>
    802003da:	85e2                	mv	a1,s8
    802003dc:	8522                	mv	a0,s0
    802003de:	e43e                	sd	a5,8(sp)
    802003e0:	0e2000ef          	jal	ra,802004c2 <strnlen>
    802003e4:	40ad8dbb          	subw	s11,s11,a0
    802003e8:	01b05b63          	blez	s11,802003fe <vprintfmt+0x2d8>
    802003ec:	67a2                	ld	a5,8(sp)
    802003ee:	00078a1b          	sext.w	s4,a5
    802003f2:	3dfd                	addiw	s11,s11,-1
    802003f4:	85a6                	mv	a1,s1
    802003f6:	8552                	mv	a0,s4
    802003f8:	9902                	jalr	s2
    802003fa:	fe0d9ce3          	bnez	s11,802003f2 <vprintfmt+0x2cc>
    802003fe:	00044783          	lbu	a5,0(s0)
    80200402:	00140a13          	addi	s4,s0,1
    80200406:	0007851b          	sext.w	a0,a5
    8020040a:	d3a5                	beqz	a5,8020036a <vprintfmt+0x244>
    8020040c:	05e00413          	li	s0,94
    80200410:	bf39                	j	8020032e <vprintfmt+0x208>
    80200412:	000a2403          	lw	s0,0(s4)
    80200416:	b7ad                	j	80200380 <vprintfmt+0x25a>
    80200418:	000a6603          	lwu	a2,0(s4)
    8020041c:	46a1                	li	a3,8
    8020041e:	8a2e                	mv	s4,a1
    80200420:	bdb1                	j	8020027c <vprintfmt+0x156>
    80200422:	000a6603          	lwu	a2,0(s4)
    80200426:	46a9                	li	a3,10
    80200428:	8a2e                	mv	s4,a1
    8020042a:	bd89                	j	8020027c <vprintfmt+0x156>
    8020042c:	000a6603          	lwu	a2,0(s4)
    80200430:	46c1                	li	a3,16
    80200432:	8a2e                	mv	s4,a1
    80200434:	b5a1                	j	8020027c <vprintfmt+0x156>
    80200436:	9902                	jalr	s2
    80200438:	bf09                	j	8020034a <vprintfmt+0x224>
    8020043a:	85a6                	mv	a1,s1
    8020043c:	02d00513          	li	a0,45
    80200440:	e03e                	sd	a5,0(sp)
    80200442:	9902                	jalr	s2
    80200444:	6782                	ld	a5,0(sp)
    80200446:	8a66                	mv	s4,s9
    80200448:	40800633          	neg	a2,s0
    8020044c:	46a9                	li	a3,10
    8020044e:	b53d                	j	8020027c <vprintfmt+0x156>
    80200450:	03b05163          	blez	s11,80200472 <vprintfmt+0x34c>
    80200454:	02d00693          	li	a3,45
    80200458:	f6d79de3          	bne	a5,a3,802003d2 <vprintfmt+0x2ac>
    8020045c:	00000417          	auipc	s0,0x0
    80200460:	0d440413          	addi	s0,s0,212 # 80200530 <memset+0x52>
    80200464:	02800793          	li	a5,40
    80200468:	02800513          	li	a0,40
    8020046c:	00140a13          	addi	s4,s0,1
    80200470:	bd6d                	j	8020032a <vprintfmt+0x204>
    80200472:	00000a17          	auipc	s4,0x0
    80200476:	0bfa0a13          	addi	s4,s4,191 # 80200531 <memset+0x53>
    8020047a:	02800513          	li	a0,40
    8020047e:	02800793          	li	a5,40
    80200482:	05e00413          	li	s0,94
    80200486:	b565                	j	8020032e <vprintfmt+0x208>

0000000080200488 <printfmt>:
    80200488:	715d                	addi	sp,sp,-80
    8020048a:	02810313          	addi	t1,sp,40
    8020048e:	f436                	sd	a3,40(sp)
    80200490:	869a                	mv	a3,t1
    80200492:	ec06                	sd	ra,24(sp)
    80200494:	f83a                	sd	a4,48(sp)
    80200496:	fc3e                	sd	a5,56(sp)
    80200498:	e0c2                	sd	a6,64(sp)
    8020049a:	e4c6                	sd	a7,72(sp)
    8020049c:	e41a                	sd	t1,8(sp)
    8020049e:	c89ff0ef          	jal	ra,80200126 <vprintfmt>
    802004a2:	60e2                	ld	ra,24(sp)
    802004a4:	6161                	addi	sp,sp,80
    802004a6:	8082                	ret

00000000802004a8 <sbi_console_putchar>:
    802004a8:	4781                	li	a5,0
    802004aa:	00003717          	auipc	a4,0x3
    802004ae:	b5673703          	ld	a4,-1194(a4) # 80203000 <SBI_CONSOLE_PUTCHAR>
    802004b2:	88ba                	mv	a7,a4
    802004b4:	852a                	mv	a0,a0
    802004b6:	85be                	mv	a1,a5
    802004b8:	863e                	mv	a2,a5
    802004ba:	00000073          	ecall
    802004be:	87aa                	mv	a5,a0
    802004c0:	8082                	ret

00000000802004c2 <strnlen>:
    802004c2:	4781                	li	a5,0
    802004c4:	e589                	bnez	a1,802004ce <strnlen+0xc>
    802004c6:	a811                	j	802004da <strnlen+0x18>
    802004c8:	0785                	addi	a5,a5,1
    802004ca:	00f58863          	beq	a1,a5,802004da <strnlen+0x18>
    802004ce:	00f50733          	add	a4,a0,a5
    802004d2:	00074703          	lbu	a4,0(a4)
    802004d6:	fb6d                	bnez	a4,802004c8 <strnlen+0x6>
    802004d8:	85be                	mv	a1,a5
    802004da:	852e                	mv	a0,a1
    802004dc:	8082                	ret

00000000802004de <memset>:
    802004de:	ca01                	beqz	a2,802004ee <memset+0x10>
    802004e0:	962a                	add	a2,a2,a0
    802004e2:	87aa                	mv	a5,a0
    802004e4:	0785                	addi	a5,a5,1
    802004e6:	feb78fa3          	sb	a1,-1(a5)
    802004ea:	fec79de3          	bne	a5,a2,802004e4 <memset+0x6>
    802004ee:	8082                	ret
