.include "include/constants.inc"
.include "include/header.inc"

.segment "CODE"
.import reset_handler

.proc irq_handler
    RTI
.endproc

.proc nmi_handler
  RTI
.endproc

.export main
.proc main
  LDX $2002
  LDX #$3f
  STX $2006
  LDX #$00
  STX $2006
  LDA #$29
  STA $2007
  LDA #%00011110
  STA $2001
forever:
  JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.res 8192