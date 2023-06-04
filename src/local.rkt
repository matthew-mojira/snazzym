#lang racket

(require "types.rkt")
(provide (all-defined-out))

(define (local-offset id lenv)
  (match lenv
    ['() #f]
    [(cons (cons idt t) rest)
     (if (eq? id idt)
         1
         (let ([rest (local-offset id rest)])
           (if rest (+ (type->size t) rest) #f)))]))

(define (local-size lenv)
  (match lenv
    ['() 0]
    [(cons (cons _ 'ret) _) 0] ; ret (return address of function) is a special
    ;                           stopping case here
    [(cons (cons _ t) ls) (+ (type->size t) (local-size ls))]))

(define (local-size-types-only lenv)
;  (println lenv)
;  (match lenv
;    ['() 0]
;    [(cons 'ret _) 0] ; ret (return address of function) is a special
;    ;                           stopping case here
;    [(cons t ls) (+ (type->size t) (local-size ls))]))

 (foldr (lambda (t acc) (+ (type->size t) acc)) 0 lenv)

 )
