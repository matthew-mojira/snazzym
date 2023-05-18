#lang racket

(provide parse)
(require "ast.rkt")

(define (parse s)
  (map parse-stat s))

(define (parse-stat stat)
  (match stat
    [(list 'return expr) (Return (parse-expr expr))]
    [(list 'if e s1 s2) (If (parse-expr e) (parse-stat s1) (parse-stat s2))]))
    ; need to figure out how to parse lists of statements better

(define (parse-expr expr)
  (match expr
    [(? exact-integer?) (Int expr)]
    [(? boolean?) (Bool expr)]))
