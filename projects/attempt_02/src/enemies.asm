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
  LDA #$10
  LDX current_enemy
  BEQ oam_address_found

find_address:
  CLC
  ADC #$10
  DEX
  BNE find_address

oam_address_found:
  LDX current_enemy
  TAY ; use Y to hold OAM address offset
  ; Find the current enemy's type and
  ; store it for later use. The enemy type
  ; is in bits 0-2 of enemy_flags.
  LDA enemy_flags, X
  AND #%00000111
  STA current_enemy_type
  ; enemy top-left
  LDA enemy_y_pos, X
  STA $0200, Y
  INY
  LDX current_enemy_type
  LDA enemy_top_lefts, X
  STA $0200, Y
  INY
  LDA enemy_palettes, X
  STA $0200, Y
  INY
  LDX current_enemy
  LDA enemy_x_pos, X
  STA $0200, Y
  INY

  ; enemy top-right
  LDA enemy_y_pos, X
  STA $0200, Y
  INY
  LDX current_enemy_type
  LDA enemy_top_rights, X
  STA $0200, Y
  INY
  LDA enemy_palettes, X
  STA $0200, Y
  INY
  LDX current_enemy
  LDA enemy_x_pos, X
  CLC
  ADC #$08
  STA $0200, Y
  INY

  ; enemy bottom-left
  LDA enemy_y_pos, X
  CLC
  ADC #$08
  STA $0200, Y
  INY
  LDX current_enemy_type
  LDA enemy_bottom_lefts, X
  STA $0200,Y
  INY
  LDA enemy_palettes, X
  STA $0200, Y
  INY
  LDX current_enemy
  LDA enemy_x_pos, X
  STA $0200, Y
  INY

  ; enemy bottom-right
  LDA enemy_y_pos, X
  CLC
  ADC #$08
  STA $0200, Y
  INY
  LDX current_enemy_type
  LDA enemy_bottom_rights, X
  STA $0200,Y
  INY
  LDA enemy_palettes, X
  STA $0200,Y
  INY
  LDX current_enemy
  LDA enemy_x_pos, X
  CLC
  ADC #$08
  STA $0200, Y

done:
  RestoreRegisters
  RTS
.endproc


.segment "RODATA"

enemy_top_lefts:
.byte $09, $0d
enemy_top_rights:
.byte $0b, $0e
enemy_bottom_lefts:
.byte $0a, $0f
enemy_bottom_rights:
.byte $0c, $10

enemy_palettes:
.byte $01, $02
