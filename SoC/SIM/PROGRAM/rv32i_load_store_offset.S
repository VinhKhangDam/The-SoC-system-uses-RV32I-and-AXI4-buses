.section .text
.globl _start

_start:
    # x30 = SoC software signature address: 0x100003f0
    lui   x30, 0x10000
    addi  x30, x30, 0x3f0

    # Base address in DRAM
    lui   x1, 0x10010

    # ------------------------------------------------------------
    # Store/read using positive offsets
    # ------------------------------------------------------------
    addi  x2, x0, 0x11
    sw    x2, 0(x1)
    lw    x3, 0(x1)
    bne   x2, x3, fail
    nop
    nop

    addi  x4, x0, 0x22
    sw    x4, 4(x1)
    lw    x5, 4(x1)
    bne   x4, x5, fail
    nop
    nop

    # ------------------------------------------------------------
    # Store/read using negative offset
    # x6 = base + 8
    # access 0(x1) through -8(x6)
    # ------------------------------------------------------------
    addi  x6, x1, 8
    addi  x7, x0, 0x33
    sw    x7, -8(x6)
    lw    x8, -8(x6)
    bne   x7, x8, fail
    nop
    nop

    # ------------------------------------------------------------
    # Store/read near positive imm limit
    # 2044 is max word-aligned positive 12-bit offset
    # ------------------------------------------------------------
    addi  x9, x0, 0x44
    sw    x9, 2044(x1)
    lw    x10, 2044(x1)
    bne   x9, x10, fail
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
