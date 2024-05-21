.include "include/constants.inc"
.include "include/header.inc"

.import reset_handler, draw_objects, draw_starfield, read_controller1, process_enemies, draw_enemy

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CODE"
.export main
.proc main
  LDA #239            ; NES can only show up to pixel 239 vertically (0 to 239)
  STA scroll          ; Set the scroll position to 239

  LDX #$3F            ; Pallete data starts at $3F00
  STX PPUADDR         ; Set the high byte of the PPU address to 3F
  LDX #$00
  STX PPUADDR         ; Set the low byte of the PPU address to 00

load_palletes:
  LDA palletes, X     ; Load the palette data from the address palletes + X
  STA PPUDATA         ; Write the palette data to the PPU
  INX                 ; Increment X to move to the next palette entry
  CPX #$10            ; Compare X to 16 (decimal)
  BNE load_palletes   ; If X is not 16, loop to load the next palette entry

  LDX #$20            ; Set X to 32 (hex 20)
  JSR draw_starfield  ; Draw the starfield at position 32

  LDX #$28            ; Set X to 40 (hex 28)
  JSR draw_starfield  ; Draw the starfield at position 40

  JSR draw_objects    ; Draw other game objects

  LDA #$00               ; Load 0 into the accumulator
  STA current_enemy      ; Initialize current_enemy to 0
  STA current_enemy_type ; Initialize current_enemy_type to 0

turtle_data:
  LDA #$00               ; Load 0 into the accumulator (Turtle type is 0)
  STA enemy_flags, X     ; Store 0 in enemy_flags at the position indicated by X
  LDA #$01               ; Load 1 into the accumulator (Turtle's Y velocity)
  STA enemy_y_vels, X    ; Store 1 in enemy_y_vels at the position indicated by X
  INX                    ; Increment X register
  CPX #$03               ; Compare X with 3
  BNE turtle_data        ; If X is not 3, repeat the loop (setup for 3 turtles)
  ; At this point, X is now 3

snake_data:
  LDA #$01               ; Load 1 into the accumulator (Snake type is 1)
  STA enemy_flags, X     ; Store 1 in enemy_flags at the position indicated by X
  LDA #$02               ; Load 2 into the accumulator (Snake's Y velocity)
  STA enemy_y_vels, X    ; Store 2 in enemy_y_vels at the position indicated by X
  INX                    ; Increment X register
  CPX #$05               ; Compare X with 5
  BNE snake_data         ; If X is not 5, repeat the loop (setup for 2 snakes)
  ; At this point, X is now 5

  LDX #$00               ; Initialize X register to 0
  LDA #$10               ; Load 16 into the accumulator (initial X position for enemies)
setup_enemy_x:
  STA enemy_x_pos, X     ; Store 16 in enemy_x_pos at the position indicated by X
  CLC                    ; Clear the carry flag before addition
  ADC #$20               ; Add 32 to the accumulator (next enemy's X position)
  INX                    ; Increment X register
  CPX #NUM_ENEMIES       ; Compare X with NUM_ENEMIES (total number of enemies)
  BNE setup_enemy_x      ; If X is not equal to NUM_ENEMIES, repeat the loop

  LDA #%10010000      ; Enable NMIs, set sprite pattern table
  STA ppuctrl_settings; Store the PPU control settings
  STA PPUCTRL         ; Write the PPU control settings to the PPU

  LDA #%00011110      ; Enable rendering (turn on screen)
  STA PPUMASK         ; Write the mask settings to the PPU

mainLoop:
  JSR read_controller1      ; Read controller input
  JSR update_player_input   ; Update player based on controller input
  ;JSR update_player_back_and_forth ; Optional routine for player movement
  JSR draw_player           ; Draw the player sprite

  JSR process_enemies       ; Self explanitory
	
  ; Draw all enemies
	LDA #$00
	STA current_enemy
enemy_drawing:
	JSR draw_enemy
	INC current_enemy
	LDA current_enemy
	CMP #NUM_ENEMIES
	BNE enemy_drawing

  LDA scroll                ; Load the current scroll value
  BNE update_scroll         ; If scroll is not zero, update the scroll positions

  LDA ppuctrl_settings      ; Load the PPU control settings
  EOR #%00000010            ; Toggle the name table select bit
  STA ppuctrl_settings      ; Store the modified settings
  ;STA PPUCTRL               ; Uncomment to apply the changes to the PPU
  LDA #240                  ; Reset the scroll value to 240
  STA scroll                ; Update the scroll variable

update_scroll:
  DEC scroll                ; Decrement the scroll value
  INC sleeping              ; Increment the sleeping variable

sleep:
  LDA sleeping              ; Load the sleeping variable
  BNE sleep                 ; Loop until sleeping is zero
  JMP mainLoop              ; Loop back to the start of the main loop

.endproc

.proc nmi_handler           ; Non-Maskable Interrupt (NMI) handler
  LDA #$00                  ; Reset the sprite memory address to the start
  STA OAMADDR               ; Set OAMADDR to 0

  LDA #$02                  ; DMA transfer from page $0200
  STA OAMDMA                ; Start the DMA transfer

  LDA ppuctrl_settings      ; Load the PPU control settings
  STA PPUCTRL               ; Restore the PPU control settings

  ; Set scroll values
  LDA #$00                  ; X scroll
  STA PPUSCROLL             ; Write X scroll to PPUSCROLL
  LDA scroll                ; Y scroll
  STA PPUSCROLL             ; Write Y scroll to PPUSCROLL

  LDA #$00                  ; Reset sleeping to 0
  STA sleeping
  RTI                       ; Return from interrupt
.endproc

.proc irq_handler           ; IRQ handler (unused)
  RTI
.endproc

.proc update_player_back_and_forth
  SaveRegisters            ; Save CPU registers

  LDA player_x             ; Load player X position
  CMP #$E0                 ; Compare with 224
  BCC not_at_right_edge    ; If player_x < 224, branch
  LDA #$00                 ; Otherwise, set direction to left
  STA player_dir           ; Store direction
  JMP direction_set        ; Jump to direction_set

not_at_right_edge:
  LDA player_x             ; Load player X position
  CMP #$10                 ; Compare with 16
  BCS direction_set        ; If player_x >= 16, branch
  LDA #$01                 ; Otherwise, set direction to right
  STA player_dir           ; Store direction

direction_set:
  LDA player_dir           ; Load player direction
  CMP #$01                 ; Compare with 1
  BEQ move_right           ; If direction is right, branch

  DEC player_x             ; Otherwise, move left
  JMP exit_subroutine      ; Jump to exit_subroutine

move_right:
  INC player_x             ; Move right

exit_subroutine:
  RestoreRegisters         ; Restore CPU registers
  RTS                      ; Return from subroutine
.endproc

.proc update_player_input  ; Update player input
  SaveRegisters            ; Save CPU registers

  LDA pad1                 ; Load controller input
  AND #BTN_LEFT            ; Check if Left is pressed
  BEQ check_right          ; If not, branch
  DEC player_x             ; Move left if pressed

check_right:
  LDA pad1                 ; Load controller input
  AND #BTN_RIGHT           ; Check if Right is pressed
  BEQ check_up             ; If not, branch
  INC player_x             ; Move right if pressed

check_up:
  LDA pad1                 ; Load controller input
  AND #BTN_UP              ; Check if Up is pressed
  BEQ check_down           ; If not, branch
  DEC player_y             ; Move up if pressed

check_down:
  LDA pad1                 ; Load controller input
  AND #BTN_DOWN            ; Check if Down is pressed
  BEQ done_checking        ; If not, branch
  INC player_y             ; Move down if pressed

done_checking:
  RestoreRegisters         ; Restore CPU registers
.endproc

.proc draw_player          ; Draw player sprite
  SaveRegisters            ; Save CPU registers

  ; Write player ship tile numbers
  LDA #$05
  STA $0201                ; Set tile ID for sprite 1
  LDA #$06
  STA $0205                ; Set tile ID for sprite 2
  LDA #$07
  STA $0209                ; Set tile ID for sprite 3
  LDA #$08
  STA $020D                ; Set tile ID for sprite 4

  ; Write player ship tile attributes (palette 0)
  LDA #$00
  STA $0202                ; Set attribute for tile 1
  STA $0206                ; Set attribute for tile 2
  STA $020A                ; Set attribute for tile 3
  STA $020E                ; Set attribute for tile 4

  ; Set sprite positions
  LDA player_y
  STA $0200                ; Set Y position for sprite 1
  LDA player_x
  STA $0203                ; Set X position for sprite 1

  LDA player_y
  STA $0204                ; Set Y position for sprite 2
  LDA player_x
  CLC                      ; Clear carry flag before addition
  ADC #$08                 ; Add 8 to player_x for sprite 2 X position
  STA $0207

  LDA player_y
  CLC
  ADC #$08                 ; Add 8 to player_y for sprite 3 Y position
  STA $0208
  LDA player_x
  STA $020B                ; Set X position for sprite 3

  LDA player_y
  CLC
  ADC #$08                 ; Add 8 to player_y for sprite 4 Y position
  STA $020C
  LDA player_x
  CLC
  ADC #$08                 ; Add 8 to player_x for sprite 4 X position
  STA $020F

  RestoreRegisters         ; Restore CPU registers
  RTS                      ; Return from subroutine
.endproc

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
sleeping: .res 1

; Entity pools:
enemy_x_pos: .res NUM_ENEMIES
enemy_y_pos: .res NUM_ENEMIES
enemy_x_vels: .res NUM_ENEMIES
enemy_y_vels: .res NUM_ENEMIES
enemy_flags: .res NUM_ENEMIES

;
current_enemy: .res 1
current_enemy_type: .res 1
enemy_timer: .res 1

; Bullet pools:
bullet_xs: .res 3
bullet_ys: .res 3


.exportzp player_x, player_y, pad1
.exportzp enemy_x_pos, enemy_y_pos, enemy_x_vels, enemy_y_vels, enemy_flags, current_enemy, current_enemy_type, enemy_timer

.segment "CHR"
.incbin "assets/space.chr"

.segment "RODATA"
palletes:
.byte $0F, $00, $10, $30
.byte $0F, $0C, $21, $32
.byte $0F, $05, $16, $27
.byte $0F, $0B, $1A, $29
.byte $0F, $00, $10, $30
.byte $0F, $0C, $21, $32
.byte $0F, $05, $16, $27
.byte $0F, $0B, $1A, $29

; ASM Notes:
; CMP is A register MINUS the value after CMP
; For example: LDA #$05 CMP #$09  is 5 - 9 and carry flag would be set for BCC

; https://famicom.party/book/11-branchingandloops/
; BEQ (“Branch if Equals zero”) 
; BNE (“Branch if Not Equals zero”)
; BCS (“Branch if Carry Set”)
; BCC (“Branch if Carry Cleared”) 

; Making Comparisons
; While the loops we have seen so far are useful, they require some careful setup. 
; The loops above rely on our loop counter becoming zero in order to end the loop. To make more flexible and 
; powerful loops, we need the ability to make arbitrary comparisons. In 6502 assembly, the opcodes that let us 
; do that are CMP, “Compare (with accumulator)“, CPX, “Compare with X register”, and CPY, “Compare with Y register”.

; Each of these opcodes works by performing a subtraction, setting the zero and carry flags as appropriate,
; and then discarding the result of the subtraction. Remember that when we perform a subtraction, we first set 
; the carry flag. This means that we have three possible outcomes from a comparison, based on the register value 
; and the value we are comparing it to:

; Register is larger than comparison value: Carry flag set, zero flag clear
; Register is equal to comparison value: Carry flag set, zero flag set
; Register is smaller than comparison value: Carry flag clear, zero flag clear
