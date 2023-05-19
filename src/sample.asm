pushpc
ORG $7E0010
y: skip 2
z: skip 2
x: skip 2
pullpc
;f
f:
    LDA.W #0
    BEQ   .iftrue7580
    BRL   .iffalse7581
.iftrue7580:
    LDA.W #10
    RTL
    BRL   .endif7582
.iffalse7581:
    LDA.W #1
    BEQ   .iftrue7583
    BRL   .iffalse7584
.iftrue7583:
    LDA.W #75
    RTL
    BRL   .endif7585
.iffalse7584:
    LDA.W #11
    RTL
.endif7585:
.endif7582:
;g
g:
    LDA.W #1
    RTL
;main
main:
    JSL   f
    JSL   g
    JSL   g
    BEQ   .iftrue7586
    BRL   .iffalse7587
.iftrue7586:
    JSL   f
    LDA.W #1
    RTL
    BRL   .endif7588
.iffalse7587:
    LDA.W #0
    BEQ   .iftrue7589
    BRL   .iffalse7590
.iftrue7589:
    JSL   f
    RTL
    BRL   .endif7591
.iffalse7590:
    LDA.W #25
    RTL
.endif7591:
.endif7588:
;init
init:
    LDA.L x
    RTL
;vblank
vblank:
    LDA.W #0
    RTL
