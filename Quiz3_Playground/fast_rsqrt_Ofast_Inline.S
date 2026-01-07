	.align	2
	.type	fast_rsqrt.part.0, @function
fast_rsqrt.part.0:
#-----------Compiler generated code for fast_rsqrt() function (part 0) -----------
	addi	sp,sp,-16
	sw	s0,12(sp)
	mv	t1,a0
	beq	a0,zero,.L71
	li	a5,65536
	bltu	a0,a5,.L72
	mv	a5,a0
	li	a2,8
	li	a4,0
.L19:
	li	a3,16777216
	bgeu	a5,a3,.L20
	slli	a5,a5,8
	mv	a4,a2
.L20:
	li	a3,268435456
	bgeu	a5,a3,.L21
	addi	a4,a4,4
	slli	a5,a5,4
.L21:
	li	a3,1073741824
	bgeu	a5,a3,.L22
	slli	a3,a5,2
	addi	a4,a4,2
	blt	a3,zero,.L70
.L23:
	addi	a4,a4,1
.L70:
	li	a3,31
	sub	a3,a3,a4
	lui	a5,%hi(.LANCHOR0)
	slli	a1,a3,2
	addi	a5,a5,%lo(.LANCHOR0)
	li	a2,1
	add	a1,a5,a1
	sll	a2,a2,a3
	lw	a0,0(a1)
	bleu	t1,a2,.L25
.L24:
	li	a2,32
	sub	a4,a2,a4
	slli	a4,a4,2
	add	a5,a5,a4
	lw	t5,0(a5)
	addi	a2,a3,-32
	sub	t5,a0,t5
	blt	a2,zero,.L28
	li	a4,1
	sll	a4,a4,a2
	li	a5,0
.L27:
	sub	a5,t1,a5
	sgtu	a1,a5,t1
	neg	a4,a4
	sub	a4,a4,a1
	slli	a4,a4,16
	srli	a1,a5,16
	or	a4,a1,a4
	slli	a5,a5,16
	srl	a6,a4,a2
	bge	a2,zero,.L31
	li	a2,31
	slli	a4,a4,1
	sub	a2,a2,a3
	srl	a6,a5,a3
	sll	a5,a4,a2
	or	a6,a5,a6
.L31:
	li	a1,0
	li	a2,0
	li	a5,0
	li	t3,1
	srli	t0,t5,1
	li	t6,31
	li	a7,32
	j	.L35
.L74:
	li	a4,0
	sll	a3,t5,a3
.L34:
	add	a4,a1,a4
	sltu	t4,a4,a1
	add	a2,a2,a3
	mv	a1,a4
	add	a2,t4,a2
.L32:
	addi	a5,a5,1
	beq	a5,a7,.L73
.L35:
	sll	a4,t3,a5
	and	a4,a4,a6
	addi	a3,a5,-32
	beq	a4,zero,.L32
	sub	a4,t6,a5
	bge	a3,zero,.L74
	srl	a3,t0,a4
	sll	a4,t5,a5
	j	.L34
.L72:
	slli	a5,a0,16
	li	a2,24
	li	a4,16
	j	.L19
.L73:
	slli	a2,a2,16
	srli	a1,a1,16
	or	a1,a2,a1
	sub	a0,a0,a1
.L25:
	li	t4,2
	li	a1,1
	li	a7,31
	li	a6,32
	srli	t3,t1,1
	li	t5,196608
.L18:
	li	t0,0
	li	a5,0
.L39:
	addi	a2,a5,-32
	sll	a3,a1,a5
	sll	a4,a0,a5
	srai	a2,a2,31
	and	a3,a3,a0
	and	a4,a4,a2
	addi	a5,a5,1
	beq	a3,zero,.L36
	add	t0,t0,a4
.L36:
	bne	a5,a6,.L39
	li	a2,0
	li	t6,0
	li	a5,0
	j	.L43
.L76:
	li	a4,0
	sll	a3,t1,a3
.L42:
	add	a4,a2,a4
	sltu	t2,a4,a2
	add	t6,t6,a3
	mv	a2,a4
	add	t6,t2,t6
.L40:
	addi	a5,a5,1
	beq	a5,a6,.L75
.L43:
	sll	a4,a1,a5
	and	a4,a4,t0
	addi	a3,a5,-32
	beq	a4,zero,.L40
	sub	a4,a7,a5
	bge	a3,zero,.L76
	srl	a3,t3,a4
	sll	a4,t1,a5
	j	.L42
.L75:
	slli	t6,t6,16
	srli	a2,a2,16
	or	a2,t6,a2
	sub	a2,t5,a2
	li	t0,0
	li	t6,0
	li	a5,0
	srli	s0,a0,1
	j	.L47
.L78:
	li	a4,0
	sll	a3,a0,a3
.L46:
	add	a4,t0,a4
	sltu	t2,a4,t0
	add	t6,t6,a3
	mv	t0,a4
	add	t6,t2,t6
.L44:
	addi	a5,a5,1
	beq	a5,a6,.L77
.L47:
	sll	a4,a1,a5
	and	a4,a4,a2
	addi	a3,a5,-32
	beq	a4,zero,.L44
	sub	a4,a7,a5
	bge	a3,zero,.L78
	srl	a3,s0,a4
	sll	a4,a0,a5
	j	.L46
.L77:
	slli	t6,t6,15
	srli	t0,t0,17
	or	a0,t6,t0
	beq	t4,a1,.L16
	li	t4,1
	j	.L18
.L16:
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
.L22:
	bge	a5,zero,.L23
	li	a6,31
	sub	a3,a6,a4
	lui	a5,%hi(.LANCHOR0)
	slli	a1,a3,2
	addi	a5,a5,%lo(.LANCHOR0)
	li	a2,1
	add	a1,a5,a1
	sll	a2,a2,a3
	lw	a0,0(a1)
	bleu	t1,a2,.L25
	bne	a3,a6,.L24
	mv	t5,a0
	li	a5,-2147483648
	li	a4,0
	li	a2,-1
	j	.L27
.L71:
	li	a0,0
	j	.L25
.L28:
	li	a5,1
	sll	a5,a5,a3
	li	a4,0
	j	.L27
	.size	fast_rsqrt.part.0, .-fast_rsqrt.part.0