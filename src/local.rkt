#lang racket

(require "types.rkt")
(provide (all-defined-out))

(define (lookup-local id lenv)
  (match lenv
    ['() #f]
    [(cons (cons idt t) rest)
     (if (eq? id idt)
         1
         (let ([rest (lookup-local id rest)])
           (if rest (+ (type->size t) rest) #f)))]))

(define (length-local lenv)
  (match lenv
    ['() 0]
    [(cons (cons _ 'long) _) 0]
    [(cons (cons _ t) ls) (+ (type->size t) (length-local ls))]))
