#lang racket

(provide (all-defined-out))

(define/match (type->size type)
  [('bool) 2]
  [('int) 2]
  [('byte) 1]
  [('void) 0]
  [('ret) 3] ; return address, should never be definable in a program
  [('long) 3])

(define (lookup-type id vars)
  (match (findf (lambda (var) (eq? id (car var))) vars)
    [(cons _ t) t]
    [_ #f]))
