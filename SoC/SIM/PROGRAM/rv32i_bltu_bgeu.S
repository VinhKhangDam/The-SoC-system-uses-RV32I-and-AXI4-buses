.section .text
.globl _start

_start:
  # x30 = SoC software signature address : 0x100003f0
  lui x30, 0x10000
  addi x30, x30, 0x3f0

  addi x1, x0, -1
  addi x2, x0, 1

  bltu x1, x2, fail
  nop
  nop

  bgeu x1, x2, case2
  nop
  nop
  jal x0, fail

case2: 
  addi x3, x0, 0
  addi x4, x0, -1

  bltu x3, x4, case3
  nop
  nop
  jal x0, fail

case3:
  addi x5, x0, 25
  addi x6, x0, 25

  bltu x5, x6, fail
  nop
  nop

  bgeu x5, x6, case4
  nop
  nop
  jal x0, fail

case4:
  addi x7, x0, 8
  addi x8, x0, 15

  bltu x7, x8, case5
  nop
  nop
  jal x0, fail

case5:
  addi x9, x0, 15
  addi x10, x0, 8

  bgeu x9, x10, pass
  nop
  nop
  jal x0, fail

pass:
  addi x31, x0, 0x5a
  sw x31, 0(x30)

done: 
  jal x0, done

fail:
  addi x31, x0, 0x0a5
  sw x31, 0(x30)
  jal x0, done
