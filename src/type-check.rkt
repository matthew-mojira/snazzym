#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt")

(define (type-check prog)
  (for ([stat prog])
    (type-check-stat stat)))

; what if statements have an expected type?
(define (type-check-stat stat)
  (match stat
    [(If e s1 s2)
     (begin
       (type-check-expr e 'bool)
       (type-check-stat s1)
       (type-check-stat s2))]
    [_ #t]))

(define (type-check-expr expr type)
  (match expr
    [(Int _) (if (eq? type 'int) #t (error "Type error"))]
    [(Bool _) (if (eq? type 'bool) #t (error "Type error"))]))
