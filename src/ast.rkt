#lang racket

(provide (all-defined-out))

; expr =
; | Int i
; | Bool b
; | Call id es
; | Var id
; stat =
; | Return e
; | If e ss
; | IfElse e ss1 ss2
; | Assign id e
; toplevel =
; | Func id t as ss
; | Global id t
(struct Int    (i)       #:prefab)
(struct Bool   (b)       #:prefab)
(struct Call   (id es)   #:prefab)
(struct Var    (id)      #:prefab)

(struct Return (e)       #:prefab)
(struct If     (e ss)    #:prefab)
(struct IfElse (e s1 s2) #:prefab)
(struct Assign (id e)    #:prefab)

; (function (id ret-type ()) stuff ...)
;                        ^ args list unimplemented
(struct Func   (id t as ss) #:prefab)
(struct Global (id t)       #:prefab)
