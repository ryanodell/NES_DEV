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
  CPX #$04            ;CPX does subtraction to check if x is 4
  BNE load_palletes   ;Zero flag set when x is 4

  LDA #%00011110
  STA PPUMASK
forever:
  JMP forever
.endproc

.proc nmi_handler
  RTI
.endproc

.proc irq_handler
  RTI
.endproc

; Just reserve it for now
.segment "CHR"
.res 8192

.segment "RODATA"
palletes:
  .byte $29, $19, $09, $0f