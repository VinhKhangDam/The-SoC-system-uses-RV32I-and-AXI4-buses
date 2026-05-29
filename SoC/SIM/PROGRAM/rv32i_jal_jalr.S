.section .text
.globl _start

_start:
  lui x30, 0x10000
  addi x30, x30, 0x3f0

  jal x1, jal_target

after_jal:
  jal x0, fail 

jal_target:
  addi x2, x0, 0x0c 
  bne x1, x2, fail
  nop
  nop

  addi x3, x0, 0x2d

  jalr x4, 0(x3)

after_jalr:
  jal x0, fail

jalr_target:
  addi x5, x0, 0x28 
  bne x4, x5, fail
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
