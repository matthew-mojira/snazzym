#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "types.rkt")

(define (extract-globs prog)
  (match prog
    [(cons (Global id t) ps) (cons (cons id t) (extract-globs ps))]
    [(cons (Include id _) ps) (cons (cons id 'long) (extract-globs ps))]
    [(cons _ ps) (extract-globs ps)]
    ['() '()]))
; use filter!!

(define (lookup-global-type id globs)
  (match globs
    ['() #f]
    [(cons (cons idt t) rest)
     (if (eq? id idt) t (lookup-global-type id rest))]))
