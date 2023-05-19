#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt"
         "func.rkt")

(define (type-check prog)
  (let ([funcs (extract-funcs prog)])
    (for ([p prog])
      (type-check-top-level p funcs))))

(define (type-check-top-level prog funcs)
  (match prog
    [(Func _ t _ ss)
     (for ([s ss])
       (type-check-stat s t funcs))]))

(define (type-check-stat stat type funcs)
  (match stat
    [(Return e) (type-check-expr e type funcs)]
    [(If e s1 s2)
     (begin
       (type-check-expr e 'bool funcs)
       (type-check-stat s1 type funcs)
       (type-check-stat s2 type funcs))]
    [(Call id es) (type-check-call id es funcs)]
    [_ #t]))

(define (type-check-expr expr type funcs)
  (begin
    (match expr
      [(Call id es) (type-check-call id es funcs)]
      [_ #t])
    (if (eq? (typeof-expr expr funcs) type)
        #t
        (error "Type error: expected"
               type
               "but got"
               (typeof-expr expr funcs)))))

(define (typeof-expr expr funcs)
  (match expr
    [(Int _) 'int]
    [(Bool _) 'bool]
    [(Call id es) (match-let ([(Func _ t _ _) (lookup-func id funcs)]) t)]))

(define (type-check-call id es funcs)
  (match-let ([(Func _ _ as ss) (lookup-func id funcs)])
    (if (= (length as) (length es))
        (for ([a as] [e es])
          (type-check-expr e a funcs))
        (error "Arity mismatch"))))
