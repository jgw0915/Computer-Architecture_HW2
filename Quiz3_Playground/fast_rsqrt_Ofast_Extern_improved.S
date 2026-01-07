    .file   "fast_rsqrt.c"
    .option nopic
    .attribute arch, "rv32i2p1_zicsr2p0"
    .attribute unaligned_access, 0
    .attribute stack_align, 16
    .text
    .align  2
    .globl  fast_rsqrt
    .type   fast_rsqrt, @function
fast_rsqrt:
    # prologue
    addi    sp,sp,-32
    sw      s0,24(sp)
    sw      ra,28(sp)
    li      s0,-1                  # C edge: return value for x==0
    beq     a0,zero,ret_zero_case  # if (x==0)

    sw      s1,20(sp)
    sw      s2,16(sp)
    li      s2,1
    mv      s1,a0                  # s1 = x
    li      s0,65536               # C edge: return value for x==1
    beq     a0,s2,ret_one_case     # if (x==1)

    sw      s3,12(sp)
    sw      s4,8(sp)

    # C03: exp = 31 - clz(x)
    call    clz
    li      a5,31
    sub     a5,a5,a0               # a5 = exp

    # C04: y = rsqrt_table[exp]
    lui     a4,%hi(rsqrt_table)
    slli    a2,a5,2
    addi    a4,a4,%lo(rsqrt_table)
    add     a2,a4,a2
    sll     s2,s2,a5               # s2 = (1u << exp)
    lw      s0,0(a2)               # s0 = y

    mv      a3,a0                  # keep clz(x) in a3 (as in original)
    bltu    s2,s1,interp_entry     # if (x > 1<<exp) → interpolate

newton_two_iters:
    li      s3,196608              # (3<<16)

    # ---- iteration 1 ----
    mv      a1,s0
    mv      a0,s0
    call    mul32                  # y2
    mv      a1,a0
    mv      a0,s1
    call    mul32                  # x*y2
    slli    a1,a1,16
    srli    a0,a0,16
    or      a0,a1,a0               # xy2 (Q16)
    sub     a1,s3,a0               # (3<<16)-xy2
    mv      a0,s0
    call    mul32
    srli    a0,a0,17
    slli    a1,a1,15
    or      s0,a1,a0               # y updated

    # ---- iteration 2 ----
    mv      a1,s0
    mv      a0,s0
    call    mul32                  # y2
    mv      a1,a0
    mv      a0,s1
    call    mul32                  # x*y2
    slli    a1,a1,16
    srli    a0,a0,16
    or      a0,a1,a0               # xy2 (Q16)
    sub     a1,s3,a0               # (3<<16)-xy2
    mv      a0,s0
    call    mul32
    srli    a0,a0,17
    slli    a1,a1,15
    or      s0,a1,a0               # y updated

    # epilogue for common path
    lw      s1,20(sp)
    lw      s2,16(sp)
    lw      s3,12(sp)
    lw      s4,8(sp)
    lw      ra,28(sp)
    mv      a0,s0
    lw      s0,24(sp)
    addi    sp,sp,32
    jr      ra

ret_zero_case:
    lw      ra,28(sp)
    mv      a0,s0
    lw      s0,24(sp)
    addi    sp,sp,32
    jr      ra

interp_entry:
    # C05–C08: linear interpolation toward next table entry when x > 2^exp
    li      a2,30
    mv      a0,s0
    bgt     a5,a2,interp_have_delta    # if exp>30, next=y_next=0 → delta=y

    # a0 = delta = y - y_next with safe table bound
    li      a2,32
    sub     a3,a2,a3
    slli    a3,a3,2
    add     a4,a4,a3
    lw      a0,0(a4)
    sub     a0,s0,a0

interp_have_delta:
    addi    a3,a5,-32
    blt     a3,zero,interp_frac_le_shift_prep

    # build frac = ((x - 2^exp)<<16)>>exp  in 32-bit, several packs
    li      a1,1
    sll     a1,a1,a3
    li      a4,0

interp_frac_build:
    sub     a4,s1,a4               # running difference
    sgtu    a2,a4,s1
    neg     a1,a1
    sub     a1,a1,a2
    slli    a1,a1,16
    srli    a2,a4,16
    or      a1,a2,a1
    slli    a4,a4,16
    blt     a3,zero,interp_frac_crosspack
    srl     a1,a1,a3

interp_apply_delta:
    call    mul32                  # mul32(delta, frac)
    srli    a0,a0,16               # >>16
    slli    a1,a1,16
    or      a0,a1,a0
    sub     s0,s0,a0               # y -= delta*frac>>16
    j       newton_two_iters

interp_frac_le_shift_prep:
    li      a4,1
    sll     a4,a4,a5
    li      a1,0
    j       interp_frac_build

ret_one_case:
    lw      ra,28(sp)
    mv      a0,s0
    lw      s0,24(sp)
    lw      s1,20(sp)
    lw      s2,16(sp)
    addi    sp,sp,32
    jr      ra

interp_frac_crosspack:
    li      a2,31
    slli    a3,a1,1
    sub     a2,a2,a5
    srl     a1,a4,a5
    sll     a5,a3,a2
    or      a1,a5,a1
    j       interp_apply_delta

    .size   fast_rsqrt, .-fast_rsqrt

    .section .rodata
    .align  2
    .type   rsqrt_table, @object
    .size   rsqrt_table, 128
rsqrt_table:
    .word   65536,46341,32768,23170,16384
    .word   11585,8192,5793,4096,2896
    .word   2048,1448,1024,724,512
    .word   362,256,181,128,90
    .word   64,45,32,23,16
    .word   11,8,6,4,3
    .word   2,1
    .ident  "GCC 14.2.0"
    .section .note.GNU-stack,"",@progbits
