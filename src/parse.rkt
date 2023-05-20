#lang racket

(provide parse)
(require "ast.rkt")

(define (parse prog)
  (map parse-top-level prog))

(define (parse-top-level prog)
  (match prog
    [(list-rest 'func (list id type '()) ss)
     (Func id type '() (parse-stat* ss))]
    [(list 'global id t) (Global id t)]))

(define (parse-stat* stats)
  (map parse-stat stats))

(define (parse-stat stat)
  (match stat
    [(list 'return expr) (Return (parse-expr expr))]
    [(list-rest 'if e ss) (If (parse-expr e) (map parse-stat ss))]
    [(list 'if/else e s1 s2)
     (IfElse (parse-expr e) (map parse-stat s1) (map parse-stat s2))]
    [(list 'set! id e) (Assign id (parse-expr e))]
    [(cons id es) (Call id (map parse-expr es))]))

(define (parse-expr expr)
  (match expr
    [(? exact-integer?) (Int expr)]
    [(? boolean?) (Bool expr)]
    [(list (? (op? bool-op1) p1) e) (BoolOp1 p1 (parse-expr e))]
    [(list (? (op? bool-op2) p2) e1 e2)
     (BoolOp2 p2 (parse-expr e1) (parse-expr e2))]
    [(list (? (op? comp-op1) p1) e) (CompOp1 p1 (parse-expr e))]
    [(list (? (op? comp-op2) p2) e1 e2)
     (CompOp2 p2 (parse-expr e1) (parse-expr e2))]
    [(list (? (op? int-op1) p1) e) (IntOp1 p1 (parse-expr e))]
    [(list (? (op? int-op2) p2) e1 e2)
     (IntOp2 p2 (parse-expr e1) (parse-expr e2))]
    [(cons id es) (Call id (map parse-expr es))]
    [(? symbol? expr) (Var expr)]))

; a function call can be either a statement or an expression.
; in the future, it might make sense to make all expressions also be statements

(define (op? ops)
  (lambda (x) (and (symbol? x) (memq x ops))))
