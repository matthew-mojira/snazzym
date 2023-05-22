#lang racket

(provide compile)
(require "ast.rkt"
         "65816.rkt"
         "types.rkt"
         "local.rkt"
         "global.rkt"
         "func.rkt"
         "const.rkt")

; global variables are mutated by call to compile
; taking a page out of my language!
; basically saves us the trouble from having to pass it around, since the global
; variables and defined functions will never change (I hope)
; wouldnt dynamic scope be cool??
(define globs '())
(define funcs '())
(define consts '())
; technically constants, NOT variables...
; does this actually get us towards function pointers??

(define (compile progs)
  (set! globs (extract-globs progs))
  (set! funcs (extract-funcs progs))
  (set! consts (extract-consts progs))
  (seq (make-global-list progs)
       (make-include-list progs)
       (flatten (map compile-top-level progs))))

(define (compile-top-level prog)
  (match prog
    [(Func id _ as ss) ; args not handled
     (seq (Comment (~a id))
          (Label (symbol->label id))
          (compile-stat* ss (cons '(#f . ret) (reverse as))))]
    ; note use of ret here as a stopping indicator for the lookup
    [_ '()]))

(define (compile-stat* stats lenv)
  (flatten (map (lambda (s) (compile-stat s lenv)) stats)))

(define (compile-stat stat lenv)
  (match stat
    [(Return expr) ; need to deallocate any remaining local variables bound
     (seq (compile-expr expr lenv)
          ; NEED TYPE OF UNDERLYING EXPRESSION
          ; this just takes the safe approach and saves everything
          ; (it doesn't know)
          ; in the future: more interesting types and byte types will
          ; necessitate a rethink of this very much
          (let ([alloc-size (length-local lenv)])
            (if (zero? alloc-size)
                '() ; no need to deallocate
                (seq (Txy)
                     (Sta (Stk (sub1 alloc-size)))
                     (move-stack (- alloc-size 2))
                     (Tyx)
                     (Pla))))
          (Rtl))]
    [(If e ss)
     (let ([true (gensym ".iftrue")] [endif (gensym ".endif")])
       (seq (compile-expr e lenv)
            (Cmp (Imm 0)) ; want to optimize this away such that the previous
            ; compile expr will always have the flags set appropriately
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
            (Cmp (Imm 0)) ; want to optimize this away such that the previous
            ; compile expr will always have the flags set appropriately
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
          (cond
            [(lookup-type id lenv)
             =>
             (lambda (t)
               (let ([offset (lookup-local id lenv)])
                 (case t
                   [(void) '()]
                   [(long)
                    ; to use stack addrsssing, need to send X to A
                    (seq (Sta (Stk offset))
                         (Sep (Imm8 #x20))
                         (Txa)
                         (Sta (Stk (+ 2 offset)))
                         (Rep (Imm8 #x20)))]
                   [else (Sta (Stk offset))])))]
            [(lookup-type id globs)
             =>
             (lambda (t)
               (case t
                 [(void) '()]
                 [(long)
                  (seq (Sta (Abs (symbol->label id)))
                       (Stx (Abs (string-append (symbol->label id) "+2"))))]
                 ; x 8 bits
                 [else (Sta (Abs (symbol->label id)))]))]
            [else (error "Assignment invalid")]))]
    [(Local bs ss)
     (seq (move-stack (- (length-local bs))) ; allocate
          (compile-stat* ss (append (reverse bs) lenv)) ; inner statements
          (move-stack (length-local bs)))] ; deallocate
    ; note the use of `length-local` is a bit different from how it was
    ; originally designed
    [(While e ss)
     (let ([loop (gensym ".loop")]
           [true (gensym ".looptrue")]
           [done (gensym ".loopdone")])
       (seq (Label loop)
            (compile-expr e lenv)
            (Cmp (Imm 0)) ; need optimizing away (bool problem!)
            (Bne true)
            (Brl done) ; this is a common idiom, and could be optimized
            (Label true) ; if the statements fit within the limits
            (compile-stat* ss lenv)
            (Brl loop)
            (Label done)))]
    [(Native as) (map (lambda (a) (Code a)) as)]
    [_ (error "not a statement")]))

(define (compile-expr expr lenv)
  (match expr
    [(Int i) (compile-int i)]
    [(Bool b) (compile-bool b)]
    [(Void) '()]
    [(Call id as) (compile-call id as lenv)]
    [(Var id)
     (cond
       [(lookup-type id lenv)
        =>
        (lambda (t)
          (let ([offset (lookup-local id lenv)])
            (case t
              [(void) '()]
              [(long)
               (seq (Sep (Imm8 #x20))
                    (Lda (Stk (+ 2 offset)))
                    (Tax) ; x 8 bits
                    (Rep (Imm8 #x20))
                    (Lda (Stk offset)))]
              [else (Lda (Stk offset))])))]
       [(lookup-type id globs)
        =>
        (lambda (t)
          (case t
            [(void) '()]

            [(long)
             (seq (Lda (Abs (symbol->label id)))
                  (Stx (Abs (string-append (symbol->label id) "+2"))))]
            ; x 8 bits
            [else (Lda (Abs (symbol->label id)))]))]
       [(lookup-type id consts)
        =>
        (lambda (t)
          (case t
            [(void) '()]
            [(long)
             (seq (Lda (Imm id)) (Ldx (Imm8 (string-append "<:" (~a id)))))]
            [else (Lda (Imm id))]))]
       [else (error "Variable invalid")])]
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
            ['1- (Dec (Acc 1))]))]
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
; note to self: should also make a compile-call version when the call is a
; statementt, because then we are safe to throw away the return value during
; the deallocation process
(define (compile-call id as lenv)
  (match-let ([(Func _ t ts _) (lookup-func id funcs)])
    (seq ; putting arguments on the stack
     ; if empty, for/list should yield empty list
     (for/list ([arg as] [type (map cdr ts)]) ; cdr is type
       (let ([code (compile-expr arg lenv)])
         (set! lenv (cons '(#f . #f) lenv)) ; functional features are gone
         (seq code
              (case type
                [(void) '()]
                [(long) (seq (Pha) (Phx))]
                [else (Pha)]))))
     ; performing the function call
     (Jsl (symbol->label id))
     ; deallocating argument space
     (let ([alloc-size (length-local ts)])
       (if (empty? as)
           '() ; no need to deallocate
           (case t
             [(void) (move-stack alloc-size)] ; no need to save
             [(long)
              (seq (Txy)
                   (Sta (Stk (sub1 alloc-size)))
                   (move-stack (- alloc-size 2))
                   (Tyx)
                   (Pla))]
             [else
              (seq (Sta (Stk (sub1 alloc-size)))
                   (move-stack (- alloc-size 2))
                   (Pla))])))
     ; an ingenious optimization: the accumulator is saved on the stack that
     ; we are
     ; eliminating, so we save it on the stack at a point and deallocate 2 fewer
     ; bytes so we can pull it at the end
     ; danger: what if we have byte-sized types eventually?
     )))

(define (make-global-list globals)
  (seq (Pushpc)
       (Org "$7E0010") ; hardcoded start of global area
       (flatten (map (match-lambda
                       [(Global id t) (Skip (symbol->label id) (type->size t))]
                       [_ '()])
                     globals))
       (Pullpc)))

; dont need to push/pull again, really
(define (make-include-list progs)
  (seq (Pushpc)
       (Org "$C10000") ; hardcoded start of data
       (flatten (map (match-lambda
                       [(Include id file)
                        (seq (Label (symbol->label id)) (Incbin file))]
                       [_ '()])
                     progs))
       (Pullpc)))
; note to self, don't lie about how large the ROM is in the header,
; maybe?

; this is inlined for every time it is called!
; idea: in certain places this could be *very* optimized
; preserving the regisets is up to the user
(define (move-stack bytes)
  (seq (Tsc) (Clc) (Adc (Imm bytes)) (Tcs)))

; this will need much more work in the future
(define (symbol->label id)
  (let ([replacements (list '("/" . "_") '("-" . "_"))])
    (foldr (lambda (pair str) (string-replace str (car pair) (cdr pair)))
           (~a id)
           replacements)))
