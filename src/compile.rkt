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
            (Bne true)
            (Brl endif)
            (Label true)
            (compile-stat* ss)
            (Label endif)))]
    [(IfElse e s1 s2)
     (let ([true (gensym ".iftrue")]
           [false (gensym ".iffalse")]
           [endif (gensym ".endif")])
       (seq (compile-expr e)
            (Bne true)
            (Brl false)
            (Label true)
            (compile-stat* s1)
            (Brl endif)
            (Label false)
            (compile-stat* s2)
            (Label endif)))]
    [(Call id as) (Jsl (~a id))] ; args unimplemented
    [(Assign id e) (seq (compile-expr e) (Sta (Long id)))] ; need optimize
    [_ (error "not a statement")]))

(define (compile-expr expr)
  (match expr
    [(Int i) (compile-int i)]
    [(Bool b) (compile-bool b)]
    [(Call id as) (Jsl (~a id))] ; args unimplemented
    [(Var id) (Lda (Long id))]
    [(BoolOp1 op e)
     (seq (compile-expr e)
          (match op
            ['not (Eor (Imm 1))]))]
    [(BoolOp2 op e1 e2)
     (seq (compile-expr e1)
          (Pha) ; think about local environments later!
          (compile-expr e2)
          (match op
            ['and (And (Stk 1))]
            ['or (Ora (Stk 1))]
            ['eor (Eor (Stk 1))])
          (Ply))] ; think about use of Y register here
    [(IntOp1 op e)
     (seq (compile-expr e)
          (match op
            ['<< (Asl (Acc 1))]
            ['>> (Lsr (Acc 1))]
            ['1+ (Inc (Acc 1))]
            ['-1 (Dec (Acc 1))]))]
    [(IntOp2 op e1 e2)
     (seq (compile-expr e2)
          (Pha) ; think about local environments later!
          (compile-expr e1)
          (match op
            ['+ (seq (Clc) (Adc (Stk 1)))]
            ['- (seq (Sec) (Sbc (Stk 1)))])
          (Ply))] ; think about use of Y register here
    ; idea: get rid of boolean type altogether and move these comparisons
    ; directly into the if statement (or provide a compiler optimization if
    ; the expression in the if is just one computation)
    [(CompOp2 op e1 e2)
     (let ([true (gensym ".comp_true")] [end (gensym ".comp_end")])
       (seq (case op
              [(= != > <=) (seq (compile-expr e1) (Pha) (compile-expr e2))]
              [(< >=) (seq (compile-expr e2) (Pha) (compile-expr e1))])
            ; ALERT! COMPARISONS ARE UNSIGNED!!!
            ; OH NO... SIGNED AND UNSIGNED TYPES??
            (Cmp (Stk 1))
            (case op
              [(=) (Beq true)]
              [(!=) (Bne true)]
              [(< >) (Bcc true)]
              [(>= <=) (Bcs true)])
            (Lda (Imm 0))
            (Bra end)
            (Label true) ; true case
            (Lda (Imm 1))
            (Label end)
            (Ply)))] ; think about use of Y register here
    ))

(define (compile-int int)
  (Lda (Imm int)))

(define (compile-bool bool)
  (Lda (Imm (if bool 1 0))))

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
