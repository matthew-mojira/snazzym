#lang racket

(provide parse)
(require "ast.rkt")

(define (parse prog)
  (map parse-top-level prog))

(define (parse-top-level prog)
  (match prog
    [(list-rest 'func (list id type ps) ss)
     (Func id
           type
           ; this turns (x int) into (x . int)
           ; proper list of 2 -> pair
           (map (match-lambda
                  [(list id t) (cons id t)])
                ps)
           (parse-stat* ss))]
    [(list 'global id t) (Global id t)]
    [(list 'include id s) (Include id s)]
    [(list 'array id t l) (Array id t l)]))

(define (parse-stat* stats)
  (map parse-stat stats))

(define (parse-stat stat)
  (match stat
    [(list 'return expr) (Return (parse-expr expr))]
    [(list-rest 'if p ss) (If (parse-pred p) (map parse-stat ss))]
    [(list 'if-else p s1 s2)
     (IfElse (parse-pred p) (map parse-stat s1) (map parse-stat s2))]
    [(list 'set! id e) (Assign id (parse-expr e))]
    [(list 'inc! id) (Increment id)]
    [(list 'dec! id) (Decrement id)]
    [(list 'zero! id) (ZeroOut id)]
    [(list-rest 'local bs ss) (parse-let bs ss)]
    [(list-rest 'while p ss) (While (parse-pred p) (parse-stat* ss))]
    [(list-rest 'native as) (Native as)]
    [(list-rest 'cond cs)
     (Cond (map (match-lambda
                  [(list p ss) (If (parse-pred p) (parse-stat* ss))])
                cs))]
    [(cons id es) (Call id (map parse-expr es))]))

(define (parse-expr expr)
  (match expr
    [(? exact-integer?) (Int expr)]
    ['() (Void)]
    [(list (? (op? int-op1) p1) e) (IntOp1 p1 (parse-expr e))]
    [(list (? (op? int-op2) p2) e1 e2)
     (IntOp2 p2 (parse-expr e1) (parse-expr e2))]
    [(list 'if-expr p e1 e2)
     (Ternary (parse-pred p) (parse-expr e1) (parse-expr e2))]
    [(cons id es) (Call id (map parse-expr es))]
    [(? symbol? expr) (Var expr)]))

(define (parse-pred pred)
  (match pred
    ['true (True)]
    ['false (False)]
    [(list (? (op? bool-op1) op) p) (BoolOp1 op (parse-pred p))]
    [(list (? (op? bool-op2) op) p1 p2)
     (BoolOp2 op (parse-pred p1) (parse-pred p2))]
    [(list (? (op? comp-op1) op) e) (CompOp1 op (parse-expr e))]
    [(list (? (op? comp-op2) op) e1 e2)
     (CompOp2 op (parse-expr e1) (parse-expr e2))]))

; a function call can be either a statement or an expression.
; in the future, it might make sense to make all expressions also be statements

(define (parse-let bs ss)
  (match bs
    ['() (Local '() (parse-stat* ss))]
    [(cons (list (? symbol? x1) t1) bs)
     (match (parse-let bs ss)
       [(Local bs ss) (Local (cons (cons x1 t1) bs) ss)])]))

(define (op? ops)
  (lambda (x) (and (symbol? x) (memq x ops))))
