    .text
    .globl  main
main:
    addi    x2, x2, -32
    sw      x8, 0(x2)
    sw      x9, 4(x2)
    sw      x18, 8(x2)
    sw      x19, 12(x2)
    sw      x20, 16(x2)

    li      x5, 0x15
    sw      x5, 20(x2)
    sw      x5, 24(x2)
    sw      x5, 28(x2)

    # Fix disk positions (BLANK 1-3: neutralize x5 effect)
    sw      x0, 20(x2)      # BLANK 1
    sw      x0, 24(x2)      # BLANK 2
    sw      x0, 28(x2)      # BLANK 3

    addi    x8, x0, 1
game_loop:
    # BLANK 4: Check loop termination (2^3 moves)
    addi    x5, x0, 8
    beq     x8, x5, finish_game

    # Gray code: gray(n) = n XOR (n >> 1)
    srli    x5, x8, 1       # BLANK 5: k=1
    xor     x6, x8, x5      # BLANK 6

    addi    x7, x8, -1      # BLANK 7
    srli    x28, x7, 1      # BLANK 8
    xor     x7, x7, x28     # BLANK 9

    xor     x5, x6, x7      # BLANK 10

    addi    x9, x0, 0
    andi    x6, x5, 1       # BLANK 11
    bne     x6, x0, disk_found   # BLANK 12

    addi    x9, x0, 1       # BLANK 13
    andi    x6, x5, 2       # BLANK 14
    bne     x6, x0, disk_found

    addi    x9, x0, 2       # BLANK 15

disk_found:
    # BLANK 16: check impossible pattern (example keeps original no-op path)
    andi    x30, x5, 5
    addi    x31, x0, 5
    beq     x30, x31, pattern_match
    jal     x0, continue_move
pattern_match:
continue_move:

    slli    x5, x9, 2       # BLANK 17: *4
    addi    x5, x5, 20      # BLANK 18: base offset 20
    add     x5, x2, x5
    lw      x18, 0(x5)

    bne     x9, x0, handle_large

    addi    x19, x18, 2     # BLANK 19
    addi    x6, x0, 3       # BLANK 20
    blt     x19, x6, display_move
    sub     x19, x19, x6
    jal     x0, display_move

handle_large:
    lw      x6, 20(x2)      # BLANK 21
    addi    x19, x0, 3      # BLANK 22: 0+1+2=3
    sub     x19, x19, x18
    sub     x19, x19, x6

display_move:
    la      x20, obdata
    add     x5, x20, x18
    lbu     x28, 0(x5)      # BLANK 23
    li      x6, 0x6F        # BLANK 24
    xor     x28, x28, x6
    addi    x28, x28, -0x12 # BLANK 25

    add     x7, x20, x19
    lbu     x29, 0(x7)
    xor     x29, x29, x6
    addi    x29, x29, -0x12

        # ===== rv32emu write(2) syscalls begin =====
    # print "Move Disk "
    li      x10, 1              # a0=fd=1
    la      x11, str1           # a1=buf
    la      x13, str1_end       # tmp = &str1_end
    la      x14, str1           # tmp = &str1
    sub     x12, x13, x14       # a2=len = end - start
    li      x17, 64             # a7=write
    ecall

    # print disk number (x9+1) as one ASCII char
    addi    x6, x9, 1           # 1..3
    addi    x6, x6, 48          # '0'+
    la      x11, tmpc           # a1=buf
    sb      x6, 0(x11)
    li      x10, 1              # a0=fd=1
    li      x12, 1              # a2=len=1
    li      x17, 64
    ecall

    # print " from "
    li      x10, 1
    la      x11, str2
    la      x13, str2_end
    la      x14, str2
    sub     x12, x13, x14
    li      x17, 64
    ecall

    # print source peg char in x11 (single byte)
    addi    x6, x28, 0          # move source char to x6
    la      x28, tmpc
    sb      x6, 0(x28)
    li      x10, 1
    add     x11, x0, x28
    li      x12, 1
    li      x17, 64
    ecall

    # print " to "
    li      x10, 1
    la      x11, str3
    la      x13, str3_end
    la      x14, str3
    sub     x12, x13, x14
    li      x17, 64
    ecall

    # print dest peg char in x12 (single byte)
    addi    x6, x29, 0
    la      x29, tmpc
    sb      x6, 0(x29)
    li      x10, 1
    add     x11, x0, x29
    li      x12, 1
    li      x17, 64
    ecall

    # print newline
    li      x10, 1
    la      x11, l
    li      x12, 1
    li      x17, 64
    ecall
    # ===== rv32emu write(2) syscalls end =====

    # BLANK 26-27: store new disk position
    slli    x5, x9, 2          # offset = disk * 4
    addi    x5, x5, 20
    add     x5, x2, x5
    sw      x19, 0(x5)

    # BLANK 28-29: next move
    addi    x8, x8, 1
    jal     x0, game_loop

finish_game:
    lw      x8, 0(x2)
    lw      x9, 4(x2)
    lw      x18, 8(x2)
    lw      x19, 12(x2)
    lw      x20, 16(x2)
    addi    x2, x2, 32

    # rv32emu exit(status=0)
    li      x10, 0              # a0=status
    li      x17, 93             # a7=exit
    ecall

    .data
obdata:     .byte   0x3c, 0x3b, 0x3a

str1:       .asciz  "Move Disk "
str1_end:
str2:       .asciz  " from "
str2_end:
str3:       .asciz  " to "
str3_end:

l:          .byte   10          # "\n"
tmpc:       .byte   0           # 1-byte scratch for write(char)
