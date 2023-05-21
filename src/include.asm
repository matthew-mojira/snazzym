pushpc
ORG $7E0010
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
;main
main:
    RTL
;vblank
vblank:
    RTL
;init
init:
    LDA.W #10
    PHA
    JSL   f
    PLY
    RTL
