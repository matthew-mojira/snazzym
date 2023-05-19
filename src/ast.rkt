#lang racket

(provide (all-defined-out))

; expr =
; | Int i
; | Bool b
; | Call id es
; stat =
; | Return e
; | If e s1 s2
; toplevel =
; | Func id t as ss
(struct Int    (i)       #:prefab)
(struct Bool   (b)       #:prefab)
(struct Call   (id es)   #:prefab)

(struct Return (e)       #:prefab)
(struct If     (e s1 s2) #:prefab)

; (function (id ret-type ()) stuff ...)
;                        ^ args list unimplemented
(struct Func   (id t as ss) #:prefab)
