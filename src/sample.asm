pushpc
ORG $7E0010
y: skip 2
z: skip 2
x: skip 2
pullpc
;f
f:
    LDA.W #0
    BEQ   .iftrue7587
    BRL   .iffalse7588
.iftrue7587:
    LDA.W #10
    RTL
    BRL   .endif7589
.iffalse7588:
    LDA.W #1
    BEQ   .iftrue7590
    BRL   .iffalse7591
.iftrue7590:
    LDA.W #75
    RTL
    BRL   .endif7592
.iffalse7591:
    LDA.W #11
    RTL
.endif7592:
.endif7589:
;g
g:
    LDA.W #1
    RTL
;h
h:
    LDA.L x
    RTL
;main
main:
    JSL   f
    JSL   g
    JSL   g
    BEQ   .iftrue7593
    BRL   .iffalse7594
.iftrue7593:
    JSL   f
    LDA.W #1
    RTL
    BRL   .endif7595
.iffalse7594:
    LDA.W #0
    BEQ   .iftrue7596
    BRL   .iffalse7597
.iftrue7596:
    JSL   h
    RTL
    BRL   .endif7598
.iffalse7597:
    LDA.W #25
    RTL
.endif7598:
.endif7595:
;init
init:
    LDA.W #16
    STA.L x
    LDA.L x
    RTL
;vblank
vblank:
    LDA.W #0
    RTL
