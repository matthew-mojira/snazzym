fastrom
hirom

;;    IMPORTANT FILES

incsrc "registers.asm"; hardware registers and bitmasks

;;    COMPILED CODE

ORG $C00000 ; program code

reset bytes

incsrc !CODE_FILE     ; compiled code

; debug information regarding how big your program is
print "Compiled code usage: ", bytes, " bytes"

warnpc $C08000-1  ; ensure code is not too big

;;    ROM HEADER INFORMATION

ORG $00FFB0
    db    "  "        ; MAKER CODE (2 Bytes)
    db    "MGL "      ; GAME CODE (4 Bytes)
    db    $00, $00, $00, $00, $00, $00, $00    ; hardcoded
    db    $00         ; EXPANSION RAM SIZE
    db    $00         ; SPECIAL VERSION (normally $00)
    db    $00         ; CARTRIDGE SUB-NUMBER (normally $00)
    db    "SNAZZYM SNES-LANG MGL"    ; GAME TITLE (21 Bytes)
          ;|-------------------|;
    db    $31         ; MAP MODE (fastrom, hirom)
    db    $00         ; CARTRIDGE TYPE (ROM only)
    db    $06         ; ROM SIZE (2^6 KB = 64KB) -- corresponds to bank C0 only
    db    $00         ; RAM SIZE (0 means 0KB)
    db    $01         ; DESTINATION CODE (north america)
    db    $33         ; hardcoded
    db    $00         ; MASK ROM VERSION (Ver 1.0)

;;    INTERRUPT VECTOR INFORMATION

ORG $00FFE0
    ;;  N/A    N/A    COP    BRK   ABORT   NMI    RESET    IRQ
    dw $0000, $0000, I_COP, I_BRK, $0000, I_NMI, I_RESET, I_IRQ      ; NATIVE
    dw $0000, $0000, I_COP, I_BRK, $0000, I_NMI, I_RESET, I_IRQ      ; EMULATION

;;    INITIALIZATION ROUTINES

ORG $00FD90       ; bank 0 mirror starts at $008000
I_RESET:
    SEI           ; set interrupt disable
    CLC           ; clear carry flag
    XCE           ; exchange carry and emulation (turns off emulation mode)
    JML   F_RESET
F_RESET:
    REP   #$30    ; accumulator 16-bit
    LDX.W #$1FFF
    TXS           ; initialize stack pointer
    SEP   #$20    ; accumulator 8-bit
    LDA.B #$01
    STA.W MEMSEL  ; sets FastROM
    JSR   clear_regs
    JSR   clear_memory
    LDA.B #$C0    ; automatic read of the SNES read the first pair of JoyPads
    STA.W WRIO    ; IO Port Write Register
    LDA.B #$81
    STA.W NMITIMEN

    REP   #$20    ; 16-bit A
    SEP   #$10    ; 8-bit XY

    JSL   init    ; COMPILED CODE: INITIALIZATION ROUTINES

-   JSL   main    ; COMPILED CODE: MAIN GAME LOOP
    WAI
    BRA -

I_NMI:
    PHP
    PHA           ; is this a good order?
    LDA.W RDNMI   ; read for NMI acknowledge

    JSL   vblank  ; COMPILED CODE: VBLANK ROUTINE

    PLA
    PLP
    RTI           ; ReTurn from Interrupt

; this should never run
I_IRQ:
    RTI           ; ReTurn from Interrupt

I_BRK:
    STP

; this should never run
I_COP:
    BRK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CLEAR REGISTERS
;; Clears all the registers. This is a general clear of everything.
;; Initialization comes later.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_regs:
    PHP           ; push processor status register

    SEP   #$20    ; accumulator 8-bit
    LDA.B #$80    ; A = %1000 0000

    STA.W INIDISP
    STZ.W OBJSEL
    STZ.W OAMADD
    STZ.W OAMADD+1
    STZ.W OAMDATA
    STZ.W BGMODE
    STZ.W MOSAIC
    STZ.W BG1SC
    STZ.W BG2SC
    STZ.W BG3SC
    STZ.W BG4SC
    STZ.W BG12NBA
    STZ.W BG34NBA
    STZ.W BG1HOFS
    STZ.W BG1HOFS
    STZ.W BG1VOFS
    STZ.W BG1VOFS
    STZ.W BG2HOFS
    STZ.W BG2HOFS
    STZ.W BG2VOFS
    STZ.W BG2VOFS
    STZ.W BG3HOFS
    STZ.W BG3HOFS
    STZ.W BG3VOFS
    STZ.W BG3VOFS
    STZ.W BG4HOFS
    STZ.W BG4HOFS
    STZ.W BG4VOFS
    STZ.W BG4VOFS
    STA.W VMAINC
    STZ.W VMADD
    STZ.W VMADD+1
    STZ.W M7SEL
    LDA.B #$01
    STZ.W M7A
    STA.W M7A
    STZ.W M7B
    STZ.W M7B
    STZ.W M7C
    STZ.W M7C
    STZ.W M7D
    STA.W M7D
    STZ.W M7X
    STZ.W M7X
    STZ.W M7Y
    STZ.W M7Y
    STZ.W CGADD
    STZ.W W12SEL
    STZ.W W34SEL
    STZ.W WOBJSEL
    STZ.W WH0
    STZ.W WH1
    STZ.W WH2
    STZ.W WH3
    STZ.W WBGLOG
    STZ.W WOBJLOG
    STZ.W TM
    STZ.W TS
    STZ.W TMW
    STZ.W TSW
    LDA.B #$30
    STA.W CGSWSEL   ; WHY?
    STZ.W CGADSUB
    LDA.B #$E0
    STA.W COLDATA   ; WHY?
    STZ.W SETINI
    STZ.W NMITIMEN
    STZ.W WRMPYA
    STZ.W WRMPYB
    STZ.W WRDIV
    STZ.W WRDIV+1
    STZ.W WRDIVB
    STZ.W HTIME
    STZ.W HTIME+1
    STZ.W VTIME
    STZ.W VTIME+1
    STZ.W MDMAEN
    STZ.W HDMAEN

    PLP
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CLEAR MEMORY
;; Clears all of WRAM and VRAM (except WRAM stack area). This is a general
;; clean and will be initialized with useful stuff later.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_memory:
    PHP
    PHB

    SEP #$20
    REP #$10

    STZ.B $00
    STZ.W VMAINC
    LDX.W #0
    STX.W VMADD
    STX.W OAMADD
    STZ.W CGADD
    STX.W DMAADDR
    STX.W $4312
    STX.W $4322
    LDA.B #$7E
    STA.W $4304
    STA.W $4314
    STA.W $4324

    STX.W $4305
    LDX.W #$200
    STX.W $4315
    LDX.W #$220
    STX.W $4325

    LDA.B #$18
    STA.W $4301
    LDA.B #$22
    STA.W $4311
    LDA.B #$04
    STA.W $4321

    LDA.B #$09
    STA.W $4300
    LDA.B #$9A
    STA.W $4310
    STA.W $4320

    LDA.B #7
    STA.W $420B

    ; clear WRAM

    REP   #$30
    LDA.W #$0000
    LDX.W #$0FFE
-   STA.L $7E0000,X
    STA.L $7E1000-4,X
    STA.L $7E2000,X
    STA.L $7E3000,X
    STA.L $7E4000,X
    STA.L $7E5000,X
    STA.L $7E6000,X
    STA.L $7E7000,X
    STA.L $7E8000,X
    STA.L $7E9000,X
    STA.L $7EA000,X
    STA.L $7EB000,X
    STA.L $7EC000,X
    STA.L $7ED000,X
    STA.L $7EE000,X
    STA.L $7EF000,X
    STA.L $7F0000,X
    STA.L $7F1000,X
    STA.L $7F2000,X
    STA.L $7F3000,X
    STA.L $7F4000,X
    STA.L $7F5000,X
    STA.L $7F6000,X
    STA.L $7F7000,X
    STA.L $7F8000,X
    STA.L $7F9000,X
    STA.L $7FA000,X
    STA.L $7FB000,X
    STA.L $7FC000,X
    STA.L $7FD000,X
    STA.L $7FE000,X
    STA.L $7FF000,X
    DEX   #2
    BMI   +
    BRL   -

+   PLB
    PLP
    RTS

warnpc $C0FFB0-1  ; ensure codes does not clobber ROM header
