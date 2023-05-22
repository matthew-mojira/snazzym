#lang racket

(provide (all-defined-out))
(require "ast.rkt")

; Extract all function definitions from a program
(define (extract-funcs prog)
  (filter (match-lambda
            [(Func _ _ _ _) #t]
            [_ #f])
          prog))

(define (lookup-func id funcs)
  (findf (match-lambda
           [(Func idf t as ss) (eq? id idf)]
           [_ #f])
         funcs))
