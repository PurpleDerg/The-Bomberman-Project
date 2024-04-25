; -------------------------
; PROCEDURE: LoadInitialMap
; Description: Loads the initial map into RAM buffers.
; -------------------------
.proc LoadInitialMap
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA
    ; Set the initial address of the map
    lda #<map   ; Get the low byte of the "map" address.
    sta RowAddress
    lda #>map   ; Get the high byte of the "map" address.
    sta RowAddress+1

    ; Start decoding

    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS

.endproc

; -------------------------
; PROCEDURE: DecodeMetatiles
; Description: Decodes metatiles from the map into RAM buffers.
; -------------------------

.proc DecodeMetatiles
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA

    ldx #$00            ; Initialize the buffer index
    stx BlockIndex

    DecodeBlock:

    ldy BlockIndex      ; Y = Map index
    lda (RowAddress), y ; Load metatile index from the map
    sta temp            ; Save the metatile index in temp
    iny
    sty BlockIndex

    ; Calculate the offset for the metatile index
    asl                ; A = index * 2
    asl                ; A = index * 4
    adc temp           ; A = index * 5
    tay                ; Y = Offset for the metatile index

    ; Decode the metatile using the offset
    lda metatiles, y     ; Read the top-left tile
    sta TileBuffer0, x  ; Write it to the upper buffer
    lda metatiles + 2, y ; Read the bottom-left tile
    sta TileBuffer1, x  ; Write it to the lower buffer
    inx
    lda metatiles + 1, y ; Read the top-right tile
    sta TileBuffer0, x  ; Write it to the upper buffer
    lda metatiles + 3, y ; Read the bottom-right tile
    sta TileBuffer1, x  ; Write it to the lower buffer
    inx

    cpx #$20            ; Check if both buffers are full
    bne DecodeBlock

    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS

.endproc

.proc CopyBuffersToVRAM
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA

    ;LDA levelStarted   ; Load the flag value into A
    ;BNE AlreadyInitialized ; If the flag is set (non-zero), exit the procedure immediately
    LDA PPUSTATUS
    JMP AlreadyInitialized ; If the flag is set (non-zero), exit the procedure immediately
    ; Set levelStarted to 1 because we're about to initialize
    LDA #1
    STA levelStarted

  ; Reset PPU latch
    LDA PPUSTATUS

    ; Set the initial VRAM address for NameTable 0
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDY #$0F ; Number of times the buffers will be copied

OuterLoop:

    ; Copy TileBuffer0 to VRAM
    LDX #$00
CopyTileBuffer0:
    LDA TileBuffer0, x
    STA PPUDATA
    INX
    CPX #$20
    BNE CopyTileBuffer0

    ; Copy TileBuffer1 to VRAM
    LDX #$00
CopyTileBuffer1:
    LDA TileBuffer1, x
    STA PPUDATA
    INX
    CPX #$20
    BNE CopyTileBuffer1

    DEY
    BNE OuterLoop

    LDA #$28
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDY #$0F ; Number of times the buffers will be copied
OuterLoop2:

    ; Copy TileBuffer0 to VRAM
    LDX #$00
CopyTileBuffer02:
    LDA TileBuffer0, x
    STA PPUDATA
    INX
    CPX #$20
    BNE CopyTileBuffer02

    ; Copy TileBuffer1 to VRAM
    LDX #$00
CopyTileBuffer12:
    LDA TileBuffer1, x
    STA PPUDATA
    INX
    CPX #$20
    BNE CopyTileBuffer12

    DEY
    BNE OuterLoop2
    ; Restore the registers and return
AlreadyInitialized:

    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc

.proc CopyPillarToVRAM

    LDA startCopyVram
    BEQ notDraw
    
    
    ;LDA PPUSTATUS
    ; Write the tiles to the PPU for TopRow
    LDA TopRowAddress+1
    STA PPUADDR
    LDA TopRowAddress
    STA PPUADDR

    LDX #$00
LoopTop:
    LDA TileBuffer0, x
    STA PPUDATA
    INX
    CPX #$20 ; There are 16 tiles in a row of metatiles
    BNE LoopTop
    
    ; Write the tiles to the PPU for BottomRow
    LDA BottomRowAddress+1
    STA PPUADDR
    LDA BottomRowAddress
    STA PPUADDR
    
    LDX #$00
LoopBottom:
    LDA TileBuffer1, x
    STA PPUDATA
    INX
    CPX #$20 ; There are 16 tiles in a row of metatiles
    BNE LoopBottom
    
    
notDraw:
    LDA #255
    CMP NTCamera
    BEQ UpdateBase
    BNE continua
UpdateBase:
    LDA NTBase    
    EOR #$01
    STA NTBase
    LDA #239
    STA NTCamera

continua:
.endproc

.proc VRAMCopyPrep
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA
    LDA NTBase
    BEQ NTBaseZero
    
    ; NTBase is 1, so tempNAddress is $2800
    LDA #$00 ; Load the low byte of $2800.
    STA tempNAddress
    LDA #$28 ; Load the high byte of $2800.
    STA tempNAddress + 1
    JMP CalculateTopRowAddress

NTBaseZero:
    ; NTBase is 0, so tempNAddress is $2000
    LDA #$00 ; Load the low byte of $2000.
    STA tempNAddress
    LDA #$20 ; Load the high byte of $2000.
    STA tempNAddress + 1

CalculateTopRowAddress:
    LDY #0      ; Use Y as a temporary high byte
  ; Shift NTCamera right three times and track the overflow in NTCameraHi
    CLC
    LDA NTCamera
    LSR A
    ROR NTCameraHi
    LSR A
    ROR NTCameraHi
    LSR A
    ROR NTCameraHi

    ; Now perform the ASL
    
    ASL A
    ROL NTCameraHi
    ASL A
    ROL NTCameraHi
    ASL A
    ROL NTCameraHi
    ASL A
    ROL NTCameraHi
    ASL A
    ROL NTCameraHi

    ; Now A has the low byte, and NTCameraHi has the high byte

    ; Add with tempNAddress
    
    ADC tempNAddress
    STA TopRowAddress

    LDA NTCameraHi
    ADC tempNAddress+1
    STA TopRowAddress+1

    LDA TopRowAddress
    CLC 
    ADC #$20
    STA BottomRowAddress
    LDA TopRowAddress + 1
    ADC #$00
    STA BottomRowAddress + 1
    
    LDA #$01
    STA startCopyVram

   
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc

; -------------------------
; PROCEDURE: UpdateCamera
; Description: Updates the Y position of the camera.
; -------------------------
.proc UpdateCamera
    PHP
    PHA
    TXA
    PHA
    TYA
    PHA
    
    ; Update NTCamera

   
    ;LDA NTCamera
    ;CLC
    ;ADC #1 ; Increment the camera
    ;CMP #240
    ;BCC EndUpdate
    ;ADC #15 ; Skip the extra 16 bytes if we go over 239
    LDA NTCamera
    SEC
    SBC #1 ; Decrement the camera
  
    BNE EndUpdate ; If NTCamera is not 0, continue.

    EndUpdate:
    STA NTCamera
    JMP Continue

    
Continue:
    CLC
    LDA CameraY        ; Load the low byte of CameraY
    ADC #1              ; Increment by 1, taking into account the carry flag
    STA CameraY        ; Save the new value

    LDA CameraY + 1        ; Load the high byte of CameraY
    ADC #0              ; Add the carry flag from the previous increment, if present
    STA CameraY + 1        ; Save the new value

     ; Compare the difference between the low byte of CameraY and OldCameraY
    LDA CameraY
    SEC
    SBC OldCameraY
    CMP #8
    BCC continue
    JSR DecodeMetatiles
continue:    
    CMP #16
    BCC DoNotDraw
    LDA CameraY
    STA OldCameraY
    JSR VRAMCopyPrep
    
    
DoNotDraw:
    
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS
.endproc

.segment "RODATA"

; Water Metatile
metatiles:
 metatile_water: .byte $00, $01, $10, $11, %00000011
 metatile_Ground: .byte $FF, $FF, $FF, $FF, %00000011

map:
    .byte 0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0
