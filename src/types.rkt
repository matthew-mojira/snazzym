#lang racket

(provide (all-defined-out))

(define/match (type->size type)
  [('bool) 2]
  [('int) 2])
