pushpc
ORG $7E0010
y: skip 2
z: skip 2
x: skip 2
pullpc
;f
f:
    LDA.W #1
    BNE   .iftrue7608
    BRL   .iffalse7609
.iftrue7608:
    LDA.W #10
    RTL
    BRL   .endif7610
.iffalse7609:
    LDA.W #0
    BNE   .iftrue7611
    BRL   .iffalse7612
.iftrue7611:
    LDA.W #75
    RTL
    BRL   .endif7613
.iffalse7612:
    LDA.W #11
    RTL
.endif7613:
.endif7610:
;g
g:
    LDA.W #0
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
    BNE   .iftrue7614
    BRL   .iffalse7615
.iftrue7614:
    JSL   f
    LDA.W #1
    RTL
    BRL   .endif7616
.iffalse7615:
    LDA.W #1
    BNE   .iftrue7617
    BRL   .iffalse7618
.iftrue7617:
    JSL   h
    RTL
    BRL   .endif7619
.iffalse7618:
    LDA.W #25
    RTL
.endif7619:
.endif7616:
;init
init:
    LDA.W #16
    STA.L x
    LDA.W #0
    PHA
    LDA.W #1
    ORA.B 1,S
    PLY
    STA.L z
    LDA.L z
    EOR.W #1
    STA.L z
    LDA.L z
    PHA
    LDA.L z
    EOR.B 1,S
    PLY
    STA.L z
    LDA.L z
    PHA
    LDA.W #0
    AND.B 1,S
    PLY
    STA.L z
    LDA.L x
    RTL
;vblank
vblank:
    LDA.W #0
    RTL
