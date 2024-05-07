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
.proc main:

.endproc

.proc nmi_handler:
  RTI
.endproc

.proc irq_handler
  RTI
.endproc