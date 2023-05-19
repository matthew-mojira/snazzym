#lang racket

(provide (all-defined-out))
(require "ast.rkt")

; Extract all function definitions from a program
(define (extract-funcs prog)
  (match prog
    [(cons (Func id t as ss) ps) (cons (Func id t as ss) (extract-funcs ps))]
    [(cons _ ps) (extract-funcs ps)]
    ['() '()]))
; use filter!!

(define (lookup-func id funcs)
  (findf (match-lambda
           [(Func idf t as ss) (if (eq? id idf) (Func idf t as ss) #f)]
           [_ #f])
         funcs))
