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

  ;Time to writes some sprite data :D
;   LDX #$00            ;Start our loop @ 0
; load_sprites:
;   LDA sprites,X       ;Load in this order: Y, TileID, Attrib table, X
;   STA $0200,X
;   INX
;   CPX #$04            ;Only 4 bytes in sprites
;   BNE load_sprites

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

  JSR draw_player
	STA $2005
	STA $2005
  RTI
.endproc

.proc irq_handler
  RTI
.endproc

.proc draw_player
  SaveRegisters
  
  ; write player ship tile numbers
  LDA #$05
  STA $0201
  LDA #$06
  STA $0205
  LDA #$07
  STA $0209
  LDA #$08
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ;positions?
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203
  
  RestoreRegisters

  RTS
.endproc

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
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