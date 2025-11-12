	.file	"fast_rsqrt.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	fast_rsqrt
	.type	fast_rsqrt, @function
fast_rsqrt:
	addi	sp,sp,-32
	sw	s0,24(sp)
	sw	ra,28(sp)
	li	s0,-1
	beq	a0,zero,.L1
	sw	s1,20(sp)
	sw	s2,16(sp)
	li	s2,1
	mv	s1,a0
	li	s0,65536
	beq	a0,s2,.L15
	sw	s3,12(sp)
	sw	s4,8(sp)
	call	clz
	li	a5,31
	sub	a5,a5,a0
	lui	a4,%hi(.LANCHOR0)
	slli	a2,a5,2
	addi	a4,a4,%lo(.LANCHOR0)
	add	a2,a4,a2
	sll	s2,s2,a5
	lw	s0,0(a2)
	mv	a3,a0
	bltu	s2,s1,.L17
.L3:
	li	s4,2
	li	s3,196608
	li	s2,1
.L9:
	mv	a1,s0
	mv	a0,s0
	call	mul32
	mv	a1,a0
	mv	a0,s1
	call	mul32
	slli	a1,a1,16
	srli	a0,a0,16
	or	a0,a1,a0
	sub	a1,s3,a0
	mv	a0,s0
	call	mul32
	srli	a0,a0,17
	slli	a1,a1,15
	or	s0,a1,a0
	bne	s4,s2,.L13
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
.L1:
	lw	ra,28(sp)
	mv	a0,s0
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
.L13:
	li	s4,1
	j	.L9
.L17:
	li	a2,30
	mv	a0,s0
	bgt	a5,a2,.L4
	li	a2,32
	sub	a3,a2,a3
	slli	a3,a3,2
	add	a4,a4,a3
	lw	a0,0(a4)
	sub	a0,s0,a0
.L4:
	addi	a3,a5,-32
	blt	a3,zero,.L5
	li	a1,1
	sll	a1,a1,a3
	li	a4,0
.L6:
	sub	a4,s1,a4
	sgtu	a2,a4,s1
	neg	a1,a1
	sub	a1,a1,a2
	slli	a1,a1,16
	srli	a2,a4,16
	or	a1,a2,a1
	slli	a4,a4,16
	blt	a3,zero,.L7
	srl	a1,a1,a3
.L8:
	call	mul32
	srli	a0,a0,16
	slli	a1,a1,16
	or	a0,a1,a0
	sub	s0,s0,a0
	j	.L3
.L5:
	li	a4,1
	sll	a4,a4,a5
	li	a1,0
	j	.L6
.L15:
	lw	ra,28(sp)
	mv	a0,s0
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	addi	sp,sp,32
	jr	ra
.L7:
	li	a2,31
	slli	a3,a1,1
	sub	a2,a2,a5
	srl	a1,a4,a5
	sll	a5,a3,a2
	or	a1,a5,a1
	j	.L8
	.size	fast_rsqrt, .-fast_rsqrt
	.section	.rodata
	.align	2
	.set	.LANCHOR0,. + 0
	.type	rsqrt_table, @object
	.size	rsqrt_table, 128
rsqrt_table:
	.word	65536
	.word	46341
	.word	32768
	.word	23170
	.word	16384
	.word	11585
	.word	8192
	.word	5793
	.word	4096
	.word	2896
	.word	2048
	.word	1448
	.word	1024
	.word	724
	.word	512
	.word	362
	.word	256
	.word	181
	.word	128
	.word	90
	.word	64
	.word	45
	.word	32
	.word	23
	.word	16
	.word	11
	.word	8
	.word	6
	.word	4
	.word	3
	.word	2
	.word	1
	.ident	"GCC: (xPack GNU RISC-V Embedded GCC x86_64) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
