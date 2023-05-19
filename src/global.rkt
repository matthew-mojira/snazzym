#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "types.rkt")

(define (extract-globs prog)
  (match prog
    [(cons (Global id t) ps) (cons (Global id t) (extract-globs ps))]
    [(cons _ ps) (extract-globs ps)]
    ['() '()]))
; use filter!!
