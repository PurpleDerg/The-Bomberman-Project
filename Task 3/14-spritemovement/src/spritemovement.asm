.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
frame_data: .res 1 
frame_buffer: .res 1
buttons1: .res 1
.exportzp player_x, player_y, frame_data

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

  ; update tiles *after* DMA transfer
	
  JSR update_frame
  JSR update_player
  JSR draw_player
  ; JSR draw_player_left
  ; JSR draw_player_down
  ; JSR draw_player_up
  ; JSR draw_player_right
  
  
  jsr ReadController
  jsr input_move
  
  
  

	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler

.export main
.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

	; write nametables
	; big stars first
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$6b
	STA PPUADDR
	LDX #$2f
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$57
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$23
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$52
	STA PPUADDR
	STX PPUDATA

	; next, small star 1
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$74
	STA PPUADDR
	LDX #$2d
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$43
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$5d
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$73
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$2f
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$f7
	STA PPUADDR
	STX PPUDATA

	; finally, small star 2
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$f1
	STA PPUADDR
	LDX #$2e
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$a8
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$7a
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$44
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$7c
	STA PPUADDR
	STX PPUDATA

	; finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c2
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
	STA PPUDATA

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10001000  ; turn on NMIs, sprites use first pattern table 
                  ; SPRITE PATTERN TABLE CHANGE BIT 3 -> 1, AND BACKGROUND PATTERN TABLE BIT 4 -> 0. 
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc update_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

;    LDA player_x
;    CMP #$e0
;    BCC not_at_right_edge
;    ; if BCC is not taken, we are greater than $e0
;    LDA #$00
;    STA player_dir    ; start moving left
;    JMP direction_set ; we already chose a direction, so we can skip the left side check
;  not_at_right_edge:
;    LDA player_x
;    CMP #$10
;    BCS direction_set   ; if BCS not taken, we are less than $10
;    LDA #$01
;    STA player_dir   ; start moving right
;  direction_set:
;    ; now, actually update player_x
;    LDA player_dir
;    CMP #$01
;    BEQ move_right
;    ; if player_dir minus $01 is not zero,
;    ; that means player_dir was $00 and
;    ; we need to move left
;    DEC player_x
;    JMP exit_subroutine
;  move_right:
;    INC player_x
;  exit_subroutine:
;   ;all done, clean up and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

;animations 
.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player tile numbers
  start_anim: 
  LDA #$08 ;frame data 
  STA $0201
  LDA #$09 ;frame data +1
  STA $0205
  LDA #$18 ;frame data +$10
  STA $0209
  LDA #$19 ;frame data +$11
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

  
  ; JSR animation
  


  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc
.proc draw_player_left
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player tile numbers
  start_anim: 
  LDA frame_data ;frame data holds the current base address of the tile 
  STA $0201
  LDA frame_data ;frame data +1
  CLC
  ADC #$01
  STA $0205
  LDA frame_data ;frame data +$10
  CLC
  ADC #$10
  STA $0209
  LDA frame_data ;frame data +$11
  CLC
  ADC #$11
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

  
  ; JSR animation
  


  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_down
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player tile numbers
  start_anim: 
  LDA frame_data ;frame data 
  CLC 
  ADC #$06
  STA $0201
  LDA frame_data ;frame data +1
  CLC
  ADC #$07
  STA $0205
  LDA frame_data ;frame data +$10
  CLC
  ADC #$16
  STA $0209
  LDA frame_data ;frame data +$11
  CLC
  ADC #$17
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

  
  ; JSR animation
  


  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc


.proc draw_player_up
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player tile numbers
  start_anim: 
  LDA frame_data ;frame data 
  CLC
  ADC #$26
  STA $0201
  LDA frame_data ;frame data +1
  CLC
  ADC #$27
  STA $0205
  LDA frame_data ;frame data +$10
  CLC
  ADC #$36
  STA $0209
  LDA frame_data ;frame data +$11
  CLC
  ADC #$37
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

  
  ; JSR animation
  


  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc


.proc draw_player_right
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player tile numbers
  start_anim: 
  LDA frame_data ;frame data 
  CLC
  ADC #$20
  STA $0201
  
  LDA frame_data ;frame data +1
  CLC
  ADC #$21
  STA $0205
  LDA frame_data ;frame data +$10
  CLC
  ADC #$30
  STA $0209
  LDA frame_data ;frame data +$11
  CLC
  ADC #$31
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

  
  ; JSR animation
  


  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

 

.proc update_frame
; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  INC frame_buffer

  LDA frame_buffer
  CMP #$06 ;nmi is called 60fps
  BEQ next_frame
  JMP exit

  next_frame:
  ;increase frame data by 2 
    INC frame_data
    INC frame_data


    ;reset frame_buffer
    LDA frame_data ;current frame
    CMP #$06  ;THIS IS HARDCODED IN. This represents the tile at which it needs to stop
    BEQ reset_frame
    LDA #$00
    STA frame_buffer
    JMP exit
  reset_frame:
    LDA #$00
    STA frame_data
    STA frame_buffer
    

    ; restore registers and return
  exit:
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc 

.proc ReadController
; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA


  LDA #$01
  STA $4016 ; set to data collection mode 
  LDA #$00
  STA $4016 ; set to read data mode
  LDX #$08 ; Loop 8 times
ReadControllerLoop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX              ; If the result is 0, the Z flag is cleared 
  BNE ReadControllerLoop ;Branch if X reaches 0
  

    ; restore registers and return
  exit:
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc 

.proc input_move
; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ReadUp: 
  LDA buttons1       
  AND #%00001000   ; And raises Z = 1 if they're not equal to the word in buttons1. 
  BEQ ReadUpDone   ; branch to ReadupDone if button is NOT pressed (0)
  DEC player_y
  JSR draw_player_up                     
  ReadUpDone:

  ReadDown: 
  LDA buttons1       
  AND #%00000100 
  BEQ ReadDownDone   ; branch to ReadDownDone if button is NOT pressed (0)
  INC player_y
  JSR draw_player_down                         
  ReadDownDone:

  ReadLeft: 
  LDA buttons1       
  AND #%00000010 
  BEQ ReadLeftDone   ; branch to ReadLeftDone if button is NOT pressed (0)
  DEC player_x
  JSR draw_player_left                        
  ReadLeftDone:

  ReadRight: 
  LDA buttons1       
  AND #%00000001 
  BEQ ReadRightDone   ; branch to ReadRightDone if button is NOT pressed (0)
  INC player_x
  JSR draw_player_right                        
  ReadRightDone:

    ; restore registers and return
  exit:
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc 

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $20, $27, $12
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "starfield1.chr"
.segment "BG"
.incbin "maptest.nam"
