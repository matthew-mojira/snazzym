#lang racket

(provide (all-defined-out))

; expr =
; | Int i
; | Bool b
; stat =
; | Return e
; | If e s1 s2
(struct Int    (i)       #:prefab)
(struct Bool   (b)       #:prefab)
(struct Return (e)       #:prefab)
(struct If     (e s1 s2) #:prefab)
