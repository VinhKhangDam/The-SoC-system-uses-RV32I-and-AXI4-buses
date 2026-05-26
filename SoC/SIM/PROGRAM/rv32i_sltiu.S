.section .text
.globl _start

_start: 
  addi x1, x0, -1

  # Unsigned : 0xffffffff < 1 => false
  sltiu x2, x1, 1
  addi x0, x0, 0
  addi x0, x0, 0
  bne x2, x0, fail

  addi x3, x0, 1

  # Unsigned : 1 < 2 => true
  sltiu x4, x3, 2
  addi x0, x0, 0
  addi x0, x0, 0
  addi x5, x0, 1
  addi x0, x0, 0
  addi x0, x0, 0
  bne x4, x5, fail

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
