.include "include/constants.asm"

.segment "ZEROPAGE"
.importzp enemy_x_pos, enemy_y_pos, enemy_x_vels, enemy_y_vels, enemy_flags, enemy_timer, current_enemy

.segment "CODE"
.export draw_enemy
.proc draw_enemy
SaveRegisters
  LDX current_enemy
  LDA enemy_flags, X
  AND #%10000000          ; Highest bit is the 'Active' flag
  BNE continue
  JMP done
  
continue:


done:
  RestoreRegisters
  RTS
.endproc
