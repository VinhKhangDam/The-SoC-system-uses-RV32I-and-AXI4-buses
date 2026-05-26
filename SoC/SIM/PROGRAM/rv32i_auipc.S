.section .text
.globl _start

_start:
  auipc x1, 0
  addi x2, x0, 0
  bne x1, x2, fail

  auipc x3, 1
  lui x4, 0x1
  addi x4, x4, 12
  bne x3, x4, fail

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
