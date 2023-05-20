#lang racket

(provide compile)
(require "ast.rkt"
         "65816.rkt"
         "types.rkt"
         "local.rkt")

(define (compile progs)
  (seq (make-global-list progs) (flatten (map compile-top-level progs))))

(define (compile-top-level prog)
  (match prog
    [(Func id _ as ss) ; args not handled
     (seq (Comment (~a id))
          (Label (~a id))
          (compile-stat* ss (cons '(#f . long) (reverse as))))]
    [_ '()]))

(define (compile-stat* stats lenv)
  (flatten (map (lambda (s) (compile-stat s lenv)) stats)))

(define (compile-stat stat lenv)
  (match stat
    [(Return expr) ; need to deallocate any remaining local variables bound
     (seq (compile-expr expr lenv)
          (build-list (length-local lenv) (const (Ply)))
          ; this is just a basic fix. in the future, lenv might contain
          ; parameters which are put on the stack before the return value (and
          ; thus shouldn't be pulled off the stack)
          ; LENGTH-LOCAL DOES THIS!?
          ; also, we might want processor flags from the expression to be
          ; preserved
          (Rtl))]
    [(If e ss)
     (let ([true (gensym ".iftrue")] [endif (gensym ".endif")])
       (seq (compile-expr e lenv)
            (Bne true)
            (Brl endif)
            (Label true)
            (compile-stat* ss lenv)
            (Label endif)))]
    [(IfElse e s1 s2)
     (let ([true (gensym ".iftrue")]
           [false (gensym ".iffalse")]
           [endif (gensym ".endif")])
       (seq (compile-expr e lenv)
            (Bne true)
            (Brl false)
            (Label true)
            (compile-stat* s1 lenv)
            (Brl endif)
            (Label false)
            (compile-stat* s2 lenv)
            (Label endif)))]
    [(Call id as) (compile-call id as lenv)]
    [(Assign id e)
     (seq (compile-expr e lenv)
          (let ([offset (lookup-local id lenv)])
            (if offset
                (Sta (Stk offset)) ; local
                (Sta (Long id)))) ; not local? must be global
          ; SHOULD OPTIMIZE LONG!!
          )]
    ; also, need different schemes of storage based on type eventually
    [(Local bs ss)
     (seq (Lda (Imm 0)) ; nice initialization
          (build-list (length bs) (const (Pha))) ; allocate
          (compile-stat* ss (append (reverse bs) lenv)) ; inner statements
          (build-list (length bs) (const (Ply))))] ; deallocate
    ; need to change allocation/deallocation strategy when we have
    ; different sized types
    [_ (error "not a statement")]))

(define (compile-expr expr lenv)
  (match expr
    [(Int i) (compile-int i)]
    [(Bool b) (compile-bool b)]
    [(Void) '()]
    [(Call id as) (compile-call id as lenv)]
    [(Var id)
     (let ([offset (lookup-local id lenv)])
       (if offset
           (Lda (Stk offset)) ; local
           (Lda (Long id))))] ; not local? must be global
    ; SHOULD OPTIMIZE LONG!!
    [(BoolOp1 op e)
     (seq (compile-expr e lenv)
          (match op
            ['not (Eor (Imm 1))]))]
    [(BoolOp2 op e1 e2)
     (seq (compile-expr e1 lenv)
          (Pha)
          (compile-expr e2 (cons '(#f . bool) lenv))
          (match op
            ['and (And (Stk 1))]
            ['or (Ora (Stk 1))]
            ['eor (Eor (Stk 1))])
          (Ply))] ; think about use of Y register here
    [(IntOp1 op e)
     (seq (compile-expr e lenv)
          (match op
            ['<< (Asl (Acc 1))]
            ['>> (Lsr (Acc 1))]
            ['1+ (Inc (Acc 1))]
            ['-1 (Dec (Acc 1))]))]
    [(IntOp2 op e1 e2)
     (seq (compile-expr e2 lenv)
          (Pha)
          (compile-expr e1 (cons '(#f . int) lenv))
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
              [(= != > <=)
               (seq (compile-expr e1 lenv)
                    (Pha)
                    (compile-expr e2 (cons '(#f . int) lenv)))]
              [(< >=)
               (seq (compile-expr e2 lenv)
                    (Pha)
                    (compile-expr e1 (cons '(#f . int) lenv)))])
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

; calling conventions:
; caller puts arguments on the stack
; then calls: putting the return address at the top
; once the call is complete, deallocate values (leave accumulator with
; result)
(define (compile-call id as lenv)
  (seq (compile-expr* as lenv)
       (Jsl (~a id))
       (build-list (length as) (const (Ply)))))

(define (compile-expr* es lenv)
  (match es
    ['() '()]
    [(cons e es)
     (seq (compile-expr e lenv)
          (Pha)
          (compile-expr* es (cons '(#f . #f) lenv)))]))

(define (make-global-list globals)
  (seq (Pushpc)
       (Org "$7E0010") ; hardcoded start of global area
       (flatten (map (match-lambda
                       [(Global id t) (Skip id (type->size t))]
                       [_ '()])
                     globals))
       (Pullpc)))
