#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt"
         "func.rkt"
         "global.rkt")

(define (type-check prog)
  (let ([funcs (extract-funcs prog)] [globs (extract-globs prog)])
    (for ([p prog])
      (type-check-top-level p funcs globs))))

(define (type-check-top-level prog funcs globs)
  (match prog
    [(Func _ t _ ss) (type-check-stat* ss t funcs globs)]
    [_ #t]))

(define (type-check-stat* ss type funcs globs)
  (for ([s ss])
    (type-check-stat s type funcs globs)))

(define (type-check-stat stat type funcs globs)
  (match stat
    [(Return e) (type-check-expr e type funcs globs)]
    [(If e ss)
     (begin
       (type-check-expr e 'bool funcs globs)
       (type-check-stat* ss type funcs globs))]
    [(IfElse e s1 s2)
     (begin
       (type-check-expr e 'bool funcs globs)
       (type-check-stat* s1 type funcs globs)
       (type-check-stat* s2 type funcs globs))]
    [(Call id es) (type-check-call id es funcs globs)]
    [(Assign id e) (type-check-expr e (typeof-global id globs) funcs globs)]
    [_ #t]))

(define (type-check-expr expr type funcs globs)
  (begin
    ; first, do type checking of any subexpressions
    (match expr
      [(Call id es) (type-check-call id es funcs globs)]
      [(BoolOp1 _ e) (type-check-expr e 'bool funcs globs)]
      [(BoolOp2 _ e1 e2)
       (begin
         (type-check-expr e1 'bool funcs globs)
         (type-check-expr e2 'bool funcs globs))]
      [(CompOp1 _ e) (type-check-expr e 'int funcs globs)]
      [(CompOp2 _ e1 e2)
       (begin
         (type-check-expr e1 'int funcs globs)
         (type-check-expr e2 'int funcs globs))]
      [(IntOp1 _ e) (type-check-expr e 'int funcs globs)]
      [(IntOp2 _ e1 e2)
       (begin
         (type-check-expr e1 'int funcs globs)
         (type-check-expr e2 'int funcs globs))]
      [_ #t])
    ; second, compare actual type of expression with expected
    (if (eq? (typeof-expr expr funcs globs) type)
        #t
        (error "Type error: expected"
               type
               "but got"
               (typeof-expr expr funcs globs)))))

(define (typeof-expr expr funcs globs)
  (match expr
    [(Int _) 'int]
    [(Bool _) 'bool]
    [(BoolOp1 _ _) 'bool]
    [(BoolOp2 _ _ _) 'bool]
    [(CompOp1 _ _) 'bool]
    [(CompOp2 _ _ _) 'bool]
    [(IntOp1 _ _) 'int]
    [(IntOp2 _ _ _) 'int]
    [(Call id es) (match-let ([(Func _ t _ _) (lookup-func id funcs)]) t)]
    [(Var id) (typeof-global id globs)]))

(define (type-check-call id es funcs globs)
  (match-let ([(Func _ _ as ss) (lookup-func id funcs)])
    (if (= (length as) (length es))
        (for ([a as] [e es])
          (type-check-expr e a funcs globs))
        (error "Arity mismatch"))))

(define (typeof-global id globs) ; need to adapt for many var types
  (match (findf (match-lambda
                  [(Global idg t) (if (eq? id idg) t #f)]
                  [_ #f])
                globs)
    [(Global _ t) t]
    [_ (error "Failed global lookup")]))
