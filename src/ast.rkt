#lang racket

(provide (all-defined-out))

; expr =
; | Int i
; | Bool b
; | Call id es
; | Var id
; | BoolOp1 op e
; | BoolOp2 op e1 e2
; | IntOp1 op e
; | IntOp2 op e1 e2
; | CompOp1 op e
; | CompOp2 op e1 e2
; | Void
; stat =
; | Return e
; | If e ss
; | IfElse e ss1 ss2
; | Assign id e
; | Local bs ss
; | While e ss
; | Native asm
; toplevel =
; | Func id t as ss
; | Global id t
; | Include file
(struct Int    (i)       #:prefab)
(struct Bool   (b)       #:prefab)
(struct Call   (id es)   #:prefab)
(struct Var    (id)      #:prefab)
(struct Void   ()        #:prefab)

(struct BoolOp1 (op e)     #:prefab)
(struct BoolOp2 (op e1 e2) #:prefab)
(struct CompOp1 (op e)     #:prefab)
(struct CompOp2 (op e1 e2) #:prefab)
(struct IntOp1  (op e)     #:prefab)
(struct IntOp2  (op e1 e2) #:prefab)

(struct Return (e)       #:prefab)
(struct If     (e ss)    #:prefab)
(struct IfElse (e s1 s2) #:prefab)
(struct Assign (id e)    #:prefab)
(struct Local  (bs ss)   #:prefab)
(struct While  (e ss)    #:prefab)
(struct Native (asm)     #:prefab)

; (function (id ret-type ()) stuff ...)
;                        ^ args list unimplemented
(struct Func   (id t as ss) #:prefab)
(struct Global (id t)       #:prefab)
(struct Include (id file)   #:prefab)


(define bool-op1 '(not))
(define bool-op2 '(and or eor))
(define comp-op1 '())
(define comp-op2 '(= != > < >= <=))
(define int-op1 '(<< >> 1+ 1-))
(define int-op2 '(+ -))

