#lang racket

(provide (all-defined-out))

; expr =
; | Int i
; | Call id es
; | Var id
; | IntOp1 op e
; | IntOp2 op e1 e2
; | Void
; | Ternary
; pred =
; | True
; | False
; | BoolOp1 op p
; | BoolOp2 op p1 p2
; | CompOp1 op e
; | CompOp2 op e1 e2
; stat =
; | Return e
; | If p ss
; | IfElse p ss1 ss2
; | Cond cs
; | Assign id e
; | Increment id
; | Decrement id
; | ZeroOut id
; | Local bs ss
; | While p ss
; | Native asm
; toplevel =
; | Func id t as ss
; | Global id t
; | Include file
; | Array id type length
(struct Int    (i)       #:prefab)
(struct Call   (id es)   #:prefab)
(struct Var    (id)      #:prefab)
(struct Void   ()        #:prefab)

(struct IntOp1  (op e)     #:prefab)
(struct IntOp2  (op e1 e2) #:prefab)
(struct Ternary (p e1 e2)  #:prefab)

(struct True    ()         #:prefab)
(struct False   ()         #:prefab)
(struct BoolOp1 (op p)     #:prefab)
(struct BoolOp2 (op p1 p2) #:prefab)
(struct CompOp1 (op e)     #:prefab)
(struct CompOp2 (op e1 e2) #:prefab)

(struct Return (e)       #:prefab)
(struct If     (p ss)    #:prefab)
(struct IfElse (p s1 s2) #:prefab)
(struct Cond   (cs)      #:prefab)

(struct Assign (id e)    #:prefab)
(struct Increment (id)   #:prefab)
(struct Decrement (id)   #:prefab)
(struct ZeroOut   (id)   #:prefab)

(struct Local  (bs ss)   #:prefab)
(struct While  (p ss)    #:prefab)
(struct Native (asm)     #:prefab)

; (function (id ret-type ()) stuff ...)
;                        ^ args list unimplemented
(struct Func   (id t as ss) #:prefab)
(struct Global (id t)       #:prefab)
(struct Include (id file)   #:prefab)
(struct Array (id t l)      #:prefab)


(define bool-op1 '(not))
(define bool-op2 '(and or))
(define comp-op1 '(zero?))
(define comp-op2 '(= != > < >= <=))
(define int-op1 '(<< >> 1+ 1-))
(define int-op2 '(+ -))

