;Bring in includes
.include "include/constants.inc"
.include "include/header.inc"
;Not needed I think?
;.segment "STARTUP"

;Import from other objects
.import reset_handler

;Set the vectors
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
  LDA palletes, x     ;x register is 0 and reads from pallete
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

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00
	STA $2005
	STA $2005
  RTI
.endproc

.proc irq_handler
  RTI
.endproc


.segment "CHR"
.incbin "assets/space.chr"
; .res 8192

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
  ; .byte $29, $19, $09, $0f