pushpc
ORG $7E0010
ptr: skip 3
pullpc
pushpc
ORG $C10000
gfx:
incbin "graphics.bin"
pullpc
;f
f:
    LDA.B 4,S
    RTL
;dma/dma-vram
dma_dma_vram:
    LDX.B #!VINC_IncBy1
    LDA.B 6,S
    STA.W VMADD
    LDX.B #VMDATA
    STX.W DMAREG
    LDA.B 4,S
    STA.W DMACNT
    LDA.B 8,S
    STA.W DMAADDR
    LDA.B 10,S
    TAX
    STX.W DMAADDR+2
    LDX.B #(!DMA_AtoB|!DMA_ABusInc|!DMA_2Byte2Addr)
    STX.W DMAPARAM
    LDX.B #!Ch0
    STX.W MDMAEN
    RTL
;foo
foo:
    TSC
    CLC
    ADC.W #-7
    TCS
    TXY
    STA.B 6,S
    TSC
    CLC
    ADC.W #5
    TCS
    TYX
    PLA
    RTL
    TSC
    CLC
    ADC.W #7
    TCS
;bar
bar:
    SEP.B #32
    LDA.B 6,S
    TAX
    REP.B #32
    LDA.B 4,S
    RTL
;main
main:
    RTL
;vblank
vblank:
    LDA.W #gfx
    LDX.B #<:gfx
    PHX
    PHA
    LDA.W #0
    PHA
    LDA.W #4096
    PHA
    JSL   dma_dma_vram
    TSC
    CLC
    ADC.W #7
    TCS
    RTL
;init
init:
    RTL
