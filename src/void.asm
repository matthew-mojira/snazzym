pushpc
ORG $7E0010
z: skip 2
pullpc
pushpc
ORG $C10000
pullpc
;foo
foo:
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
    JSL   foo
    TSC
    CLC
    ADC.W #0
    TCS
    TSC
    CLC
    ADC.W #0
    TCS
    RTL
