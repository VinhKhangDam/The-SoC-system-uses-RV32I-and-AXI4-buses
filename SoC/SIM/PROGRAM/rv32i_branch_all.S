.section .text
.globl _start

_start:
  addi x1, x0, 5
  addi x2, x0, 5
  addi x3, x0, 9

  beq  x1, x2, beq_taken_ok
  beq  x0, x0, fail

beq_taken_ok:
  beq  x1, x3, fail

  addi x4, x0, 1
  addi x5, x0, 1
  beq  x4, x5, pass
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
