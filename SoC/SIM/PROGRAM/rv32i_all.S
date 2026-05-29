.section .text
.globl _start

_start:
    # Signature address: 0x100003f0
    lui   x30, 0x10000
    addi  x30, x30, 0x3f0

    # DRAM base: 0x10010000
    lui   x29, 0x10010

    # ------------------------------------------------------------
    # R-type ALU
    # ------------------------------------------------------------
    addi  x1, x0, 9
    addi  x2, x0, 4

    add   x3, x1, x2
    addi  x4, x0, 13
    bne   x3, x4, fail
    nop
    nop

    sub   x5, x1, x2
    addi  x6, x0, 5
    bne   x5, x6, fail
    nop
    nop

    and   x7, x1, x2
    addi  x8, x0, 0
    bne   x7, x8, fail
    nop
    nop

    or    x9, x1, x2
    addi  x10, x0, 13
    bne   x9, x10, fail
    nop
    nop

    xor   x11, x1, x2
    addi  x12, x0, 13
    bne   x11, x12, fail
    nop
    nop

    slt   x13, x2, x1
    addi  x14, x0, 1
    bne   x13, x14, fail
    nop
    nop

    addi  x15, x0, -1
    sltu  x16, x15, x1
    bne   x16, x0, fail
    nop
    nop

    # ------------------------------------------------------------
    # I-type ALU
    # ------------------------------------------------------------
    addi  x17, x0, 10
    addi  x18, x17, -3
    addi  x19, x0, 7
    bne   x18, x19, fail
    nop
    nop

    andi  x20, x17, 6
    addi  x21, x0, 2
    bne   x20, x21, fail
    nop
    nop

    ori   x22, x17, 1
    addi  x23, x0, 11
    bne   x22, x23, fail
    nop
    nop

    xori  x24, x17, 15
    addi  x25, x0, 5
    bne   x24, x25, fail
    nop
    nop

    slti  x26, x15, 1
    addi  x27, x0, 1
    bne   x26, x27, fail
    nop
    nop

    sltiu x28, x15, 1
    bne   x28, x0, fail
    nop
    nop

    # ------------------------------------------------------------
    # Shift R-type and shift immediate
    # ------------------------------------------------------------
    addi  x1, x0, 1
    addi  x2, x0, 4

    sll   x3, x1, x2
    addi  x4, x0, 16
    bne   x3, x4, fail
    nop
    nop

    lui   x5, 0x80000
    srl   x6, x5, x2
    lui   x7, 0x08000
    bne   x6, x7, fail
    nop
    nop

    sra   x8, x5, x2
    lui   x9, 0xf8000
    bne   x8, x9, fail
    nop
    nop

    slli  x10, x1, 31
    lui   x11, 0x80000
    bne   x10, x11, fail
    nop
    nop

    srli  x12, x11, 31
    addi  x13, x0, 1
    bne   x12, x13, fail
    nop
    nop

    srai  x14, x11, 4
    lui   x15, 0xf8000
    bne   x14, x15, fail
    nop
    nop

    # ------------------------------------------------------------
    # LUI / AUIPC
    # ------------------------------------------------------------
    lui   x16, 0x12345
    lui   x17, 0x12345
    bne   x16, x17, fail
    nop
    nop

    auipc x18, 0
    auipc x19, 0
    addi  x19, x19, -4
    bne   x18, x19, fail
    nop
    nop

    # ------------------------------------------------------------
    # Load/store word with offsets
    # ------------------------------------------------------------
    addi  x1, x0, 0x11
    sw    x1, 0(x29)
    lw    x2, 0(x29)
    bne   x1, x2, fail
    nop
    nop

    addi  x3, x0, 0x22
    sw    x3, 4(x29)
    lw    x4, 4(x29)
    bne   x3, x4, fail
    nop
    nop

    addi  x5, x29, 8
    addi  x6, x0, 0x33
    sw    x6, -8(x5)
    lw    x7, -8(x5)
    bne   x6, x7, fail
    nop
    nop

    # ------------------------------------------------------------
    # Byte/half load/store
    # ------------------------------------------------------------
    addi  x1, x0, 0
    sw    x1, 16(x29)

    addi  x2, x0, 0x7f
    sb    x2, 17(x29)
    lb    x3, 17(x29)
    bne   x2, x3, fail
    nop
    nop

    addi  x4, x0, -1
    sb    x4, 18(x29)
    lb    x5, 18(x29)
    bne   x4, x5, fail
    nop
    nop

    lbu   x6, 18(x29)
    addi  x7, x0, 255
    bne   x6, x7, fail
    nop
    nop

    addi  x8, x0, -128
    sh    x8, 20(x29)
    lh    x9, 20(x29)
    bne   x8, x9, fail
    nop
    nop

    lhu   x10, 20(x29)
    lui   x11, 0x00010
    addi  x11, x11, -128
    bne   x10, x11, fail
    nop
    nop

    # ------------------------------------------------------------
    # Branches
    # ------------------------------------------------------------
    addi  x1, x0, 5
    addi  x2, x0, 5
    beq   x1, x2, beq_ok
    nop
    nop
    jal   x0, fail

beq_ok:
    addi  x3, x0, 6
    bne   x1, x3, bne_ok
    nop
    nop
    jal   x0, fail

bne_ok:
    addi  x4, x0, -1
    addi  x5, x0, 1
    blt   x4, x5, blt_ok
    nop
    nop
    jal   x0, fail

blt_ok:
    bge   x5, x4, bge_ok
    nop
    nop
    jal   x0, fail

bge_ok:
    bltu  x4, x5, fail
    nop
    nop
    bgeu  x4, x5, branch_ok
    nop
    nop
    jal   x0, fail

branch_ok:
    # ------------------------------------------------------------
    # JAL / JALR link behavior
    # ------------------------------------------------------------
    jal   x1, jal_target

after_jal:
    jal   x0, fail

jal_target:
    auipc x2, 0
    addi  x2, x2, -4
    bne   x1, x2, fail
    nop
    nop

    auipc x3, 0
    addi  x3, x3, 17
    jalr  x4, 0(x3)

after_jalr:
    jal   x0, fail

jalr_target:
    auipc x5, 0
    addi  x5, x5, -4
    bne   x4, x5, fail
    nop
    nop

    # ------------------------------------------------------------
    # x0 hardwired behavior
    # ------------------------------------------------------------
    addi  x0, x0, 123
    addi  x6, x0, 0
    bne   x6, x0, fail
    nop
    nop

    add   x0, x1, x2
    addi  x7, x0, 0
    bne   x7, x0, fail
    nop
    nop

    # ------------------------------------------------------------
    # FENCE as NOP
    # ------------------------------------------------------------
    fence
    addi  x8, x0, 9
    addi  x9, x8, 1
    addi  x10, x0, 10
    bne   x9, x10, fail
    nop
    nop

pass:
    addi  x31, x0, 0x5a
    sw    x31, 0(x30)
    jal   x0, end_program

fail:
    addi  x31, x0, 0x0a5
    sw    x31, 0(x30)
    jal   x0, end_program

end_program:
    nop
    nop
    nop
    nop
