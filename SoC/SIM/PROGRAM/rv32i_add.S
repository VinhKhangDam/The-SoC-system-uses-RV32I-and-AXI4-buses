.section .text
.globl _start

_start:
  addi x1, x0, 5
  addi x2, x0, 7
  add  x3, x1, x2
  addi x4, x0, 12
  bne  x3, x4, fail

  addi x5, x0, -1
  addi x6, x0, 1
  add  x7, x5, x6
  bne  x7, x0, fail

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
