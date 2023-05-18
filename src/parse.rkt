#lang racket

(provide parse)
(require "ast.rkt")

(define (parse s)
  (map parse-stat s))

(define (parse-stat stat)
  (match stat
    [(list 'return expr) (Return (parse-expr expr))]))

(define (parse-expr expr)
  (match expr
    [(? exact-integer?) (Int expr)]))
