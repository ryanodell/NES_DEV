.include "include/constants.inc"

.segment "CODE"


.import main
.export reset_handler
.proc reset_handler
  SEI               ;Disable Interupts
  LDX #$00
  STX PPUCTRL       ;Disable NMI
  STX PPUMASK       ;Disable rendering
  STX $4010         ;Disable DMC IRQ
  DEX               ;Set X = FF for initializing the stack pointer
  TXS               ;Transfer X(FF) to init the stack pointer to $01FF
  BIT PPUSTATUS     ;Acknowledge stray vblank NMI across reset ($2002)
  BIT SNDCHN        ;Acknowledge DMC IRQ
  LDA #$40
  STA CONTROLLER2   ;Disable APU frame IRQ CONTROLLER2 is also $4017
  LDA #$05
  STA SNDCHN        ;Disable DMC Playback, init other channels
  VblankWait        ;Takes 1 full frame for PPU to become stable
  CLD               ;Clear decimal mode because NES was trying to be cheap :D

  LDX #$00
  LDA #$FF
clear_oam:          ;Set the sprite's Y location off screen
  STA $0200,X
  INX
  INX
  INX
  INX
  BNE clear_oam
;TODO: Clear ZP
  VblankWait          ;After second vblank, PPU is stable, ready to rock and roll

  JMP main
.endproc


;Keep for reference:
;ca65 --listing out.lst init.asm