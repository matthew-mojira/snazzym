#lang racket

(provide compile)
(require "ast.rkt"
         "65816.rkt"
         "types.rkt")

(define (compile progs)
  (seq (make-global-list progs) (flatten (map compile-top-level progs))))

(define (compile-top-level prog)
  (match prog
    [(Func id _ as ss) ; args not handled
     (seq (Comment (~a id)) (Label (~a id)) (compile-stat* ss))]
    [_ '()]))

(define (compile-stat* stats)
  (flatten (map compile-stat stats)))

(define (compile-stat stat)
  (match stat
    [(Return expr) (seq (compile-expr expr) (Rtl))]
    [(If e ss)
     (let ([true (gensym ".iftrue")] [endif (gensym ".endif")])
       (seq (compile-expr e)
            (Beq true)
            (Brl endif)
            (Label true)
            (compile-stat* ss)
            (Label endif)))]
    [(IfElse e s1 s2)
     (let ([true (gensym ".iftrue")]
           [false (gensym ".iffalse")]
           [endif (gensym ".endif")])
       (seq (compile-expr e)
            (Beq true)
            (Brl false)
            (Label true)
            (compile-stat* s1)
            (Brl endif)
            (Label false)
            (compile-stat* s2)
            (Label endif)))]
    [(Call id as) (Jsl (~a id))] ; args unimplemented
    [_ (error "not a statement")]))

(define (compile-expr expr)
  (match expr
    [(Int i) (compile-int i)]
    [(Bool b) (compile-bool b)]
    [(Call id as) (Jsl (~a id))]
    [(Var id) (Lda (Long id))])) ; args unimplemented

(define (compile-int int)
  (Lda (Imm int)))

(define (compile-bool bool)
  (Lda (Imm (if bool 0 1))))

;(define (symbol->label s)
;  (string-append "func_"
;                 (list->string (map (λ (c)
;                                      (if (or (char<=? #\a c #\z)
;                                              (char<=? #\A c #\Z)
;                                              (char<=? #\0 c #\9)
;                                              (memq c '(#\_)))
;                                          c
;                                          #\_))
;                                    (string->list (symbol->string s))))
;                 "_"
;                 (number->string (eq-hash-code s) 16)))

(define (make-global-list globals)
  (seq (Pushpc)
       (Org "$7E0010") ; hardcoded start of global area
       (flatten (map (match-lambda
                       [(Global id t) (Skip id (type->size t))]
                       [_ '()])
                     globals))
       (Pullpc)))
