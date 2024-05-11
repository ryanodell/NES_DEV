.include "include/constants.inc"
.export ppu_clear_oam

.proc ppu_clear_oam
  LDX #$00
  LDA #$FF
clear_oam:          ;Set the sprite's Y location off screen
  STA $0200,X
  INX
  INX
  INX
  INX
  BNE clear_oam
  RTS
.endproc