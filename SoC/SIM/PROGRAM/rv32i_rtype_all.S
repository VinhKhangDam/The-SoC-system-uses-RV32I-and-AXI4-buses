.section .text
.globl _start

_start:
  addi x1, x0, 20
  addi x2, x0, 7

  add  x3, x1, x2
  addi x4, x0, 27
  bne  x3, x4, fail

  sub  x5, x1, x2
  addi x6, x0, 13
  bne  x5, x6, fail

  addi x7, x0, 1
  sll  x8, x7, x2
  addi x9, x0, 128
  bne  x8, x9, fail

  slt  x10, x2, x1
  addi x11, x0, 1
  bne  x10, x11, fail

  xor  x12, x1, x2
  addi x13, x0, 19
  bne  x12, x13, fail

  srl  x14, x8, x2
  bne  x14, x7, fail

  addi x15, x0, -8
  sra  x16, x15, x7
  addi x17, x0, -4
  bne  x16, x17, fail

  or   x18, x1, x2
  addi x19, x0, 23
  bne  x18, x19, fail

  and  x20, x1, x2
  addi x21, x0, 4
  bne  x20, x21, fail

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
