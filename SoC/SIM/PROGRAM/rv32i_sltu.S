.section .text 
.globl _start

_start:
  addi x1, x0, -1
  addi x2, x0, 1

  # signed : -1 < 1 => true
  slt x3, x1, x2
  addi x0, x0, 0
  addi x0, x0, 0
  addi x4, x0, 1
  addi x0, x0, 0
  addi x0, x0, 0
  bne x3, x4, fail

  # unsigned : 0xffffffff < 1 => false
  sltu x5, x1, x2
  addi x0, x0, 0
  addi x0, x0, 0
  bne x5, x0, fail

  # unsigned : 1 < 0xffffffff => true
  sltu x6, x2, x1
  addi x0, x0, 0
  addi x0, x0, 0
  addi x7, x0, 1
  addi x0, x0, 0
  addi x0, x0, 0
  bne x6, x7, fail

pass:
  lui x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0x5a
  addi x0, x0, 0
  addi x0, x0, 0
  sw x31, 0(x30)
  beq x0, x0, end 

fail:
  lui x30, 0x10000
  addi x30, x30, 0x3f0
  addi x31, x0, 0xa5
  addi x0, x0, 0
  addi x0, x0, 0
  sw x31, 0(x30)

end:
  addi x0, x0, 0
