.section .text
.globl _start

_start:
  lui  x1, 0x12345
  lui  x2, 0x12345
  bne  x1, x2, fail

  jal  x3, jal_target
  beq  x0, x0, fail

jal_target:
  addi x4, x0, 1
  bne  x4, x0, pass
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
