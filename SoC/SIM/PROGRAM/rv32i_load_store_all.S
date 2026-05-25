.section .text
.globl _start

_start:
  lui  x1, 0x10010
  addi x2, x0, 0x55
  sw   x2, 0(x1)
  lw   x3, 0(x1)
  bne  x3, x2, fail

  addi x4, x0, -1
  sw   x4, 4(x1)
  lw   x5, 4(x1)
  bne  x5, x4, fail

  addi x6, x0, 0x7f
  sw   x6, 8(x1)
  lw   x7, 8(x1)
  bne  x7, x6, fail

pass:
  lui  x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0x5a
  sw   x31, 0(x30)
  beq  x0, x0, end

fail:
  lui  x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0xa5
  sw   x31, 0(x30)

end:
  addi x0, x0, 0
