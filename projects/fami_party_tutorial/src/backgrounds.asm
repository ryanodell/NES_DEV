.include "constants.inc"

.segment "CODE"

.export draw_starfield
.proc draw_starfield
  ; X register stores high byte of nametable
  ; write nametables
  ; big stars first
  LDA PPUSTATUS
  TXA
  STA PPUADDR
  LDA #$6b
  STA PPUADDR
  LDY #$2f
  STY PPUDATA

  LDA PPUSTATUS
  TXA
  ADC #$01
  STA PPUADDR
  LDA #$57
  STA PPUADDR
  STY PPUDATA

; ...and much more, see the file for full listing

  ; finally, attribute table
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$c2
  STA PPUADDR
  LDA #%01000000
  STA PPUDATA

  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$e0
  STA PPUADDR
  LDA #%00001100
  STA PPUDATA

  RTS
.endproc

.export draw_objects
.proc draw_objects
  ; Draw objects on top of the starfield,
  ; and update attribute tables

  ; new additions: galaxy and planet
  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$90
  STA PPUADDR
  LDX #$30
  STX PPUDATA
  LDX #$31
  STX PPUDATA

  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$b0
  STA PPUADDR
  LDX #$32
  STX PPUDATA
  LDX #$33
  STX PPUDATA

; ...and more, not listed here

  ; finally, attribute tables
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$dc
  STA PPUADDR
  LDA #%00000001
  STA PPUDATA

  LDA PPUSTATUS
  LDA #$2b
  STA PPUADDR
  LDA #$ca
  STA PPUADDR
  LDA #%10100000
  STA PPUDATA

  LDA PPUSTATUS
  LDA #$2b
  STA PPUADDR
  LDA #$d2
  STA PPUADDR
  LDA #%00001010
  STA PPUDATA

  RTS
.endproc