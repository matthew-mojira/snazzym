#lang racket

(provide (all-defined-out))

(define/match (type->size type)
  [('bool) 2]
  [('int) 2]
  [('void) 0]
  [('ret) 3]  ; return address, should never be definable in a program
  [('long) 3])
