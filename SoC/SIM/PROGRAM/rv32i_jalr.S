.section .text 
.globl _start

_start:
  auipc x1, 0
  addi x1, x1, 20
  jalr x5, 0(x1)
  beq x0, x0, fail
  addi x0, x0, 0
  addi x0, x0, 0

target: 
  addi x2, x0, 1
  addi x3, x0, 12
  bne x5, x3, fail
  bne x2, x0, pass
  beq x0, x0, fail

pass: 
  lui x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0x5a
  sw x31, 0(x30)
  beq x0, x0, end

fail:
  lui x30, 0x10000 
  addi x30, x30, 0x3f0 
  addi x31, x0, 0xa5
  sw x31, 0(x30)

end:
  addi x0, x0, 0
