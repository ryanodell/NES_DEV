.include "constants.inc"
.include "header.inc"

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00
  JSR read_controller1

  ; update tiles *after* DMA transfer
  JSR update_player
  JSR draw_player

  LDA scroll
  CMP #$00 ; did we scroll to the end of a nametable?
  BNE set_scroll_positions
  ; if yes,
  ; update base nametable
  LDA ppuctrl_settings
  EOR #%00000010 ; flip bit #1 to its opposite
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #240
  STA scroll

set_scroll_positions:
  LDA #$00 ; X scroll first
  STA PPUSCROLL
  DEC scroll
  LDA scroll ; then Y scroll
  STA PPUSCROLL

  RTI
.endproc

.import reset_handler

.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed
  DEC player_x  ; If the branch is not taken, move player left
check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up
  INC player_x
check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down
  DEC player_y
check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking
  INC player_y
done_checking:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

;DO NOT REMOVE THIS, THIS IS A GOOD EXAMPLE FOR BOUND CHECKING
; .proc update_player
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA

;   LDA player_x
;   CMP #$e0
;   BCC not_at_right_edge
;   ; if BCC is not taken, we are greater than $e0
;   LDA #$00
;   STA player_dir    ; start moving left
;   JMP direction_set ; we already chose a direction,
;                     ; so we can skip the left side check
; not_at_right_edge:
;   LDA player_x
;   CMP #$10
;   BCS direction_set
;   ; if BCS not taken, we are less than $10
;   LDA #$01
;   STA player_dir   ; start moving right
; direction_set:
;   ; now, actually update player_x
;   LDA player_dir
;   CMP #$01
;   BEQ move_right
;   ; if player_dir minus $01 is not zero,
;   ; that means player_dir was $00 and
;   ; we need to move left
;   DEC player_x
;   JMP exit_subroutine
; move_right:
;   INC player_x
; exit_subroutine:
;   ; all done, clean up and return
;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP
;   RTS
; .endproc

.proc draw_player
  ;Save the registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  ; write player ship tile numbers
  LDA #$05
  STA $0201
  LDA #$06
  STA $0205
  LDA #$07
  STA $0209
  LDA #$08
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.import draw_starfield

.export main
.proc main
  LDA #239   ; Y is only 240 lines tall!
  STA scroll
  ;Maybe
  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL

  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palletes:
  LDA palettes, X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palletes
; write nametables
  LDX #$20
  JSR draw_starfield

  LDX #$28
  JSR draw_starfield

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK
forever:
  JMP forever
.endproc

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
.exportzp player_x, player_y, pad1

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $2d, $10, $15
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
sprites:
.byte $70, $05, $00, $80
.byte $70, $06, $00, $88
.byte $78, $07, $00, $80
.byte $78, $08, $00, $88

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "starfield.chr"
