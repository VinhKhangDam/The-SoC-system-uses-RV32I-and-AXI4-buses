.section .text
.globl _start

_start:
    # x30 = SoC software signature address: 0x100003f0
    lui   x30, 0x10000
    addi  x30, x30, 0x3f0

    # ------------------------------------------------------------
    # Case 1: equal values, BEQ must branch
    # ------------------------------------------------------------
    addi  x1, x0, 10
    addi  x2, x0, 10

    beq   x1, x2, case2
    nop
    nop
    jal   x0, fail

case2:
    # ------------------------------------------------------------
    # Case 2: different values, BNE must branch
    # ------------------------------------------------------------
    addi  x3, x0, 11
    addi  x4, x0, 12

    bne   x3, x4, case3
    nop
    nop
    jal   x0, fail

case3:
    # ------------------------------------------------------------
    # Case 3: equal values, BNE must NOT branch
    # ------------------------------------------------------------
    bne   x1, x2, fail
    nop
    nop

    # ------------------------------------------------------------
    # Case 4: different values, BEQ must NOT branch
    # ------------------------------------------------------------
    beq   x3, x4, fail
    nop
    nop

    # ------------------------------------------------------------
    # Case 5: compare x0
    # ------------------------------------------------------------
    beq   x0, x0, pass
    nop
    nop
    jal   x0, fail

pass:
    addi  x31, x0, 0x5a
    sw    x31, 0(x30)

done:
    jal   x0, done

fail:
    addi  x31, x0, 0x0a5
    sw    x31, 0(x30)
    jal   x0, done
