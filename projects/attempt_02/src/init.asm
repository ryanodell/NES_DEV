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
vblank1:
  BIT PPUSTATUS     ;Takes 1 full frame for PPU to become stable
  BPL vblank1

  CLD               ;Clear decimal mode because NES was trying to be cheap :D

;TODO: Clear OAM
;TODO: Clear ZP
vblank2:
  BIT PPUSTATUS     ;After second vblank, PPU is stable, ready to rock and roll
  BPL vblank2

  JMP main
.endproc