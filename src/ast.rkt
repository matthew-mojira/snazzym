#lang racket

(provide (all-defined-out))

; expr =
; | Int i
; stat =
; | Return e
(struct Int    (i)  #:prefab)
(struct Return (e)  #:prefab)
