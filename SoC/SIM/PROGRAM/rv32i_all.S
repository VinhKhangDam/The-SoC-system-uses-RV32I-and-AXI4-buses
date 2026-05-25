.section .text
.globl _start

_start:
  addi x1, x0, 12
  addi x2, x0, 5

  add  x3, x1, x2
  addi x4, x0, 17
  bne  x3, x4, fail

  sub  x5, x1, x2
  addi x6, x0, 7
  bne  x5, x6, fail

  sll  x7, x2, x2
  addi x8, x0, 160
  bne  x7, x8, fail

  slt  x9, x2, x1
  addi x10, x0, 1
  bne  x9, x10, fail

  xor  x11, x1, x2
  addi x12, x0, 9
  bne  x11, x12, fail

  srl  x13, x7, x2
  bne  x13, x2, fail

  addi x14, x0, -8
  sra  x15, x14, x10
  addi x16, x0, -4
  bne  x15, x16, fail

  or   x17, x1, x2
  addi x18, x0, 13
  bne  x17, x18, fail

  and  x19, x1, x2
  addi x20, x0, 4
  bne  x19, x20, fail

  slti x21, x2, 6
  bne  x21, x10, fail

  xori x22, x2, 3
  addi x23, x0, 6
  bne  x22, x23, fail

  ori  x24, x2, 8
  addi x25, x0, 13
  bne  x24, x25, fail

  andi x26, x24, 12
  addi x27, x0, 12
  bne  x26, x27, fail

  lui  x28, 0x10010
  sw   x27, 0(x28)
  lw   x29, 0(x28)
  bne  x29, x27, fail

  jal  x5, after_jal
  beq  x0, x0, fail

after_jal:
  beq  x10, x10, pass
  beq  x0, x0, fail

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
