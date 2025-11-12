.section .text
.globl uf8_encode
uf8_encode:
# register roles:
#   a0 : uint32_t value (input)
#   s0 : frame pointer
#   t0 : input value copy
#   t1 : msb (most significant bit position)
#   t2 : exponent
#   t3 : overflow (offset for current exponent)
#   t4 : e (temporary for exponent calculation)
#   t5 : next_overflow (offset for next exponent)
#   t6 : mantissa
#   a1 : temporary constant
# stack frame (from s0, growing down):
#   -4(s0)  : ra
#   -8(s0)  : saved s0
#   -12(s0) : uint32_t value (spill)

#   initialize stack frame
        addi    sp,sp,-16
        sw      ra,8(sp)
        sw      s0,4(sp)
        addi    s0,sp,16

#   quick return for value <= 15
        addi    a1,zero,15        # a1 = 15
        bgtu    a0,a1,init_exponent_guess  # if (value <= 15) return value
        j       uf8_encode_return
init_exponent_guess:
#   initialize variables for exponent guessing loop
        sw      a0,0(sp)               # save value across call
        call    uf8_clz                # call uf8_clz(value)
        li      t1,31                  # t1 = msb = 31
        lw      t0,0(sp)               # t0 = value
        sub     t1,t1,a0               # msb = 31 - uf8_clz(value)

        li      t2,0                    # t2 = exponent = 0
        li      t3,0                    # t3 = overflow = 0

#   Estimate exponent
        addi    a1,x0,4                  # a1 = 4
        ble     t1,a1,find_exact_exponent   # if (msb <= 4) goto find_exact_exponent
        addi    t2,t1,-4                   # exponent = msb - 4
#   Handle exponent overflow
        addi    a1,x0,15                    # a1 = 15
        bleu    t2,a1,estimate_exponent_and_overflow    # if (exponent <= 15) goto estimate_exponent
        addi    t2,x0,15                    # exponent = 15

estimate_exponent_and_overflow:
#   Calculate overflow for current exponent
        addi    t4,x0,0                   # t4 = e = 0

        j       Loop_condition_1

Loop_1:
        slli    t3,t3,1                   # overflow <<= 1
        addi    t3,t3,16                  # overflow += 16
        addi    t4,t4,1                   # e += 1

Loop_condition_1:
        bltu    t4,t2,Loop_1
        
adjust_e_o:
#   adjust exponent and overflow
        beq     t2,x0,find_exact_exponent   # if (exponent == 0) goto find_exact_exponent
        bge     t0,t3,find_exact_exponent   # if (value >= overflow) go to estimating
        addi    t3,t3,-16                 # overflow -= 16
        srli    t3,t3,1                   # overflow >>= 1
        addi    t2,t2,-1                  # exponent -= 1
        j       adjust_e_o

find_exact_exponent:
#   Find exact exponent
        addi    a1,x0,14                   # a1 = 14
        bgtu    t2,a1,finalize            # if (exponent > 14) goto finalize
        slli    t5,t3,1                   # next_overflow = overflow << 1
        addi    t5,t5,16                  # next_overflow += 16
        bltu    t0,t5,finalize            # if (value < next_overflow) goto finalize
        addi    t3,t5,0                   # overflow = next_overflow
        addi    t2,t2,1                   # exponent += 1

        j       find_exact_exponent
finalize:
#   Calculate mantissa
        sub    t6,t0,t3          # mantissa = value - overflow
        srl    t6,t6,t2          # mantissa >>= exponent
        andi   t6,t6,15          # mantissa &= 0x0f
#   Combine exponent and mantissa
        slli   t2,t2,4           # exponent <<= 4
        slli   t2,t2,24
        srai   t2,t2,24
        or     a0,t2,t6          # return (exponent << 4) | mantissa
        slli   a0,a0,24
        srai   a0,a0,24

uf8_encode_return:
        lw      ra,8(sp)          # epilogue: restore ra
        lw      s0,4(sp)          # restore s0
        addi    sp,sp,16           # free frame
        jr      ra                 # return
        