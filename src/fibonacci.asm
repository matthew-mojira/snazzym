pushpc
ORG $7E0010
pullpc
;fibonacci
fibonacci:
    LDA.B 4,S
    PHA
    LDA.W #1
    CMP.B 1,S
    BCS   .comp_true8399
    LDA.W #0
    BRA   .comp_end8400
.comp_true8399:
    LDA.W #1
.comp_end8400:
    PLY
    CMP.W #0
    BNE   .iftrue8397
    BRL   .endif8398
.iftrue8397:
    LDA.B 4,S
    RTL
.endif8398:
    LDA.W #2
    PHA
    LDA.B 6,S
    SEC
    SBC.B 1,S
    PLY
    PHA
    JSL   fibonacci
    PLY
    PHA
    LDA.B 6,S
    DEC   #1
    PHA
    JSL   fibonacci
    PLY
    CLC
    ADC.B 1,S
    PLY
    RTL
;main
main:
    RTL
;vblank
vblank:
    RTL
;init
init:
    LDA.W #0
    PHA
    LDA.W #20
    PHA
    JSL   fibonacci
    PLY
    STA.B 1,S
    PLY
    RTL
