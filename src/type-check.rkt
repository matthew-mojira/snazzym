#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt")

(define (type-check prog)
  (for ([p prog])
    (type-check-top-level p)))

(define (type-check-top-level prog)
  (match prog
    [(Func _ t ss)
     (for ([s ss])
       (type-check-stat s t))]))

(define (type-check-stat stat type)
  (match stat
    [(Return e) (type-check-expr e type)]
    [(If e s1 s2)
     (begin
       (type-check-expr e 'bool)
       (type-check-stat s1 type)
       (type-check-stat s2 type))]
    [_ #t]))

(define (type-check-expr expr type)
  (if (eq? (typeof-expr expr) type)
      #t
      (error "Type error: expected" type "but got" (typeof-expr expr))))

(define (typeof-expr expr)
  (match expr
    [(Int _) 'int]
    [(Bool _) 'bool]))
