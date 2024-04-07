.include "constants.inc"
.include "header.inc"

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  RTI
.endproc

.import reset_handler

; .proc reset_handler
;   SEI
;   CLD
;   LDX #$40
;   STX $4017
;   LDX #$FF
;   TXS
;   INX
;   STX $2000
;   STX $2001
;   STX $4010
;   BIT $2002
; vblankwait:
;   BIT $2002
;   BPL vblankwait
; vblankwait2:
;   BIT $2002
;   BPL vblankwait2
;   JMP main
; .endproc
.export main
.proc main
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
  LDA #$29
  STA PPUDATA
  LDA #%00011110
  STA PPUMASK
forever:
  JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.res 8192
