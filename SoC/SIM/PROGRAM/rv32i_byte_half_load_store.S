.section .text
.globl _start

_start:
  lui  x1, 0x10010
  addi x0, x0, 0
  addi x0, x0, 0

  addi x2, x0, 0x7f
  addi x0, x0, 0
  addi x0, x0, 0
  sb   x2, 0(x1)
  addi x0, x0, 0
  addi x0, x0, 0

  addi x3, x0, 0x12
  addi x0, x0, 0
  addi x0, x0, 0
  sb   x3, 1(x1)
  addi x0, x0, 0
  addi x0, x0, 0

  addi x4, x0, 0x34
  addi x0, x0, 0
  addi x0, x0, 0
  sb   x4, 2(x1)
  addi x0, x0, 0
  addi x0, x0, 0

  addi x5, x0, 0x56
  addi x0, x0, 0
  addi x0, x0, 0
  sb   x5, 3(x1)
  addi x0, x0, 0
  addi x0, x0, 0

  lw   x6, 0(x1)
  addi x0, x0, 0
  addi x0, x0, 0
  lui  x7, 0x56341
  addi x7, x7, 0x27f
  addi x0, x0, 0
  addi x0, x0, 0
  bne  x6, x7, fail

  addi x8, x0, -1
  addi x0, x0, 0
  addi x0, x0, 0
  sb   x8, 4(x1)
  addi x0, x0, 0
  addi x0, x0, 0

  lb   x9, 4(x1)
  addi x0, x0, 0
  addi x0, x0, 0
  bne  x9, x8, fail

  lbu  x10, 4(x1)
  addi x0, x0, 0
  addi x0, x0, 0
  addi x11, x0, 0xff
  addi x0, x0, 0
  addi x0, x0, 0
  bne  x10, x11, fail

  addi x12, x0, -128
  addi x0, x0, 0
  addi x0, x0, 0
  sh   x12, 8(x1)
  addi x0, x0, 0
  addi x0, x0, 0

  lh   x13, 8(x1)
  addi x0, x0, 0
  addi x0, x0, 0
  bne  x13, x12, fail

  lhu  x14, 8(x1)
  addi x0, x0, 0
  addi x0, x0, 0
  lui  x15, 0x00010
  addi x15, x15, -128
  addi x0, x0, 0
  addi x0, x0, 0
  bne  x14, x15, fail

pass:
  lui  x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0x5a
  addi x0, x0, 0
  addi x0, x0, 0
  sw   x31, 0(x30)
  beq  x0, x0, end

fail:
  lui  x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0xa5
  addi x0, x0, 0
  addi x0, x0, 0
  sw   x31, 0(x30)

end:
  addi x0, x0, 0
