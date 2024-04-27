.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1 ;$00
player_y: .res 1 ;$01
absoluteX: .res 1 ;$02
frame_data: .res 1 ;$03
frame_buffer: .res 1 ;$04
scroll: .res 1  ;$05
buttons1: .res 1 ;$06
Myb: .res 1 ;$07
Mxb: .res 1 ;$08
NTBH_index: .res 1 ;$09
NTBL_index: .res 1 ;$0A
maplevel: .res 1 ;$0B
Namoffset: .res 1 ;THIS ONLY WORKS BY FIXING MIRRORING VERTICAL ;$0C
collisionX: .res 1 ;$0D
collisionY: .res 1 ;$0E
  ; L_bit = $0000
  ; H_bit = $0001
level: .res 1 ;$0F
NTflag: .res 1 ;$10
currentlvl: .res 1 ;$11
supetileX: .res 1 ; $12
MegaXb: .res 1 ;$13 
player_dir: .res 1 ;14$ 
absoverflow: .res 1 ;$15
iswalkable: .res 1 ;$16
.exportzp player_x, player_y, frame_data, level

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
  jsr scrolldone
  JSR pxlclsionset
  jsr getlevel
  JSR checkcollision
  
  
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

LDX #$00  
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

	; write nametables
  ; LDA PPUSTATUS
  ; LDA #$20
  ; STA PPUADDR
  ; LDA #$00
  ; STA PPUADDR


  LDA NTflag
  CMP #$00
  BEQ stage1


  CMP #$01
  BEQ stage2

  JMP continue
  
  stage1: 
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDA #$00   ;EVERYTIME THAT YOU WANT TO LOAD A BACKGROUND, YOU HAVE TO CLEAN UP PPUCTRL AND PPUMASK
    STA PPUCTRL
    STA PPUMASK
    JSR loadstage1
    LDA #%10001000
    STA PPUCTRL   ;SETUP VALUES OF THE PPUCTRL

    LDA #%00011110  ; turn on screen AGAIN
    STA PPUMASK
    JMP continue

  stage2:
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDA #$00   ;EVERYTIME THAT YOU WANT TO LOAD A BACKGROUND, YOU HAVE TO CLEAN UP PPUCTRL AND PPUMASK
    STA PPUCTRL
    STA PPUMASK
    JSR loadstage2
    LDA #%10001000
    STA PPUCTRL   ;SETUP VALUES OF THE PPUCTRL

    LDA #%00011110  ; turn on screen AGAIN
    STA PPUMASK

  continue: 



 


  




  

;   LDA #<bg_nam
;   STA L_bit
;   LDA #>bg_nam
;   STA H_bit

;   LDX #$00
;   LDY #$00

; namloop:
;   LDA ($00), Y 
;   STA PPUDATA
;   INY 
;   CPY #$00
;   BNE namloop
;   INC H_bit
;   INX
;   CPX #$04
;   BNE namloop
; ;Background color setup
; LDA $2002x
; LDA #$3F
; STA $2006
; LDA #$00
; STA $2006
; LDX #$00



	

	;finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$d8
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$23
	; STA PPUADDR
	; LDA #$e0
	; STA PPUADDR
	; LDA #%00001100
	; STA PPUDATA

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

.proc checkcollision
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDX collisionX ;load current player x and y positions into X and Y registers
  LDY collisionY

  ;---------LOGIC TO CHOSE WHICH NAMETABLE TO LOOK INTO COLLISIONS-------------------

  TXA ; do the math if it's nametable 0 or nametable 1 check with player X coordinate
  CLC 
  ADC scroll ;Do the math for absoluteX, if that sets the carryflag, then set absoverflow's last bit to 1 
  BCS setflag ; if C == 1, then branch
  LDA absoverflow 
  AND #%00000000   ;Using an OR let's us specify which bit we want to turn on or off in a byte, useful for checking T or F flags
  STA absoverflow
  JMP continue

  setflag:
    LDA absoverflow
    ORA #%00000001 ;set last bit to 1 
    STA absoverflow

continue:

  LDA NTflag ;Forgot I already had a flag that determines the current stage. So just check which stage is currently loaded
  CMP #$01 ; 1 = stage 2, 0 = stage 1
  BEQ checkstage2 

  LDA absoverflow  ; #%00000001, if you AND this and it's the same, then Z = 0, meaning that you want to branch if Z = 1
  AND #%000000001 ;If last bit is 1, then check for nt1, otherwise, check for nametable 0 
  BNE NT1
  JSR colmap0
  JMP end


  NT1:
    JSR colmap1
    JMP end


  checkstage2:
    LDA absoverflow
    AND #%00000001 ;If last bit is 1, then check for nt1, otherwise, check for nametable 0
    BNE NT3
    JSR colmap2
    JMP end
  NT3:
    JSR colmap3
    JMP end

  
  end: 

  
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc colmap0  
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  
  LDY currentlvl
  LDA supetileX  ;CHECK IF IT'S DOING MOD 4 correctly 
  AND #%00000011
  STA supetileX

  LDA nametable0, Y ;Check the current level of player 
  LDX #$00
startloop: 
  CPX supetileX
  BEQ docheck

  ASL ;keep looping until you reach the two bits that the collision pixel is in. 
  ASL
  INX
  JMP startloop

docheck:
    ;---------KEEP IN MIND THAT REG A HAS THE SHIFTED LEVEL ACCORDING TO THE CURRENT TILE OF PLAYER-------
    AND #%11000000 ;Check if it's a flower patch since flower = 11bin, If it's not, Z = 1
    CMP #%11000000
    BNE elsefloor
    LDX #$01
    STX iswalkable ;could be used in a bitmask in the overflowflag to be honest. too lazy, so time to abuse the zeropage.
    JMP end 

    elsefloor: 
      AND #%11000000
      CMP #%01000000
      BNE neither
      LDX #$01
      STX iswalkable
      JMP end

    neither:
      LDX #$00  ;If neither, make sure to indicate it's not walkable 
      STX iswalkable
      
  end:


  

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc

.proc colmap1  
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  LDY currentlvl
  LDA supetileX  ;CHECK IF IT'S DOING MOD 4 correctly 
  AND #%00000011
  STA supetileX

  LDA nametable1, Y ;Check the current level of player 
  LDX #$00
startloop: 
  CPX supetileX
  BEQ docheck

  ASL ;keep looping until you reach the two bits that the collision pixel is in. 
  ASL
  INX
  JMP startloop

docheck:
    ;---------KEEP IN MIND THAT REG A HAS THE SHIFTED LEVEL ACCORDING TO THE CURRENT TILE OF PLAYER-------
    AND #%11000000 ;Check if it's a flower patch since flower = 11bin, If it's not, Z = 1
    CMP #%11000000
    BNE elsefloor
    LDX #$01
    STX iswalkable ;could be used in a bitmask in the overflowflag to be honest. too lazy, so time to abuse the zeropage. 
    JMP end

    elsefloor: 
      AND #%11000000
      CMP #%01000000
      BNE neither
      LDX #$01
      STX iswalkable
      JMP end

    neither:
      LDX #$00  ;If neither, make sure to indicate it's not walkable 
      STX iswalkable
      
  end:

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc

.proc colmap2  
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDY currentlvl
  LDA supetileX  ;CHECK IF IT'S DOING MOD 4 correctly 
  AND #%00000011
  STA supetileX
  
  LDA nametable2, Y ;Check the current level of player 
  LDX #$00
startloop: 
  CPX supetileX
  BEQ docheck

  ASL ;keep looping until you reach the two bits that the collision pixel is in. 
  ASL
  INX
  JMP startloop

docheck:
    ;---------KEEP IN MIND THAT REG A HAS THE SHIFTED LEVEL ACCORDING TO THE CURRENT TILE OF PLAYER-------
    AND #%11000000 ;Check if it's a flower patch since flower = 11bin, If it's not, Z = 1
    CMP #%11000000
    BNE elsefloor
    LDX #$01
    STX iswalkable ;could be used in a bitmask in the overflowflag to be honest. too lazy, so time to abuse the zeropage. 
    JMP end

    elsefloor: 
      AND #%11000000
      CMP #%01000000
      BNE neither
      LDX #$01
      STX iswalkable
      JMP end

    neither:
      LDX #$00  ;If neither, make sure to indicate it's not walkable 
      STX iswalkable
      
  end:

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc

.proc colmap3  
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDY currentlvl
  LDA supetileX  ;CHECK IF IT'S DOING MOD 4 correctly 
  AND #%00000011
  STA supetileX

  LDA nametable3, Y ;Check the current level of player 
  LDX #$00
startloop: 
  CPX supetileX
  BEQ docheck

  ASL ;keep looping until you reach the two bits that the collision pixel is in. 
  ASL
  INX
  JMP startloop

docheck:
    ;---------KEEP IN MIND THAT REG A HAS THE SHIFTED LEVEL ACCORDING TO THE CURRENT TILE OF PLAYER-------
    AND #%11000000 ;Check if it's a flower patch since flower = 11bin, If it's not, Z = 1
    CMP #%11000000
    BNE elsefloor
    LDX #$01
    STX iswalkable ;could be used in a bitmask in the overflowflag to be honest. too lazy, so time to abuse the zeropage. 
    JMP end

    elsefloor: 
      AND #%11000000
      CMP #%01000000
      BNE neither
      LDX #$01
      STX iswalkable
      JMP end

    neither:
      LDX #$00  ;If neither, make sure to indicate it's not walkable 
      STX iswalkable
      
  end:

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc


.proc loadstage1
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

    LDX #$00
  load_Background0: 
    LDY #$20
    STY Namoffset
    STX level ;Current position of map 
    LDA nametable0, x
    STA maplevel ; What's currently going to be printed 
    
    JSR Decode ;Returns DECODED HighBit AND LOBit of nametable address based on LEVEL
    JSR printSupertile ;Prints the LEVEL tiles
    INX 
    CPX #$3c ;Total bytes to load
    BNE load_Background0

  
  
    LDX #$00
    STX level
  load_Background1: 
    LDY #$24
    STY Namoffset
    STX level ;Current position of map 
    LDA nametable1, x
    STA maplevel ; What's currently going to be printed 
    
    JSR Decode ;Returns DECODED HighBit AND LOBit of nametable address based on LEVEL
    JSR printSupertile ;Prints the LEVEL tiles
    INX 
    CPX #$3c ;Total bytes to load
    BNE load_Background1


  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc

.proc loadstage2
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

    LDX #$00
  load_Background2: 
    LDY #$20
    STY Namoffset
    STX level ;Current position of map 
    LDA nametable2, x
    STA maplevel ; What's currently going to be printed 
    
    JSR Decode ;Returns DECODED HighBit AND LOBit of nametable address based on LEVEL
    JSR printSupertile ;Prints the LEVEL tiles
    INX 
    CPX #$3c ;Total bytes to load
    BNE load_Background2

  
  
    LDX #$00
    STX level
  load_Background3: 
    LDY #$24
    STY Namoffset
    STX level ;Current position of map 
    LDA nametable3, x
    STA maplevel ; What's currently going to be printed 
    
    JSR Decode ;Returns DECODED HighBit AND LOBit of nametable address based on LEVEL
    JSR printSupertile ;Prints the LEVEL tiles
    INX 
    CPX #$3c ;Total bytes to load
    BNE load_Background3


  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc

.proc pxlclsionset
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

    LDA player_dir
    AND #%00000001 ;check if the player direction is right
    BEQ ifelseleft ;If false, go to the else statement
    LDY player_y  
    STY collisionY
    LDA player_x
    CLC 
    ADC #$10
    STA collisionX

  ifelseleft: 
    LDA player_dir
    AND #%00000010 ;check if the player direction is left
    BEQ ifelsedown ;If false, go to the else statement
    LDY player_y
    STY collisionY
    LDA player_x
    CLC 
    SBC #$01
    STA collisionX
  
  ifelsedown: 
    LDA player_dir
    AND #%00000100 ;check if the player direction is down
    BEQ ifelseup ;If false, go to the else statement
    LDX player_x
    STX collisionX
    LDA player_y
    CLC 
    ADC #$10
    STA collisionY

  ifelseup:
    LDA player_dir
    AND #%00001000 ;check if the player direction is right
    BEQ end ;If false, go to the else statement
    LDX player_x
    STX collisionX
    LDA player_y
    CLC 
    SBC #$01
    STA collisionY
  
  end:



  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc getlevel 
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDX collisionX ;THIS is the collision pixel that will be determining the tile to check. 
  TXA
  CLC 
  ADC scroll
  STA absoluteX ;Store for testing 
  
      ; TXA ;Do math with player X
  LSR ; Divide X/16 to get SUPERtilespace for X 
  LSR 
  LSR 
  LSR ;We have the SuperTileSpace after dividing by 16
  STA supetileX ;REMEMBER MOD 4 to find which super tile you are in in a range of 0-3

  LSR
  LSR ; Now divide by 4 again to obtain Mxb  
  STA MegaXb ;store MXb 

  LDY collisionY ;THIS 
  TYA ; Mathing with player_y coord
  LSR ; Divide Y/16 to get SUPERtilespace for MYb
  LSR
  LSR
  LSR 
      ; Level = (Myb<<2)+Mxb
  ASL ;Myb is already in Accumulator, so let's Shift left 2 times
  ASL
  CLC 
  ADC MegaXb ;adding MXb
  STA currentlvl ; This is gonna store the final result for the level calculation it should be equal to current level
  

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc printSupertile
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
 
  LDX #$00 ;set i = 0
start:
  LDA maplevel ;MapLevel stores the 1 byte word that will be used to checked per iteration
  AND #%11000000
  CMP #%00000000
  BEQ Iron

  AND #%11000000
  CMP #%01000000
  BEQ Wall

  AND #%11000000
  CMP #%10000000
  BEQ Brick

  AND #%11000000
  CMP #%11000000
  BEQ Flower

  

  
  Iron: 
    JSR printIron   ; 00
    JMP loopend
          
  Wall:
    JSR printFloor   ; 01
    JMP loopend
  Brick:
    JSR printBrick  ;10
    JMP loopend
              
  Flower:           ; 11
    JSR printFlower 
    JMP loopend


loopend: 
  ASL maplevel
  ASL maplevel
  
  INX ;Increase iterator of loop

  INC NTBL_index
  INC NTBL_index

  CPX #$04 ;if i <=4, break 
  BNE start
  




  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS



.endproc

.proc printFloor
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA PPUSTATUS ;Sequence To print TopLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;Manage base address of nametable 0, $2000
  STA PPUADDR
  LDA NTBL_index
  STA PPUADDR
  LDX supertile + 7
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print TopRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;a
  STA PPUADDR
  LDA NTBL_index
  CLC
  ADC #$01 ;LoBit + 1
  STA PPUADDR
  LDX supertile + 7
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index 
  CLC 
  ADC #$20 ;32
  STA PPUADDR
  LDX supertile + 7
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index
  CLC
  ADC #$21 ; +33
  STA PPUADDR
  LDX supertile + 7
  STX PPUDATA

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc printBrick
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA PPUSTATUS ;Sequence To print TopLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;Manage base address of nametable 0, $2000
  STA PPUADDR
  LDA NTBL_index
  STA PPUADDR
  LDX supertile + 8
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print TopRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;a
  STA PPUADDR
  LDA NTBL_index 
  CLC 
  ADC #$01 ; Add 1
  STA PPUADDR
  LDX supertile + 9
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index  
  CLC 
  ADC #$20 ;ADD 32 Offset
  STA PPUADDR
  LDX supertile + 10
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index 
  CLC 
  ADC #$21 ;ADD 33
  STA PPUADDR
  LDX supertile + 11
  STX PPUDATA

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc printIron
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA PPUSTATUS ;Sequence To print TopLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;Manage base address of nametable 0, $2000
  STA PPUADDR
  LDA NTBL_index 
  STA PPUADDR
  LDX supertile 
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print TopRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;a
  STA PPUADDR
  LDA NTBL_index ;ADD 1 for offset
  CLC
  ADC #$01
  STA PPUADDR
  LDX supertile + 1
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index ;ADD 32 for offset
  CLC 
  ADC #$20
  STA PPUADDR
  LDX supertile + 2
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index ; ADD 33 for offset
  CLC 
  ADC #$21
  STA PPUADDR
  LDX supertile + 3
  STX PPUDATA

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc printFlower
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA PPUSTATUS ;Sequence To print TopLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;Manage base address of nametable 0, $2000
  STA PPUADDR
  LDA NTBL_index
  STA PPUADDR
  LDX supertile + 12
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print TopRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset ;a
  STA PPUADDR
  LDA NTBL_index ;Same as previous subroutines ADD 1
  CLC
  ADC #$01
  STA PPUADDR
  LDX supertile + 13
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomLeft tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index ;ADD 32 offset for nametable address, same as previous subs
  CLC 
  ADC #$20
  STA PPUADDR
  LDX supertile + 14
  STX PPUDATA

  LDA PPUSTATUS ;Sequence To print BottomRight tile 
  LDA NTBH_index
  CLC
  ADC Namoffset
  STA PPUADDR
  LDA NTBL_index ; ADD 33 
  CLC 
  ADC #$21
  STA PPUADDR
  LDX supertile + 15
  STX PPUDATA

 

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc



.proc Decode
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ;Decode START
decoding:
  LDA level ;MEGATILE INDEX 8 
  LSR A ;Shift MEGATILE Right /2, to calulate Myb
  LSR A 
  STA Myb ;Store Myb in memory 

  LDA level ; PUT MEGATILE INDEX into A for math
  AND #%00000011 ;Modulo 4 = Mindex&&0x03
  STA Mxb  ;Store Mxb in X 

  LDA Myb ;RESTORE Y in A for math 
  LSR A ;Shift 2 times right again
  LSR A 
  AND #%00000011 ;Do the the mask again for the 2
  STA NTBH_index ;save Highbyte for NAMETABLE address

  LDA Mxb ;RESTORE X in A for math for Mxb
  ASL A ;Shift left 3 times = A*8
  ASL A 
  ASL A 
  STA Mxb ;store updated value

  LDA Myb ;RESTORE Myb in A for Math
  ASL A ;Shift left 6 times = A*64
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A ;What we have in A is Myb
  CLC
  ADC Mxb
  STA NTBL_index ;store LOW BIT OF NAMETABLE ADRESS





  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
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
  STA player_dir
  JSR draw_player_up
  LDA iswalkable ;Check if it's a walkable tile
  AND #$01
  BEQ ReadUpDone  
  DEC player_y                  
  ReadUpDone:

  ReadDown: 
  LDA buttons1   
  AND #%00000100  ; And raises Z = 1 if they're not equal to the word in buttons1.
  BEQ ReadDownDone   ; branch to ReadDownDone if button is NOT pressed (0)
  STA player_dir
  JSR draw_player_down

  LDA iswalkable ;Check if it's a walkable tile
  AND #$01
  BEQ ReadDownDone
  INC player_y                      
  ReadDownDone:

  ReadLeft: 
  LDA buttons1     
  AND #%00000010  ; And raises Z = 1 if they're not equal to the word in buttons1.
  BEQ ReadLeftDone   ; branch to ReadLeftDone if button is NOT pressed (0)
  STA player_dir
  JSR draw_player_left ;set render sprite to left
  LDA iswalkable ;Check if it's a walkable tile
  AND #$01
  BEQ ReadLeftDone
  LDA scroll 
  CMP #$01 ;check if scroll hit wall
  BCC hit_left 
  LDA player_x ;check if player in center
  CMP #$80
  BCS hit_left
  DEC scroll ;else case move screen
  JMP ReadLeftDone
  hit_left:  ; if player not in center or border of map is hit 
  DEC player_x
  ReadLeftDone:

  ReadRight: 
  LDA buttons1       
  AND #%00000001  ; And raises Z = 1 if they're not equal to the word in buttons1.
  BEQ ReadRightDone   ; branch to ReadRightDone if button is NOT pressed (0)
  STA player_dir
  JSR draw_player_right ;set render sprite to right
  LDA iswalkable ;Check if it's a walkable tile
  AND #$01
  BEQ ReadRightDone
  LDA scroll
  CMP #$ff ;check if scroll hit wall
  BCS hit_right
  LDA player_x
  CMP #$80 ;check if player in center
  BCC hit_right
  INC scroll ;else case move screen
  JMP ReadRightDone
  hit_right: ; if player not in center or border of map is hit
  INC player_x
  ReadRightDone:

  ReadA: 
  LDA buttons1
  AND #%10000000 ; branch to ReadA if button is NOT pressed (0)
  BEQ ReadADone

  LDA NTflag
  CMP #$00
  BEQ returnToMain
  CMP #$01 
  BEQ returnToMain
  JMP ReadADone

  returnToMain:
    INC NTflag
    jmp main
  ; LDX NTflag
  ; CPX #$01
  ; BEQ resetNTFlag
  
  ; INC NTflag
  ; JMP main

  ; resetNTn
  ;   LDX #$00
  ;   STX NTflag
  ;   JMP main

  ReadADone:


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

.proc scrolldone
; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  LDA scroll
  STA $2005        ; write the horizontal scroll count register

  LDA #$00         ; no vertical scrolling
  STA $2005

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

bg_nam:
  .incbin "maptest.nam"
bg_pal:
  .incbin "bg_pal.pal"

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

supertile:
 .byte $04, $05, $14, $15 ; IronBlock 0,1,2,3
 .byte $0c, $0d, $1c, $10 ; Floor Tile 4,5,6,7 NUMBER 7 IS BLACK
 .byte $07, $08, $17, $18 ; Brick Tile 8,9,10,11
 .byte $0a, $0b, $1a, $1b ; Flower Tile 12,13,14,15

nametable0: 
  .byte %10101010, %10101010, %10101010, %10101010
  .byte %10010101, %01010101, %00010101, %01010110
  .byte %10010000, %00000001, %00010000, %00000110
  .byte %10010101, %01010101, %11010101, %01010010

  .byte %10010000, %00000001, %00111111, %01010110
  .byte %10010001, %01010100, %00010000, %00000010
  .byte %10011111, %11010101, %00010101, %01010101
  .byte %10010000, %00000001, %00010100, %00000010

  .byte %10010101, %01010101, %00010101, %01010110
  .byte %10010001, %01010000, %00010000, %00000010
  .byte %10010001, %01001111, %11010001, %01010110
  .byte %10010001, %01001100, %00010001, %00000110
  

  .byte %10110000, %00001101, %01010001, %00000110
  .byte %10111101, %01010001, %01010101, %01010110
  .byte %10101010, %10101010, %10101010, %10101010

nametable1: 
  .byte %10101010, %10101010, %10101010, %10101010
  .byte %10010101, %00010101, %01010101, %01010101
  .byte %10010001, %00000001, %01000101, %00000000
  .byte %10010001, %11110101, %01010101, %11010110
  .byte %10010101, %00000000, %01110000, %00000110
  .byte %10010001, %00010111, %01010101, %01000110
  .byte %01010111, %00010101, %01010101, %01010110
  .byte %10010100, %00000011, %01010100, %00001110
  .byte %10010101, %01010111, %00010001, %01010110
  .byte %10010001, %01010111, %00000001, %00000110
  .byte %10010000, %00000011, %01110101, %01010110
  .byte %10010001, %01010101, %01000101, %01000110
  .byte %10110001, %01000001, %01000101, %00010110
  .byte %10010000, %00010111, %11110000, %01010010
  .byte %10111101, %01010101, %01000101, %01010010
  .byte %10101010, %10101010, %10101010, %10101010


nametable2: 
  .byte %10101010, %10101010, %10101010, %10101010
  .byte %01010101, %01010100, %01010100, %01000010
  .byte %10010100, %00110000, %01010000, %01010110
  .byte %10110100, %00111100, %00010000, %01010110
  .byte %10110001, %01000100, %01010101, %01000010
  .byte %10110100, %00010100, %01010101, %01010110
  .byte %10010101, %01000100, %01010000, %01010110
  .byte %10010101, %01000100, %00010101, %00000101
  .byte %10010000, %00010100, %01010000, %01000010
  .byte %10010100, %00010000, %01000000, %01010110
  .byte %10000101, %01010100, %01010111, %11010110
  .byte %10010000, %00000100, %00010000, %11010010
  .byte %10000101, %01000000, %00110101, %01000010
  .byte %10101010, %10101010, %10101010, %10101010

nametable3: 
  .byte %10101010, %10101010, %10101010, %10101010
  .byte %10000000, %00010101, %01010101, %01010110
  .byte %10010101, %00010000, %00000000, %00010110
  .byte %10010101, %01010101, %01010101, %01000010
  .byte %10010000, %01000001, %00000100, %00010110
  .byte %10011111, %01111111, %00000100, %00010110 
  .byte %10010000, %01000011, %01010101, %01010110 
  .byte %01010001, %01010001, %00000000, %00010101
  .byte %10010000, %01000001, %01000100, %01000010 
  .byte %10010000, %01000001, %01000100, %01000010 
  .byte %10010101, %00010101, %01010101, %01010110 
  .byte %10010101, %01010100, %01000001, %00000110
  .byte %10010000, %01000001, %01000001, %00000110
  .byte %10000100, %01000001, %00000000, %00000110
  .byte %10010101, %01010100, %01010101, %01010100 
  .byte %10101010, %10101010, %10101010, %10101010

	
.segment "CHR"
.incbin "starfield1.chr"

