.section .text
.globl _start

_start:
  lui x30, 0x10000
  addi x30, x30, 0x3f0

  addi x1, x0, 1 
  slli x2, x1, 4
  addi x3, x0, 16
  bne x2, x3, fail
  nop 
  nop 

  lui x4, 0x80000 
  srli x5, x4, 4

  lui x6, 0x08000 
  bne x5, x6, fail
  nop
  nop

  lui x7, 0x80000
  srai x8, x7, 4

  lui x9, 0xf8000 
  bne x8, x9, fail
  nop
  nop

  addi x10, x0, 1 
  slli x11,x10, 31

  lui x12, 0x80000 
  bne x11, x12, fail
  nop
  nop

  srli x13, x12, 31
  addi x14, x0, 1 
  bne x13, x14, fail
  nop
  nop

pass:
  addi x31, x0, 0x5a
  sw x31, 0(x30)

done:
  jal x0, done

fail:
  addi x31, x0, 0x0a5
  sw x31, 0(x30)
  jal x0, done
