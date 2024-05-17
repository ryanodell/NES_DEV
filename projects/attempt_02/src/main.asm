.include "include/constants.inc"
.include "include/header.inc"

.import reset_handler

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CODE"
.export main
.proc main
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

  ;Writing thing (35) to background 
	LDX #$35            ;The Star
  LDA PPUSTATUS
	LDA #$20            ;Low byte
	STA PPUADDR
	LDA #$83            ;High byte
	STA PPUADDR
	STX PPUDATA

  ;Attribute table
  LDA PPUSTATUS
	LDA #$23            ;High byte NEXXT atOff(xx)
	STA PPUADDR
	LDA #$c8            ;Low byte  (NEXXT atOff(xx))
	STA PPUADDR
	LDA #%00001000      ;.2 so it would be in the top right 4x4
	STA PPUDATA         ;Set the data in the ppu

  LDA #%10010000      ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL

  LDA #%00011110      ;Turn on screen?
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

  JSR update_player
  JSR draw_player
	STA $2005
	STA $2005
  RTI
.endproc

.proc irq_handler
  RTI
.endproc

.proc update_player
  SaveRegisters
  LDA player_x
  CMP #$e0                ; Compayer player_x with e0
  BCC not_at_right_edge   ; Is the register value larger than e0?
  LDA #$00
  STA player_dir          ; Set it to 0 so we start moving left
  JMP direction_set
not_at_right_edge:        ; We are not, keep moving right
  LDA player_x
  CMP #$10
  BCS direction_set       ;
  LDA #$01                
  STA player_dir          ; Set direction to 1 (right)
direction_set:
  ; Actually move the player's x in either direction
  LDA player_dir
  CMP #$01
  BEQ move_right ; Direction was set to 1 so move right. If not, we move left (line below this)
  DEC player_x
  JMP exit_subroutine
move_right:
  INC player_x
exit_subroutine:
  RestoreRegisters
  RTS
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
.exportzp player_x, player_y

.segment "CHR"
.incbin "assets/space.chr"

.segment "RODATA"
palletes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $2d, $10, $15
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

sprites:
.byte $70, $05, $00, $80 ; 0 = Y position, 1 = TileID, 2 = Attribute, 3 = X position



; ASM Notes:
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