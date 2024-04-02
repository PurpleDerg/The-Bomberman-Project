.include "constants.inc"
.include "header.inc"

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

  ; write sprite data
  LDX #$00
load_sprites:
  LDA sprites,X
  STA $0200,X
  INX
  CPX #$c0
  BNE load_sprites

	; write nametables
	; Wall textures
	;Steel Wall
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	LDX #$04
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$01
	STA PPUADDR
	LDX #$05
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$20
	STA PPUADDR
	LDX #$14
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$21
	STA PPUADDR
	LDX #$15
	STX PPUDATA

	; next, Brick Wall
	LDA PPUSTATUS
	LDA #$21 ;Hi bit
	STA PPUADDR
	LDA #$02 ;Lo Bit
	STA PPUADDR
	LDX #$06 ;tile address
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$03 
	STA PPUADDR
	LDX #$07
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$22
	STA PPUADDR
	LDX #$16
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$23
	STA PPUADDR
	LDX #$17
	STX PPUDATA

	

	; flowerpatch
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$40
	STA PPUADDR
	LDX #$0a
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$41
	STA PPUADDR
	LDX #$0b
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$60
	STA PPUADDR
	LDX #$1a
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$61
	STA PPUADDR
	LDX #$1b
	STX PPUDATA	

	;Now the floor tiles
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$42
	STA PPUADDR
	LDX #$0c
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$43
	STA PPUADDR
	LDX #$0d
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$62
	STA PPUADDR
	LDX #$1c
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$63
	STA PPUADDR
	LDX #$1d
	STX PPUDATA

	; write nametables
	; Wall textures
	;Steel Wall
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$80
	STA PPUADDR
	LDX #$04
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$81
	STA PPUADDR
	LDX #$05
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$A0
	STA PPUADDR
	LDX #$14
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$A1
	STA PPUADDR
	LDX #$15
	STX PPUDATA

	; next, Brick Wall
	LDA PPUSTATUS
	LDA #$21 ;Hi bit
	STA PPUADDR
	LDA #$82 ;Lo Bit
	STA PPUADDR
	LDX #$06 ;tile address
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$83 
	STA PPUADDR
	LDX #$07
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$A2
	STA PPUADDR
	LDX #$16
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$A3
	STA PPUADDR
	LDX #$17
	STX PPUDATA

	

	; flowerpatch
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$C0
	STA PPUADDR
	LDX #$0a
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$c1
	STA PPUADDR
	LDX #$0b
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$E0
	STA PPUADDR
	LDX #$1a
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$E1
	STA PPUADDR
	LDX #$1b
	STX PPUDATA	

	;Now the floor tiles
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$C2
	STA PPUADDR
	LDX #$0c
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$c3
	STA PPUADDR
	LDX #$0d
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$e2
	STA PPUADDR
	LDX #$1c
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$e3
	STA PPUADDR
	LDX #$1d
	STX PPUDATA

	; finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$d0
	STA PPUADDR
	LDA #%11111000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$d8
	STA PPUADDR
	LDA #%01001101
	STA PPUDATA





vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10001000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
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

sprites:
.byte $00, $00, $00, $00 ; y,tile,pallete,x
.byte $00, $01, $00, $08
.byte $08, $10, $00, $00
.byte $08, $11, $00, $08

.byte $00, $02, $00, $10 
.byte $00, $03, $00, $18
.byte $08, $12, $00, $10
.byte $08, $13, $00, $18

.byte $00, $04, $00, $20 
.byte $00, $05, $00, $28
.byte $08, $14, $00, $20
.byte $08, $15, $00, $28

.byte $10, $06, $00, $00 
.byte $10, $07, $00, $08
.byte $18, $16, $00, $00
.byte $18, $17, $00, $08

.byte $10, $08, $00, $10 
.byte $10, $09, $00, $18
.byte $18, $18, $00, $10
.byte $18, $19, $00, $18

.byte $10, $0a, $00, $20 
.byte $10, $0b, $00, $28
.byte $18, $1a, $00, $20
.byte $18, $1b, $00, $28

.byte $20, $20, $00, $00 
.byte $20, $21, $00, $08
.byte $28, $30, $00, $00
.byte $28, $31, $00, $08

.byte $20, $22, $00, $10 
.byte $20, $23, $00, $18
.byte $28, $32, $00, $10
.byte $28, $33, $00, $18

.byte $20, $24, $00, $20 
.byte $20, $25, $00, $28
.byte $28, $34, $00, $20
.byte $28, $35, $00, $28

.byte $30, $26, $00, $00 
.byte $30, $27, $00, $08
.byte $38, $36, $00, $00
.byte $38, $37, $00, $08

.byte $30, $28, $00, $10 
.byte $30, $29, $00, $18
.byte $38, $38, $00, $10
.byte $38, $39, $00, $18

.byte $30, $2a, $00, $20 
.byte $30, $2b, $00, $28
.byte $38, $3a, $00, $20
.byte $38, $3b, $00, $28

.segment "CHR"
.incbin "starfield1.chr"
