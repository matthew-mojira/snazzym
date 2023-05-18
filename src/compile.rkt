#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "65816.rkt")

(define (compile prog)
  (seq (Label "entry") (flatten (map compile-stat prog))))

(define (compile-stat stat)
  (match stat
    [(Return expr) (seq (compile-expr expr) (Rtl))]
    [_ (error "not a statement")]))

(define (compile-expr expr)
  (match expr
    [(Int i) (compile-int i)]))

(define (compile-int int)
  (Lda (Imm int)))
