.include "include/constants.asm"

.segment "ZEROPAGE"
.importzp enemy_x_pos, enemy_y_pos, enemy_x_vels, enemy_y_vels, enemy_flags, enemy_timer, current_enemy

.segment "CODE"
.export draw_enemy
.proc draw_enemy
  SaveRegisters                ; Save the state of the CPU registers

  LDX current_enemy            ; Load the current enemy index into X
  LDA enemy_flags, X           ; Load the enemy's flags using the X index
  AND #%10000000               ; Check if the highest bit (Active flag) is set
  BNE continue                 ; If the Active flag is set, branch to continue
  JMP done                     ; If not, jump to done (skip drawing this enemy)

continue:
  LDA #$10                     ; Initialize A with the base offset for OAM
  LDX current_enemy            ; Reload current enemy index into X
  BEQ oam_address_found        ; If the current enemy index is zero, branch to oam_address_found

find_address:
  CLC                          ; Clear the carry flag before addition
  ADC #$10                     ; Add 16 to A (next OAM address block)
  DEX                          ; Decrement X
  BNE find_address             ; If X is not zero, repeat the loop

oam_address_found:
  LDX current_enemy            ; Reload current enemy index into X
  TAY                          ; Transfer the OAM address offset to Y
  LDA enemy_flags, X           ; Load the enemy's flags using the X index
  AND #%00000111               ; Mask out the bits to get the enemy type (bits 0-2)
  STA current_enemy_type       ; Store the enemy type in current_enemy_type

  ; Draw enemy top-left
  LDA enemy_y_pos, X           ; Load the enemy's Y position using X index
  STA $0200, Y                 ; Store Y position in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy_type       ; Load the enemy type into X
  LDA enemy_top_lefts, X       ; Load the top-left tile ID for the enemy type
  STA $0200, Y                 ; Store tile ID in OAM
  INY                          ; Increment Y for next OAM byte
  LDA enemy_palettes, X        ; Load the palette for the enemy type
  STA $0200, Y                 ; Store the palette in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy            ; Reload current enemy index into X
  LDA enemy_x_pos, X           ; Load the enemy's X position using X index
  STA $0200, Y                 ; Store X position in OAM
  INY                          ; Increment Y for next OAM byte

  ; Draw enemy top-right
  LDA enemy_y_pos, X           ; Load the enemy's Y position again
  STA $0200, Y                 ; Store Y position in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy_type       ; Reload enemy type into X
  LDA enemy_top_rights, X      ; Load the top-right tile ID for the enemy type
  STA $0200, Y                 ; Store tile ID in OAM
  INY                          ; Increment Y for next OAM byte
  LDA enemy_palettes, X        ; Load the palette again
  STA $0200, Y                 ; Store the palette in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy            ; Reload current enemy index into X
  LDA enemy_x_pos, X           ; Load the enemy's X position again
  CLC                          ; Clear the carry flag before addition
  ADC #$08                     ; Add 8 to X position (for the right side)
  STA $0200, Y                 ; Store X position in OAM
  INY                          ; Increment Y for next OAM byte

  ; Draw enemy bottom-left
  LDA enemy_y_pos, X           ; Load the enemy's Y position again
  CLC                          ; Clear the carry flag before addition
  ADC #$08                     ; Add 8 to Y position (for the bottom side)
  STA $0200, Y                 ; Store Y position in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy_type       ; Reload enemy type into X
  LDA enemy_bottom_lefts, X    ; Load the bottom-left tile ID for the enemy type
  STA $0200, Y                 ; Store tile ID in OAM
  INY                          ; Increment Y for next OAM byte
  LDA enemy_palettes, X        ; Load the palette again
  STA $0200, Y                 ; Store the palette in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy            ; Reload current enemy index into X
  LDA enemy_x_pos, X           ; Load the enemy's X position again
  STA $0200, Y                 ; Store X position in OAM
  INY                          ; Increment Y for next OAM byte

  ; Draw enemy bottom-right
  LDA enemy_y_pos, X           ; Load the enemy's Y position again
  CLC                          ; Clear the carry flag before addition
  ADC #$08                     ; Add 8 to Y position (for the bottom side)
  STA $0200, Y                 ; Store Y position in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy_type       ; Reload enemy type into X
  LDA enemy_bottom_rights, X   ; Load the bottom-right tile ID for the enemy type
  STA $0200, Y                 ; Store tile ID in OAM
  INY                          ; Increment Y for next OAM byte
  LDA enemy_palettes, X        ; Load the palette again
  STA $0200, Y                 ; Store the palette in OAM
  INY                          ; Increment Y for next OAM byte
  LDX current_enemy            ; Reload current enemy index into X
  LDA enemy_x_pos, X           ; Load the enemy's X position again
  CLC                          ; Clear the carry flag before addition
  ADC #$08                     ; Add 8 to X position (for the right side)
  STA $0200, Y                 ; Store X position in OAM

done:
  RestoreRegisters             ; Restore the state of the CPU registers
  RTS                          ; Return from subroutine
.endproc


.segment "RODATA"

enemy_top_lefts:
.byte $09, $0d                 ; Tile IDs for the top-left of enemies
enemy_top_rights:
.byte $0b, $0e                 ; Tile IDs for the top-right of enemies
enemy_bottom_lefts:
.byte $0a, $0f                 ; Tile IDs for the bottom-left of enemies
enemy_bottom_rights:
.byte $0c, $10                 ; Tile IDs for the bottom-right of enemies

enemy_palettes:
.byte $01, $02                 ; Palettes for enemies
