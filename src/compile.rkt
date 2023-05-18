#lang racket

(provide compile)
(require "ast.rkt"
         "65816.rkt")

(define (compile prog)
  (seq (Label "entry") (flatten (map compile-stat prog))))

(define (compile-stat stat)
  (match stat
    [(Return expr) (seq (compile-expr expr) (Rtl))]
    [(If e s1 s2)
     (let ([true (gensym ".iftrue")]
           [false (gensym ".iffalse")]
           [endif (gensym ".endif")])
       (seq (compile-expr e)
            (Beq true)
            (Brl false)
            (Label true)
            (compile-stat s1)
            (Brl endif)
            (compile-stat s2)
            (Label endif)))]
    [_ (error "not a statement")]))

(define (compile-expr expr)
  (match expr
    [(Int i) (compile-int i)]
    [(Bool b) (compile-bool b)]
    ))

(define (compile-int int)
  (Lda (Imm int)))

(define (compile-bool bool)
  (Lda (Imm (if bool 0 1))))
