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

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
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
