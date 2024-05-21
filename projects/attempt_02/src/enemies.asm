.include "include/constants.asm"

.segment "ZEROPAGE"
.importzp enemy_x_pos, enemy_y_pos, enemy_x_vels, enemy_y_vels, enemy_flags, enemy_timer, current_enemy

.segment "CODE"
.export update_enemy
.proc update_enemy
  SaveRegisters             ; Save the state of the CPU registers

  LDX current_enemy         ; Load the current enemy index into X
  LDA enemy_flags, X        ; Load the enemy's flags using the X index
  AND #%10000000            ; Check if the highest bit (Active flag) is set
  BEQ done                  ; If the Active flag is not set, branch to done

  ; Update Y position
  LDA enemy_y_pos, X        ; Load the enemy's Y position using the X index
  CLC                       ; Clear the carry flag before addition
  ADC enemy_y_vels, X       ; Add the enemy's Y velocity to the Y position
  STA enemy_y_pos, X        ; Store the updated Y position back in memory

  ; Set inactive if Y >= 239
  CPY #239                  ; Compare the Y position to 239
  BCC done                  ; If Y < 239, branch to done (enemy is still active)
  LDA enemy_flags, X        ; Load the enemy's flags using the X index
  EOR #%10000000            ; Toggle the Active flag (set it to 0)
  STA enemy_flags, X        ; Store the updated flags back in memory

done:
  RestoreRegisters          ; Restore the state of the CPU registers
  RTS
.endproc

.export process_enemies
.proc process_enemies
  SaveRegisters             ; Save the state of the CPU registers

  ; Start with enemy zero.
  LDX #$00                  ; Initialize X register to 0

enemy:
  STX current_enemy         ; Store the current enemy index in current_enemy
  LDA enemy_flags, X        ; Load the enemy's flags using the X index
  ; Check if active (bit 7 set)
  AND #%10000000            ; Mask to check if the highest bit (Active flag) is set
  BEQ spawn_or_timer        ; If the Active flag is not set, branch to spawn_or_timer

  ; If we get here, the enemy is active,
  ; so call update_enemy
  JSR update_enemy          ; Jump to subroutine to update the enemy
  ; Then, get ready for the next loop.
  JMP prep_next_loop        ; Jump to prep_next_loop to process the next enemy

spawn_or_timer:
  ; Start a timer if it is not already running.
  LDA enemy_timer           ; Load the enemy timer
  BEQ spawn_enemy           ; If the timer is zero, branch to spawn_enemy
  CMP #20                   ; Compare the timer value to 20
  ; If carry is set, enemy_timer > 20
  BCC prep_next_loop        ; If the timer is less than 20, branch to prep_next_loop

  LDA #20                   ; Otherwise, reset the timer to 20
  STA enemy_timer           ; Store 20 in the enemy timer
  JMP prep_next_loop        ; Jump to prep_next_loop to process the next enemy

spawn_enemy:
  ; Set this slot as active
  ; (set bit 7 to "1")
  LDA enemy_flags, X        ; Load the enemy's flags using the X index
  ORA #%10000000            ; Set the highest bit to 1 to mark the enemy as active
  STA enemy_flags, X        ; Store the updated flags back in memory

  ; Set y position to zero
  LDA #$00                  ; Load 0 into the accumulator
  STA enemy_y_pos, X        ; Store 0 in the enemy's y position using the X index

  ; IMPORTANT: reset the timer!
  LDA #$FF                  ; Load 255 (0xFF) into the accumulator
  STA enemy_timer           ; Store 255 in the enemy timer

  ; After spawning the enemy, return to continue processing
  JMP prep_next_loop        ; Jump to prep_next_loop to process the next enemy

prep_next_loop:
  INX                       ; Increment the X register to process the next enemy
  CPX #NUM_ENEMIES          ; Compare X to the total number of enemies
  BNE enemy                 ; If X is not equal to NUM_ENEMIES, branch to enemy

  ; Done with all enemies. Decrement
  ; enemy spawn timer if 20 or less
  ; (and not zero)
  LDA enemy_timer           ; Load the enemy timer
  BEQ done                  ; If the timer is zero, branch to done
  CMP #20                   ; Compare the timer value to 20
  BEQ decrement             ; If the timer is equal to 20, branch to decrement
  BCS done                  ; If the timer is greater than 20, branch to done

decrement:
  DEC enemy_timer           ; Decrement the enemy timer by 1

done:
  ; Restore registers, then return
  RestoreRegisters          ; Restore the state of the CPU registers
  RTS                       ; Return from subroutine
.endproc

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
