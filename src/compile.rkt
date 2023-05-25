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
  (seq (Pushpc)
       (make-global-list progs)
       (make-include-list progs)
       (make-array-list progs)
       (Pullpc)
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
    [(Call id as) (compile-call id as lenv)]
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
    [(If p ss)
     (let ([true (gensym ".iftrue")] [endif (gensym ".endif")])
       (seq (compile-pred p lenv true endif)
            (Label true)
            (compile-stat* ss lenv)
            (Label endif)))]
    [(IfElse p s1 s2)
     (let ([true (gensym ".iftrue")]
           [false (gensym ".iffalse")]
           [endif (gensym ".endif")])
       (seq (compile-pred p lenv true false)
            (Label true)
            (compile-stat* s1 lenv)
            (Brl endif)
            (Label false)
            (compile-stat* s2 lenv)
            (Label endif)))]
    [(While p ss)
     (let ([loop (gensym ".loop")]
           [true (gensym ".looptrue")]
           [done (gensym ".loopdone")])
       (seq (Label loop)
            (compile-pred p lenv true done)
            (Label true)
            (compile-stat* ss lenv)
            (Brl loop)
            (Label done)))]
    [(Cond cs)
     (let ([done (gensym ".conddone")])
       (seq (foldr (match-lambda**
                     [((If p ss) acc)
                      (let ([true (gensym ".condtrue")]
                            [next (gensym ".condnext")])
                        (seq (compile-pred p lenv true done)
                             (Label true)
                             (compile-stat* ss lenv)
                             (Jsl done)
                             (Label next)
                             acc))])
                   '()
                   cs)
            (Label done)))]
    [(Assign id e)
     (seq (compile-expr e lenv)
          (cond
            [(lookup-type id lenv)
             (let ([offset (lookup-local id lenv)])
               (case (lookup-type id lenv)
                 [(void) '()]
                 [(long)
                  ; to use stack addrsssing, need to send X to A
                  (seq (Sta (Stk offset))
                       (Sep (Imm8 #x20))
                       (Txa)
                       (Sta (Stk (+ 2 offset)))
                       (Rep (Imm8 #x20)))]
                 [(byte)
                  (seq (Sep (Imm8 #x20)) (Sta (Stk offset)) (Rep (Imm8 #x20)))]
                 [(word) (Sta (Stk offset))]))]
            [(lookup-type id globs)
             (case (lookup-type id globs)
               [(void) '()]
               [(long)
                (seq (Sta (Abs (symbol->label id)))
                     (Stx (Abs (string-append (symbol->label id) "+2"))))]
               [(byte) (seq (Tax) (Stx (Abs (symbol->label id))))]
               [(word) (Sta (Abs (symbol->label id)))])]
            [else (error "Assignment invalid")]))]
    [(Increment id)
     (cond
       [(lookup-type id lenv)
        (let ([offset (lookup-local id lenv)])
          (case (lookup-type id lenv)
            [(byte)
             (seq (Sep (Imm8 #x20))
                  (Lda (Stk offset))
                  (Inc)
                  (Sta (Stk offset))
                  (Rep (Imm8 #x20)))]
            [(word) (seq (Lda (Stk offset)) (Inc) (Sta (Stk offset)))]))]
       ; can we ensure global variables of type int can always work with abs?
       [(lookup-type id globs)
        (case (lookup-type id globs)
          [(byte)
           (seq (Sep (Imm8 #x20))
                (Inc (Abs (symbol->label id)))
                (Rep (Imm8 #x20)))]
          [(word) (Inc (Abs (symbol->label id)))])])]
    [(Decrement id)
     (cond
       [(lookup-type id lenv)
        (let ([offset (lookup-local id lenv)])
          (case (lookup-type id lenv)
            [(byte)
             (seq (Sep (Imm8 #x20))
                  (Lda (Stk offset))
                  (Dec)
                  (Sta (Stk offset))
                  (Rep (Imm8 #x20)))]
            [(word) (seq (Lda (Stk offset)) (Dec) (Sta (Stk offset)))]))]
       ; can we ensure global variables of type int can always work with abs?
       [(lookup-type id globs)
        (case (lookup-type id globs)
          [(byte)
           (seq (Sep (Imm8 #x20))
                (Dec (Abs (symbol->label id)))
                (Rep (Imm8 #x20)))]
          [(word) (Dec (Abs (symbol->label id)))])])]
    [(ZeroOut id)
     (cond
       [(lookup-type id lenv)
        (let ([offset (lookup-local id lenv)])
          (case (lookup-type id lenv)
            [(byte)
             (seq (Sep (Imm8 #x20))
                  (Lda (Imm8 0))
                  (Sta (Stk offset))
                  (Rep (Imm8 #x20)))]
            [(word) (seq (Lda (Imm 0)) (Sta (Stk offset)))]))]
       ; can we ensure global variables of type int can always work with abs?
       [(lookup-type id globs)
        (case (lookup-type id globs)
          [(byte)
           (seq (Sep (Imm8 #x20))
                (Stz (Abs (symbol->label id)))
                (Rep (Imm8 #x20)))]
          [(word) (Stz (Abs (symbol->label id)))])])]
    [(Local bs ss)
     (seq (move-stack (- (length-local bs))) ; allocate
          (compile-stat* ss (append (reverse bs) lenv)) ; inner statements
          (move-stack (length-local bs)))] ; deallocate
    ; note the use of `length-local` is a bit different from how it was
    ; originally designed
    [(Native as) (map (lambda (a) (Code a)) as)]
    [_ (error "not a statement")]))

(define (compile-expr expr lenv)
  (match expr
    [(Int i) (compile-int i)]
    [(Void) '()]
    [(Call id as) (compile-call id as lenv)]
    [(Var id)
     (cond
       [(lookup-type id lenv)
        (let ([offset (lookup-local id lenv)])
          (case (lookup-type id lenv)
            [(void) '()]
            [(long)
             (seq (Sep (Imm8 #x20))
                  (Lda (Stk (+ 2 offset)))
                  (Tax) ; x 8 bits
                  (Rep (Imm8 #x20))
                  (Lda (Stk offset)))]
            [(byte)
             (seq (Sep (Imm8 #x20)) (Lda (Stk offset)) (Rep (Imm8 #x20)))]
            [(word) (Lda (Stk offset))]))]
       [(lookup-type id globs)
        (case (lookup-type id globs)
          [(void) '()]
          [(long)
           (seq (Lda (Abs (symbol->label id)))
                (Stx (Abs (string-append (symbol->label id) "+2"))))]
          [(byte) (seq (Lda (Abs (symbol->label id))) (And (Imm #x00FF)))]
          [(word) (Lda (Abs (symbol->label id)))])]
       [(lookup-type id consts)
        (case (lookup-type id consts)
          [(void) '()]
          [(long)
           (seq (Lda (Imm id)) (Ldx (Imm8 (string-append "<:" (~a id)))))]
          [(byte word) (Lda (Imm id))])]
       ; need to ensure the constant is small enough for byte
       ; (I don't think this is actually used yet)
       [else (error "Variable invalid")])]
    [(IntOp1 op e)
     (seq (compile-expr e lenv)
          (match op
            ['<< (Asl (Acc 1))]
            ['>> (Lsr (Acc 1))]
            ['1+ (Inc (Acc 1))]
            ['1- (Dec (Acc 1))]
            ['bit-not (Eor (Acc #xFFFF))]))]
    [(IntOp2 op e1 e2)
     (match e2
       ; =============================
       ; CONSTANT FOLDING OPTIMIZATION
       ; =============================
       [(Int n)
        (seq (compile-expr e1 lenv)
             (match op
               ['+ (seq (Clc) (Adc (Imm n)))]
               ['- (seq (Sec) (Sbc (Imm n)))]
               ['bit-or (Ora (Imm n))]
               ['bit-and (And (Imm n))]
               ['bit-eor (Eor (Imm n))]))]
       [_ ; second argument not optimized
        (seq (compile-expr e2 lenv)
             (Sta (Zp 0))
             (compile-expr e1 lenv)
             (match op
               ['+ (seq (Clc) (Adc (Zp 0)))]
               ['- (seq (Sec) (Sbc (Zp 0)))]
               ['bit-or (Ora (Zp 0))]
               ['bit-and (And (Zp 0))]
               ['bit-eor (Eor (Zp 0))]))])]
    [(Ternary p e1 e2)
     (let ([true (gensym ".terntrue")]
           [false (gensym ".ternfalse")]
           [endif (gensym ".endtern")])
       (seq (compile-pred p lenv true false)
            (Label true)
            (compile-expr e1 lenv)
            (Brl endif)
            (Label false)
            (compile-expr e2 lenv)
            (Label endif)))]))

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
         (set! lenv (cons `(#f . ,type) lenv))
         (seq code
              (case type
                [(void) '()]
                [(long) (seq (Phx) (Pha))]
                [(byte) (seq (Tax) (Phx))]
                [(word) (Pha)]))))
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
                   (Sta (Zp 0))
                   (move-stack alloc-size)
                   (Tyx)
                   (Lda (Zp 0)))]
             [(byte)
              (seq (Sta (Zp 0))
                   (move-stack alloc-size)
                   (Lda (Zp 0))
                   (And (Imm #x00FF)))] ; zero out high byte if there is
             ; additional stuff here (see note)
             [(word)
              (seq (Sta (Zp 0)) (move-stack alloc-size) (Lda (Zp 0)))]))))))

(define (compile-pred p lenv true false)
  (match p
    [(True) (Brl true)]
    [(False) (Brl false)]
    [(BoolOp1 op p) (compile-pred (BoolOp1 op p) lenv false true)]
    [(BoolOp2 op p1 p2)
     (match op
       ['and
        (let ([second (gensym ".predand")])
          (seq (compile-pred p1 lenv second false)
               (Label second)
               (compile-pred p2 lenv true false)))]
       ['or
        (let ([second (gensym ".predor")])
          (seq (compile-pred p1 lenv true second)
               (Label second)
               (compile-pred p2 lenv true false)))])]
    [(CompOp1 op e)
     (seq (compile-expr e lenv)
          (match op
            ['zero? (Beq true)]
            ['nonzero? (Bne true)]
            ['nonneg? (Bpl true)]
            ['neg? (Bmi true)])
          (Brl false))]
    [(CompOp2 op e1 e2)
     (seq (case op
            [(= != > <=)
             (seq (compile-expr e1 lenv) (Sta (Zp 0)) (compile-expr e2 lenv))]
            [(< >=)
             (seq (compile-expr e2 lenv) (Sta (Zp 0)) (compile-expr e1 lenv))])
          ; ALERT! COMPARISONS ARE UNSIGNED!!!
          ; OH NO... SIGNED AND UNSIGNED TYPES??
          (Cmp (Zp 0)) ; no longer compare on the stack
          (case op
            [(=) (Beq true)]
            [(!=) (Bne true)]
            [(< >) (Bcc true)]
            [(>= <=) (Bcs true)])
          (Brl false))]))

(define (make-global-list globals)
  (seq (Org "$7E0010") ; hardcoded start of global area
       (flatten (map (match-lambda
                       [(Global id t) (Skip (symbol->label id) (type->size t))]
                       [_ '()])
                     globals))))

(define (make-include-list progs)
  (seq (Org "$C10000") ; hardcoded start of data
       (flatten (map (match-lambda
                       [(Include id file)
                        (seq (Label (symbol->label id)) (Incbin file))]
                       [_ '()])
                     progs))))
; note to self, don't lie about how large the ROM is in the header,
; maybe?

(define (make-array-list progs)
  (seq (Org "$7E2000") ; hardcoded start of data
       (flatten
        (map (match-lambda
               [(Array id t l) (Skip (symbol->label id) (* (type->size t) l))]
               [_ '()])
             progs))))

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
