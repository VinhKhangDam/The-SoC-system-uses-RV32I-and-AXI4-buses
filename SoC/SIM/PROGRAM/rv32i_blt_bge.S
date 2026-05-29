.section .text
.globl _start

_start:
    # x30 = SoC software signature address: 0x100003f0
    lui   x30, 0x10000
    addi  x30, x30, 0x3f0

    # ------------------------------------------------------------
    # Case 1:
    # signed: -1 < 1, so BLT must branch
    # ------------------------------------------------------------
    addi  x1, x0, -1
    addi  x2, x0, 1

    blt   x1, x2, case2
    nop
    nop
    jal   x0, fail

case2:
    # ------------------------------------------------------------
    # Case 2:
    # signed: 1 >= -1, so BGE must branch
    # ------------------------------------------------------------
    addi  x3, x0, 1
    addi  x4, x0, -1

    bge   x3, x4, case3
    nop
    nop
    jal   x0, fail

case3:
    # ------------------------------------------------------------
    # Case 3:
    # signed: -1 >= 1 is false, so BGE must NOT branch
    # ------------------------------------------------------------
    bge   x1, x2, fail
    nop
    nop

    # ------------------------------------------------------------
    # Case 4:
    # signed: 1 < -1 is false, so BLT must NOT branch
    # ------------------------------------------------------------
    blt   x3, x4, fail
    nop
    nop

case4:
    # ------------------------------------------------------------
    # Case 5:
    # equal values:
    # BLT must NOT branch, BGE must branch
    # ------------------------------------------------------------
    addi  x5, x0, 20
    addi  x6, x0, 20

    blt   x5, x6, fail
    nop
    nop

    bge   x5, x6, pass
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
