.include "include/constants.inc"
.include "include/header.inc"

.import reset_handler, draw_objects, draw_starfield

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CODE"
.export main
.proc main
  LDA #239            ;NES can only show at pixel 240, not the full 256
  STA scroll
  LDX #$3f            ;Pallete data starts at $3f00
  STX PPUADDR         ;Set the high bit 3f
  LDX #$00            
  STX PPUADDR         ;Set the low bit 00

load_palletes:
  LDA palletes, X     ;x register is 0 and reads from pallete. If something changes before this, do LDX #$00
  STA PPUDATA         ;store the actual value located at index
  INX
  CPX #$10            ;CPX does subtraction to check if x is 10 (16 in decimal)
  BNE load_palletes   ;Zero flag set when x is 4

  LDX #$20
  JSR draw_starfield

  LDX #$28
  JSR draw_starfield

  JSR draw_objects

  LDA #%10010000        ; Turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings  ; Store the value we send to the ppu controller to modify and re-use later
  STA PPUCTRL

  LDA #%00011110        ; Turn on screen?
  STA PPUMASK
forever:
  JMP forever
.endproc

.proc nmi_handler     ;Will come back to document this
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA  
	LDA #$00            ;I don't know what this does but it's needed :(

  JSR update_player_back_and_forth
  JSR draw_player

  LDA scroll
  CMP #$00
  BNE set_scroll_positions
  LDA ppuctrl_settings
  EOR #%00000010
  STA PPUCTRL
  LDA #240
  STA scroll

set_scroll_positions:
  LDA #$00
  STA PPUSCROLL       ;$2005 - X SCROLL
  DEC scroll
  LDA scroll
  STA PPUSCROLL       ;$2005 - Y SCROLL
  ;A register should be 0 so each write sets the X & Y of the scroll:
	; STA PPUSCROLL       ;$2005 - X SCROLL
	; STA PPUSCROLL       ;$2005 - Y SCROLL
  RTI
.endproc

.proc irq_handler
  RTI
.endproc

.proc update_player_back_and_forth
  SaveRegisters            ; Save the current state of the CPU registers

  LDA player_x             ; Load the value of player_x into the accumulator
  CMP #$e0                 ; Compare player_x with e0 (224)
  BCC not_at_right_edge    ; If player_x < e0, branch to not_at_right_edge
  LDA #$00                 ; Otherwise, load 0 into the accumulator
  STA player_dir           ; Store 0 in player_dir (indicating move left)
  JMP direction_set        ; Jump to direction_set to skip the rest of the checks

not_at_right_edge:         ; player_x is less than e0, check the lower boundary
  LDA player_x             ; Load the value of player_x into the accumulator
  CMP #$10                 ; Compare player_x with 10 (16)
  BCS direction_set        ; If player_x >= 10, branch to direction_set
  LDA #$01                 ; Otherwise, load 1 into the accumulator
  STA player_dir           ; Store 1 in player_dir (indicating move right)

direction_set:             ; Set the player's movement direction
  LDA player_dir           ; Load the value of player_dir into the accumulator
  CMP #$01                 ; Compare player_dir with 1
  BEQ move_right           ; If player_dir is 1, branch to move_right (move right)

  DEC player_x             ; If player_dir is not 1, decrement player_x (move left)
  JMP exit_subroutine      ; Jump to exit_subroutine to finish

move_right:                ; Routine to move the player to the right
  INC player_x             ; Increment player_x (move right)

exit_subroutine:           ; Routine to finish the procedure
  RestoreRegisters         ; Restore the state of the CPU registers
  RTS                      ; Return from subroutine

.endproc


.proc draw_player
  SaveRegisters
  
  ; Write player ship tile numbers
  LDA #$05
  STA $0201         ; Setting tile ID of A (05) sprite 1
  LDA #$06
  STA $0205         ; Setting tile ID of A (06) sprite 2
  LDA #$07
  STA $0209         ; etc ^ (07) sprite 3
  LDA #$08
  STA $020d         ; etc ^ (08) sprite 4
  ;End writing tile numbers

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202         ; Setting attribute for pallete (0) for tile 05 - sprite 1
  STA $0206         ; Setting attribute for pallete (0) for tile 06 - sprite 2
  STA $020a         ; Setting attribute for pallete (0) for tile 07 - sprite 3
  STA $020e         ; Setting attribute for pallete (0) for tile 08 - sprite 4

  ; Positions
  ; Sprite 1: Top Left
  LDA player_y
  STA $0200         ; Y Position
  LDA player_x
  STA $0203         ; X Position

  ; Sprite 2: Top Right
  LDA player_y
  STA $0204         ; Y Position
  LDA player_x
  CLC               ; Always clear carry flag before additon (unless for 16 bytes)
  ADC #$08          ; Add player_x + 8 for tile to the right
  STA $0207         ; X Position

  ; Sprite 3: Bottom Left
  LDA player_y
  CLC
  ADC #$08          ; Add player_y + 8 for tile underneath top left corner
  STA $0208         ; Y Position
  LDA player_x
  STA $020b         ; X Position

  ; Sprite 4: Bottom Right
  LDA player_y
  CLC
  ADC #$08          ; Add player_y + 8 for tile below top left corner
  STA $020c
  LDA player_x
  CLC
  ADC #$08          ; Add player_x + 8 for for tile to right of top left corner
  STA $020f
  ; Combined together, puts this tile to the right and below top left corner
  ; End positions

  RestoreRegisters

  RTS
.endproc

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
.exportzp player_x, player_y

.segment "CHR"
.incbin "assets/space.chr"

.segment "RODATA"
palletes:
.byte $0f,$00,$10,$30
.byte $0f,$0c,$21,$32
.byte $0f,$05,$16,$27
.byte $0f,$0b,$1a,$29

.byte $0f,$00,$10,$30
.byte $0f,$0c,$21,$32
.byte $0f,$05,$16,$27
.byte $0f,$0b,$1a,$29
; .byte $0f, $12, $23, $27
; .byte $0f, $2b, $3c, $39
; .byte $0f, $0c, $07, $13
; .byte $0f, $19, $09, $29

; .byte $0f, $2d, $10, $15
; .byte $0f, $19, $09, $29
; .byte $0f, $19, $09, $29
; .byte $0f, $19, $09, $29

sprites:
.byte $70, $05, $00, $80 ; 0 = Y position, 1 = TileID, 2 = Attribute, 3 = X position

; palette_session_a:
; .byte $0f,$00,$10,$30
; .byte $0f,$0c,$21,$32
; .byte $0f,$05,$16,$27
; .byte $0f,$0b,$1a,$29


; ASM Notes:
; CMP is A register MINUS the value after CMP
; For example: LDA #$05 CMP #$09  is 5 - 9 and carry flag would be set for BCC

; https://famicom.party/book/11-branchingandloops/
; BEQ (“Branch if Equals zero”) 
; BNE (“Branch if Not Equals zero”)
; BCS (“Branch if Carry Set”)
; BCC (“Branch if Carry Cleared”) 

; Making Comparisons
; While the loops we have seen so far are useful, they require some careful setup. 
; The loops above rely on our loop counter becoming zero in order to end the loop. To make more flexible and 
; powerful loops, we need the ability to make arbitrary comparisons. In 6502 assembly, the opcodes that let us 
; do that are CMP, “Compare (with accumulator)“, CPX, “Compare with X register”, and CPY, “Compare with Y register”.

; Each of these opcodes works by performing a subtraction, setting the zero and carry flags as appropriate,
; and then discarding the result of the subtraction. Remember that when we perform a subtraction, we first set 
; the carry flag. This means that we have three possible outcomes from a comparison, based on the register value 
; and the value we are comparing it to:

; Register is larger than comparison value: Carry flag set, zero flag clear
; Register is equal to comparison value: Carry flag set, zero flag set
; Register is smaller than comparison value: Carry flag clear, zero flag clear
