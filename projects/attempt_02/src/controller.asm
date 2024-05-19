.include "include/constants.inc"  ; Include a file containing constant definitions

.segment "ZEROPAGE"  ; Define the start of the zero page segment
.importzp pad1       ; Import the zero page variable pad1

.segment "CODE"
.export read_controller1  ; Export the read_controller1 procedure to make it accessible from other modules

.proc read_controller1  ; Begin the read_controller1 procedure
  SaveRegisters          ; Save the state of the CPU registers (implementation dependent)
  
  LDA #$01
  STA CONTROLLER1        ; Write 1 to CONTROLLER1 to prepare for latching the button states

  LDA #$00
  STA CONTROLLER1        ; Write 0 to CONTROLLER1 to latch the button states

  LDA #%00000001         ; Load the binary value 00000001 into the accumulator
  STA pad1               ; Store this value in the zero page variable pad1

get_buttons:
  LDA CONTROLLER1        ; Load the state of the next button from CONTROLLER1 into the accumulator
  LSR A                  ; Logical Shift Right: shift the button state right by 1 bit, placing the least significant bit into the carry flag
  ROL pad1               ; Rotate Left through Carry: rotate the value in pad1 left by 1 bit, incorporating the carry flag into bit 0 of pad1

  BCC get_buttons        ; Branch to get_buttons if the carry flag is clear (this loops until the original '1' from pad1 is rotated out)

  RestoreRegisters       ; Restore the state of the CPU registers (implementation dependent)

  RTS
.endproc
