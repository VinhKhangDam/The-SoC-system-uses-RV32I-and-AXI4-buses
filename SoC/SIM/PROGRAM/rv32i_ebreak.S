.section .text
.globl _start

_start:
    lui   x30, 0x10000
    addi  x30, x30, 0x3f0

    addi  x1, x0, 1

    # Write PASS before EBREAK
    addi  x31, x0, 0x5a
    sw    x31, 0(x30)

    ebreak

    # These must NOT execute
    addi  x1, x0, 2
    addi  x31, x0, 0x0a5
    sw    x31, 0(x30)

done:
    jal   x0, done
