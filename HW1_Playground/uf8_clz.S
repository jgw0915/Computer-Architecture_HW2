.section .text
.globl uf8_clz
.type uf8_clz, @function
uf8_clz:
# a0 -> function arg x on entry; return value on exit.
# ra -> return address (saved to stack).
# s0 -> frame pointer.
# t0 -> x (current working value).
# t1 -> n.
# t2 -> c.
# t3 -> y (temporary, store x >> c).

# initialize stack frame
        addi    sp,sp,-8          # prologue: make 48B stack frame
        sw      ra,4(sp)          # save ra
        sw      s0,0(sp)          # save s0
        addi    s0,sp,8           # s0 = frame pointer

        add     t0,a0,x0          # x = arg
        addi    t1,x0,32          # n = 32
        addi    t2,x0,16          # c = 16

# do { ... } while (c);
WHILE_LOOP:
        srl     t3,t0,t2          # y = x >> c
        beq     t3,x0,SKIP        # if (y) skip if
        sub     t1,t1,t2          # n -= c;
        add     t0,x0,t3          # x = y;
SKIP:
        srai    t2,t2,1           # c >>= 1;
        bne     t2,x0,WHILE_LOOP  # while (c) loop
        sub     a0,t1,t0          # return n - x;
        lw      ra,4(sp)          # epilogue
        lw      s0,0(sp)
        addi    sp,sp,8
        jr      ra