.section .text
.globl _start

_start:
    # x30 = SoC software signature address: 0x100003f0
    lui   x30, 0x10000
    addi  x30, x30, 0x3f0

    # ------------------------------------------------------------
    # Try to write x0 using ALU instructions
    # ------------------------------------------------------------
    addi  x0, x0, 123
    addi  x1, x0, 0
    bne   x1, x0, fail
    nop
    nop

    addi  x2, x0, 5
    addi  x3, x0, 7
    add   x0, x2, x3
    addi  x4, x0, 0
    bne   x4, x0, fail
    nop
    nop

    # ------------------------------------------------------------
    # Try to write x0 using LUI
    # ------------------------------------------------------------
    lui   x0, 0xfffff
    addi  x5, x0, 0
    bne   x5, x0, fail
    nop
    nop

    # ------------------------------------------------------------
    # Try to write x0 using JAL
    # JAL x0 should jump but not write a link value
    # ------------------------------------------------------------
    jal   x0, jal_x0_target

    jal   x0, fail

jal_x0_target:
    addi  x6, x0, 0
    bne   x6, x0, fail
    nop
    nop

    # ------------------------------------------------------------
    # Try to write x0 using load
    # Store a nonzero value, then lw into x0.
    # x0 must remain zero.
    # ------------------------------------------------------------
    lui   x7, 0x10010
    addi  x8, x0, 0x55
    sw    x8, 0(x7)

    lw    x0, 0(x7)
    addi  x9, x0, 0
    bne   x9, x0, fail
    nop
    nop

pass:
    addi  x31, x0, 0x5a
    sw    x31, 0(x30)

done:
    jal   x0, done

fail:
    addi  x31, x0, 0x0a5
    sw    x31, 0(x30)
    jal   x0, done
