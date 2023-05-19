#lang racket

(provide parse)
(require "ast.rkt")

(define (parse prog)
  (map parse-top-level prog))

(define (parse-top-level prog)
  (match prog
    [(list-rest 'function (list id type '()) ss)
     (Func id type '() (map parse-stat ss))]))

(define (parse-stat stat)
  (match stat
    [(list 'return expr) (Return (parse-expr expr))]
    [(list 'if e s1 s2) (If (parse-expr e) (parse-stat s1) (parse-stat s2))]
    [(cons id es) (Call id (map parse-expr es))]))
; need to figure out how to parse lists of statements better

(define (parse-expr expr)
  (match expr
    [(? exact-integer?) (Int expr)]
    [(? boolean?) (Bool expr)]
    [(cons id es) (Call id (map parse-expr es))]))

; a function call can be either a statement or an expression.
; in the future, it might make sense to make all expressions also be statements
