#lang racket

(provide compile)
(require "ast.rkt"
         "65816.rkt"
         "types.rkt"
         "local.rkt"
         "global.rkt")

(define g-env '())

(define (compile progs)
  (set! g-env (extract-global-env progs))
  (seq (Pushpc)
       (make-global-list progs)
       (make-include-list progs)
       (make-array-list progs)
       (Pullpc)
       (make-enum-list progs)
       (flatten (map compile-top-level progs))))

; todo make this make-func-list instead like the above!
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
    [(Call id-e as) (compile-call id-e as lenv)]
    [(Return expr)
     (seq (compile-expr expr lenv)
          ; need to deallocate any remaining local variables bound
          (let ([alloc-size (local-size lenv)])
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
                        (seq (compile-pred p lenv true next)
                             (Label true)
                             (compile-stat* ss lenv)
                             (Brl done)
                             (Label next)
                             acc))])
                   '()
                   cs)
            (Label done)))]
    [(Assign id e)
     ; by assumption `id` is the name of a valid variable
     ; unlike array-set! where the name can be an expression evaluating to the
     ; pointer
     ; it may be global or local
     (seq (compile-expr e lenv)
          ; accumulator/registers will have value
          (if (lookup-type id lenv)

              (match (lookup-type id lenv)
                ['void '()]
                [(or 'long (list 'array _) (list 'func _ _))
                 ; all pointer types
                 (let ([offset (local-offset id lenv)])
                   ; to use stack addrsssing, need to send X to A
                   (seq (Sta (Stk offset))
                        (Sep (Imm8 #x20))
                        (Txa)
                        (Sta (Stk (+ 2 offset)))
                        (Rep (Imm8 #x20))))]
                ['byte
                 (let ([offset (local-offset id lenv)])
                   (seq (Sep (Imm8 #x20))
                        (Sta (Stk offset)) ; store
                        (Rep (Imm8 #x20))))]
                [(or 'word (list 'enum _))
                 (let ([offset (local-offset id lenv)]) (Sta (Stk offset)))])

              (match (lookup-type id g-env)
                ['void '()]
                [(or 'long (list 'array _) (list 'func _ _))
                 ; all pointer types
                 (seq (Sta (Abs (symbol->label id)))
                      (Stx (Abs (string-append (symbol->label id) "+2"))))]
                ['byte (seq (Tax) (Stx (Abs (symbol->label id))))]
                [(or 'word (list 'enum _)) (Sta (Abs (symbol->label id)))])))]

    [(Increment id)
     (if (lookup-type id lenv)
         (match (lookup-type id lenv)
           ['byte
            (let ([offset (local-offset id lenv)])
              (seq (Sep (Imm8 #x20))
                   (Lda (Stk offset))
                   (Inc (Acc 1))
                   (Sta (Stk offset))
                   (Rep (Imm8 #x20))))]
           ['word
            (let ([offset (local-offset id lenv)])
              (seq (Lda (Stk offset))
                   (Inc (Acc 1)) ;inc
                   (Sta (Stk offset))))])

         (match (lookup-type id g-env)
           ['byte
            (seq (Sep (Imm8 #x20))
                 (Inc (Abs (symbol->label id)))
                 (Rep (Imm8 #x20)))]
           ['word (Inc (Abs (symbol->label id)))]))]

    [(Decrement id)
     (if (lookup-type id lenv)
         (match (lookup-type id lenv)
           ['byte
            (let ([offset (local-offset id lenv)])
              (seq (Sep (Imm8 #x20))
                   (Lda (Stk offset))
                   (Dec (Acc 1))
                   (Sta (Stk offset))
                   (Rep (Imm8 #x20))))]
           ['word
            (let ([offset (local-offset id lenv)])
              (seq (Lda (Stk offset))
                   (Dec (Acc 1)) ;dec
                   (Sta (Stk offset))))])

         (match (lookup-type id g-env)
           ['byte
            (seq (Sep (Imm8 #x20))
                 (Dec (Abs (symbol->label id)))
                 (Rep (Imm8 #x20)))]
           ['word (Dec (Abs (symbol->label id)))]))]

    [(ZeroOut id)
     (if (lookup-type id lenv)
         (match (lookup-type id lenv)
           ['byte
            (let ([offset (local-offset id lenv)])
              (seq (Sep (Imm8 #x20))
                   (Lda (Imm8 0))
                   (Sta (Stk offset))
                   (Rep (Imm8 #x20))))]
           ['word
            (let ([offset (local-offset id lenv)])
              (seq (Lda (Imm 0)) ;load 0
                   (Sta (Stk offset))))])

         (match (lookup-type id g-env)
           ['byte
            (seq (Sep (Imm8 #x20))
                 (Stz (Abs (symbol->label id)))
                 (Rep (Imm8 #x20)))]
           ['word (Stz (Abs (symbol->label id)))]))]

    [(Local bs ss)
     (seq (move-stack (- (local-size bs))) ; allocate
          (compile-stat* ss (append (reverse bs) lenv)) ; inner statements
          (move-stack (local-size bs)))] ; deallocate
    ; note the use of `local-size` is a bit different from how it was
    ; originally designed
    [(Native as) (map (lambda (a) (Code a)) as)]
    [(ArraySet a-e i e)
     ; evaluation orders are
     ; const array: i -> e
     ; non-const: i -> e -> a-e
     (match (typeof-expr a-e (append lenv g-env))
       [(list 'array r)
        (match r
          ['byte
           (seq (compile-expr i lenv)
                (Pha) ; push offset
                (compile-expr e (cons '(#f . word) lenv))
                ; accumulator has data to put
                (Tax)
                (Phx)
                (compile-expr a-e (append '((#f . byte) (#f . word)) lenv))
                ; accumulator has address of array
                (Sta (Zp 0))
                (Stx (Zp 2))
                (Sep (Imm8 #x20)) ; 8-bit A, 16-bit XY
                (Rep (Imm8 #x10)) ; in the future: small offsets can be 8-bit
                (Pla) ; data to put
                (Ply) ; offset
                (Sta (ZpIndY 0)) ; STORE!
                (Rep (Imm8 #x20))
                (Sep (Imm8 #x10)))]
          [(or 'word (list 'enum _))
           (seq (compile-expr i lenv)
                (Asl (Acc 1)) ; 2 bytes
                (Pha) ; push offset
                (compile-expr e (cons '(#f . word) lenv))
                ; accumulator has data to put
                (Pha)
                (compile-expr a-e (append '((#f . word) (#f . word)) lenv))
                ; accumulator has address of array
                (Sta (Zp 0))
                (Stx (Zp 2))
                (Rep (Imm8 #x10)) ; 16-bit XY
                (Pla) ; data to put
                (Ply) ; offset
                (Sta (ZpIndY 0)) ; STORE!
                (Sep (Imm8 #x10)))]
          [(or 'long (list 'array _) (list 'func _ _))
           (seq (compile-expr i lenv)
                (Sta (Zp 0))
                (Asl (Acc 1))
                (Clc) ; may not be necessary given above line
                (Adc (Zp 0)) ; 3 bytes
                (Pha) ; push offset
                (compile-expr e (cons '(#f . word) lenv))
                (Phx)
                (Pha)
                (compile-expr a-e (append '((#f . long) (#f . word)) lenv))
                ; accumulator has address of array
                (Sta (Zp 0))
                (Stx (Zp 2))
                (Pla) ; data to put
                (Plx) ; bank byte
                (Rep (Imm8 #x10)) ; 16-bit XY
                (Ply) ; offset
                (Sta (ZpIndY 0)) ; STORE!
                (Sep (Imm8 #x20)) ; 8-bit A
                (Iny (Acc 2)) ; bank byte address
                (Txa)
                (Sta (ZpIndY 0)) ; STORE!
                (Rep (Imm8 #x20))
                (Sep (Imm8 #x10)))])]
       [(list 'const 'array r)
        (match r
          ['byte
           (seq (compile-expr i lenv)
                (Pha) ; push offset
                (compile-expr e (cons '(#f . word) lenv))
                ; accumulator has data to put
                (Rep (Imm8 #x10))
                (Plx)
                (Sep (Imm8 #x20))
                (Sta (LongX (const-var->label a-e)))
                (Rep (Imm8 #x20))
                (Sep (Imm8 #x10)))]
          [(or 'word (list 'enum _))
           (seq (compile-expr i lenv)
                (Asl (Acc 1)) ; 2 bytes
                (Pha) ; push offset
                (compile-expr e (cons '(#f . word) lenv))
                ; accumulator has data to put
                (Rep (Imm8 #x10))
                (Plx)
                (Sta (LongX (const-var->label a-e)))
                (Sep (Imm8 #x10)))]
          [(or 'long (list 'array _) (list 'func _ _))
           (seq (compile-expr i lenv)
                (Sta (Zp 0))
                (Asl (Acc 1))
                (Clc) ; may not be necessary given above line
                (Adc (Zp 0)) ; 3 bytes
                (Pha) ; push offset
                (compile-expr e (cons '(#f . word) lenv))
                (Txy) ; Y <- bank
                (Rep (Imm8 #x10))
                (Plx) ; offset
                (Sta (LongX (const-var->label a-e)))
                (Sep (Imm8 #x20))
                (Tya) ; A <- bank
                (Sta (LongX (string-append (const-var->label a-e) "+2")))
                (Rep (Imm8 #x20))
                (Sep (Imm8 #x10)))])])
     ;
     ]))

(define (compile-expr expr lenv)
  (match expr
    [(Int i) (compile-int i)]
    [(Void) '()]
    [(Call id-e as) (compile-call id-e as lenv)]
    [(Var id)
     (if (lookup-type id lenv)

         (match (lookup-type id lenv)
           ['void '()]
           [(or 'long (list 'array _) (list 'func _ _))
            ; all pointer types
            (let ([offset (local-offset id lenv)])
              (seq (Sep (Imm8 #x20))
                   (Lda (Stk (+ 2 offset)))
                   (Tax) ; x 8 bits
                   (Rep (Imm8 #x20))
                   (Lda (Stk offset))))]
           ['byte
            (let ([offset (local-offset id lenv)])
              (seq (Lda (Stk offset)) ;load
                   (And (Imm #x00FF))))]
           [(or 'word (list 'enum _))
            (let ([offset (local-offset id lenv)]) (Lda (Stk offset)))]) ;load

         (match (lookup-type id g-env)
           [(cons 'const r)
            (match r
              ['void '()]
              [(or 'long (list 'array _) (list 'func _ _))
               ; all pointer types
               (seq (Lda (Imm (symbol->label id)))
                    (Ldx (Imm8 (string-append "<:" (symbol->label id)))))]
              ; hopefully it puts in the 0s for us in the byte case
              [(or 'byte 'word) (Lda (Imm (symbol->label id)))]
              [(list 'enum name)
               ; make into its own helper function?
               (Lda (Imm (string-append "!"
                                        (symbol->label name)
                                        "_"
                                        (symbol->label id))))])]
           [r
            (match r
              ['void '()]
              [(or 'long (list 'array _) (list 'func _ _))
               ; all pointer types
               (seq (Lda (Abs (symbol->label id)))
                    (Ldx (Abs (string-append (symbol->label id) "+2"))))]
              ['byte (seq (Lda (Abs (symbol->label id))) (And (Imm #x00FF)))]
              [(or 'word (list 'enum _)) (Lda (Abs (symbol->label id)))])]))]

    [(IntOp1 op e)
     (seq (compile-expr e lenv)
          (match op
            ['<< (Asl (Acc 1))]
            ['>> (Lsr (Acc 1))]
            ['1+ (Inc (Acc 1))]
            ['1- (Dec (Acc 1))]
            ['bit-not (Eor (Acc #xFFFF))]))]
    [(IntOp2 op e1 e2)
     ; todo
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
             (Pha)
             (compile-expr e1 (cons `(#f . word) lenv))
             (match op
               ['+ (seq (Clc) (Adc (Stk 1)))]
               ['- (seq (Sec) (Sbc (Stk 1)))]
               ['bit-or (Ora (Stk 1))]
               ['bit-and (And (Stk 1))]
               ['bit-eor (Eor (Stk 1))])
             (Sta (Zp 0))
             (Pla)
             (Lda (Zp 0)))])]
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
            (Label endif)))]
    [(ArrayGet a-e i)
     (match (typeof-expr a-e (append lenv g-env))
       [(list 'array r)
        (match r
          ['byte
           (seq (compile-expr i lenv)
                (Pha) ; push offset
                (compile-expr a-e (cons '(#f . word) lenv))
                ; accumulator has address of array
                (Sta (Zp 0))
                (Stx (Zp 2))
                (Rep (Imm8 #x10)) ; in the future: small offsets can be 8-bit
                (Ply) ; offset
                (Lda (ZpIndY 0)) ; LOAD!
                (And (Imm #x00FF))
                (Sep (Imm8 #x10)))]
          [(or 'word (list 'enum _))
           (seq (compile-expr i lenv)
                (Asl (Acc 1)) ; 2 bytes
                (Pha) ; push offset
                (compile-expr a-e (cons '(#f . word) lenv))
                ; accumulator has address of array
                (Sta (Zp 0))
                (Stx (Zp 2))
                (Rep (Imm8 #x10)) ; 16-bit XY
                (Ply) ; offset
                (Lda (ZpIndY 0)) ; LOAD!
                (Sep (Imm8 #x10)))]
          [(or 'long (list 'array _) (list 'func _ _))
           (seq (compile-expr i lenv)
                (Sta (Zp 0))
                (Asl (Acc 1))
                (Clc) ; may not be necessary given above line
                (Adc (Zp 0)) ; 3 bytes
                (Inc (Acc 2)) ; get bank byte first
                (Pha) ; push offset
                (compile-expr a-e (cons '(#f . word) lenv))
                ; accumulator has address of array
                (Sta (Zp 0))
                (Stx (Zp 2))
                (Rep (Imm8 #x10)) ; 16-bit XY
                (Ply) ; offset
                (Lda (ZpIndY 0)) ; LOAD! (bank byte)
                (Tax) ; X <- bank byte
                (Dey (Acc 2)) ; offset of rest
                (Lda (ZpIndY 0)) ; LOAD! (lower 16)
                (Rep (Imm8 #x20))
                (Sep (Imm8 #x10)))])]
       [(list 'const 'array r)
        (match r
          ['byte
           (seq (compile-expr i lenv)
                (Rep (Imm8 #x10))
                (Tax)
                (Lda (LongX (const-var->label a-e)))
                (And (Imm #x00FF))
                (Sep (Imm8 #x10)))]
          [(or 'word (list 'enum _))
           (seq (compile-expr i lenv)
                (Asl (Acc 1)) ; 2 bytes
                (Rep (Imm8 #x10))
                (Tax)
                (Lda (LongX (const-var->label a-e)))
                (Sep (Imm8 #x10)))]
          [(or 'long (list 'array _) (list 'func _ _))
           (seq (compile-expr i lenv)
                (Sta (Zp 0))
                (Asl (Acc 1))
                (Clc) ; may not be necessary given above line
                (Adc (Zp 0)) ; 3 bytes
                (Rep (Imm8 #x10))
                (Tax) ; offset
                (Lda (LongX (string-append (const-var->label a-e) "+2")))
                (Tay)
                (Lda (LongX (const-var->label a-e)))
                (Tyx)
                (Sep (Imm8 #x10)))])])]
    ;;
    ))

(define (compile-int int)
  (Lda (Imm int)))

; note to self: should also make a compile-call version when the call is a
; statement, because then we are safe to throw away the return value during
; the deallocation process
(define (compile-call f-e as lenv)
  (match (extract-const (typeof-expr f-e (append lenv g-env)))
    [(list 'func ret args)
     ; push args to the stack
     (seq
      (for/list ([a as] [t args])
        (let ([code (compile-expr a lenv)])
          (set! lenv (cons `(#f . ,t) lenv))
          (seq code
               (match t
                 ['void '()]
                 ; all pointer types
                 [(or 'long (list 'array _) (list 'func _ _)) (seq (Phx) (Pha))]
                 [(or 'word (list 'enum _)) (Pha)]
                 ['byte (seq (Tax) (Phx))]))))
      ; function call
      (if (constant-type? (typeof-expr f-e (append lenv g-env)))
          (Jsl (const-var->label f-e))
          ; non-constant -- need to:
          ; -> push return address
          ; -> resolve effective address
          ; -> jump
          (let ([ret (gensym ".call_ret")])
            (seq (Phk)
                 (Per (string-append (~a ret) "-1"))
                 (compile-expr f-e (cons '(#f . long) lenv))
                 (Sta (Zp 0))
                 (Stx (Zp 2))
                 (Jml (AbsInd 0)) ; jump!
                 (Label ret))))
      ; save return value and deallocate arguments
      (let ([alloc-size (local-size-types-only args)])
        (if (empty? as)
            '() ; no need to deallocate
            (match ret
              ['void (move-stack alloc-size)] ; no need to save
              [(or 'long (list 'array _) (list 'func _ _))
               (seq (Txy)
                    (Sta (Zp 0))
                    (move-stack alloc-size)
                    (Tyx)
                    (Lda (Zp 0)))]
              ['byte
               (seq (Sta (Zp 0))
                    (move-stack alloc-size)
                    (Lda (Zp 0))
                    (And (Imm #x00FF)))] ; zero out high byte if there is
              ; additional stuff here (see note)
              [(or 'word (list 'enum _))
               (seq (Sta (Zp 0)) (move-stack alloc-size) (Lda (Zp 0)))]))))]))

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
     ; ALERT! COMPARISONS ARE UNSIGNED!!!
     (seq (case op
            [(> <=)
             (seq (compile-expr e1 lenv)
                  (Pha)
                  (compile-expr e2 (cons `(#f . word) lenv))
                  (Cmp (Stk 1))
                  (Pla))] ; pull will not clobber carry
            [(< >=)
             (match e2
               ; CONSTANT FOLDING OPTIMIZATION
               ; todo
               [(Int i) (seq (compile-expr e1 lenv) (Cmp (Imm i)))]
               [_
                (seq (compile-expr e2 lenv)
                     (Pha)
                     (compile-expr e1 (cons `(#f . word) lenv))
                     (Cmp (Stk 1))
                     (Pla))])] ; pull will not clobber carry
            [(= !=)
             (match e2
               ; CONSTANT FOLDING OPTIMIZATION
               ; todo
               [(Int i) (seq (compile-expr e1 lenv) (Cmp (Imm i)))]
               [_
                (seq (compile-expr e2 lenv)
                     (Pha)
                     (compile-expr e1 (cons `(#f . word) lenv))
                     (Sta (Zp 0))
                     (Pla)
                     (Cmp (Zp 0)))])])
          ; strategy: pull off stack will clobber zero flag, so
          ; instead we get it off the stack first, then do the
          ; compare
          (case op
            [(=) (Beq true)]
            [(!=) (Bne true)]
            [(< >) (Bcc true)]
            [(>= <=) (Bcs true)])
          (Brl false))]))

; todo figure out the bototm

(define (make-global-list globals)
  (seq (Org "$7E0010") ; hardcoded start of global area
       (Comment "global variables:")
       (flatten (map (match-lambda
                       [(Global id t) (Skip (symbol->label id) (type->size t))]
                       [_ '()])
                     globals))
       (Warnpc "$7E17FF")))

(define (make-include-list progs)
  (seq (Org "$C10000") ; hardcoded start of data
       (Comment "file inclusions:")
       (flatten (map (match-lambda
                       [(Include id file)
                        (seq (Label (symbol->label id)) (Incbin file))]
                       [_ '()])
                     progs))))
; note to self, don't lie about how large the ROM is in the header,
; maybe?

(define (make-array-list progs)
  (seq (Org "$7E2000") ; hardcoded start of data
       (Comment "array list:")
       (flatten (map (match-lambda
                       [(Array id t l)
                        (Skip (symbol->label id) (* (type->size t) l))]
                       [_ '()])
                     progs))
       (Warnpc "$7FFFFF")))

(define (make-enum-list progs)
  ;  (foldr (lambda (tl rest)
  ;           (match tl
  ;             [(Enum name ids)
  ;              (cons (map (lambda (id) (cons id `(enum ,name))) ids) rest)]
  ;             [_ rest]))
  ;         '()
  ;         prog))

  (seq (Comment "enum definitions")
       (flatten
        (map (match-lambda
               [(Enum name ids)
                (let ([offset -2])
                  (for/list ([id ids])
                    (set! offset (+ offset 2))
                    (DefnAsm
                     (string-append (symbol->label name) "_" (symbol->label id))
                     offset)))]
               [_ '()])
             progs))))

; this is inlined for every time it is called!
; idea: in certain places this could be *very* optimized
; preserving the regisets is up to the user
(define (move-stack bytes)
  (seq (Tsc) (Clc) (Adc (Imm bytes)) (Tcs)))

; replace anything not alphanumeric with _
(define (symbol->label id)
  (let ([chars (list "/" "-" "." "!" "$" "%" "&" "<" "=" ">" "^" "_" "~" "@")])
    (foldr (lambda (char str) (string-replace str char "_")) (~a id) chars)))

(define (const-var->label v)
  (match v
    [(Var id) (symbol->label id)]))
