pushpc
ORG $7E0010
ptr: skip 3
pullpc
pushpc
ORG $C10000
gfx:
incbin "graphics.bin"
pullpc
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
    RTL
;init
init:
    TSC
    CLC
    ADC.W #0
    TCS
    JSL   main
    TSC
    CLC
    ADC.W #0
    TCS
    RTL
