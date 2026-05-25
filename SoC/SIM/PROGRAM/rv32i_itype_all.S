.section .text
.globl _start

_start:
  addi x1, x0, 10
  addi x2, x1, -3
  addi x3, x0, 7
  bne  x2, x3, fail

  slti x4, x2, 8
  addi x5, x0, 1
  bne  x4, x5, fail

  xori x6, x2, 3
  addi x7, x0, 4
  bne  x6, x7, fail

  ori  x8, x2, 8
  addi x9, x0, 15
  bne  x8, x9, fail

  andi x10, x8, 6
  addi x11, x0, 6
  bne  x10, x11, fail

  addi x12, x0, 1
  slli x13, x12, 5
  addi x14, x0, 32
  bne  x13, x14, fail

  srli x15, x13, 4
  addi x16, x0, 2
  bne  x15, x16, fail

  addi x17, x0, -16
  srai x18, x17, 2
  addi x19, x0, -4
  bne  x18, x19, fail

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
