#lang racket

(provide compile)
(require "ast.rkt"
         "65816.rkt")

(define (compile progs)
  (flatten (map compile-top-level progs)))

(define (compile-top-level prog)
  (match prog
    [(Func id _ ss)
     (seq (Comment (~a id))
          (Label (symbol->label id))
          (flatten (map compile-stat ss)))]))

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
    [(Bool b) (compile-bool b)]))

(define (compile-int int)
  (Lda (Imm int)))

(define (compile-bool bool)
  (Lda (Imm (if bool 0 1))))

(define (symbol->label s)
  (string-append "func_"
                 (list->string (map (λ (c)
                                      (if (or (char<=? #\a c #\z)
                                              (char<=? #\A c #\Z)
                                              (char<=? #\0 c #\9)
                                              (memq c '(#\_)))
                                          c
                                          #\_))
                                    (string->list (symbol->string s))))
                 "_"
                 (number->string (eq-hash-code s) 16)))
