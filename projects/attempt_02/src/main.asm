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
  ;LDX PPUSTATUS      ;Pretty sure this was never needed. Keep just in case
  LDX #$3f            ;Pallete data starts at $3f00
  STX PPUADDR         ;Set the high bit 3f
  LDX #$00            
  STX PPUADDR         ;Set the low bit 00

  LDA #$29            ;Now that we have set the address, we can set the PPU data
  STA PPUDATA         ;$29 for the bright green. Updating to loop soon though

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