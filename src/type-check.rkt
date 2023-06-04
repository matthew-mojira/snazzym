#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt"
         "types.rkt"
         "global.rkt" racket/pretty)

(define g-env '())

(define (type-check prog)
  (set! g-env (extract-global-env prog))
;  (pretty-print g-env)
  (for ([p prog])
    (type-check-top-level p)))

(define (type-check-top-level prog)
  (match prog
    [(Func _ t bs ss) (type-check-stat* ss t (reverse bs))]
    [_ #t]))

(define (type-check-stat* ss type locals)
  (for ([s ss])
    (type-check-stat s type locals)))

(define (type-check-stat stat type locals)
  (match stat
    [(Return e) (type-check-expr e type locals)]
    [(If p ss)
     (type-check-pred p locals)
     (type-check-stat* ss type locals)]
    [(IfElse p s1 s2)
     (type-check-pred p locals)
     (type-check-stat* s1 type locals)
     (type-check-stat* s2 type locals)]
    [(Cond cs)
     (for ([c cs]) ; the underlying type of c is an If, so use above check
       (type-check-stat c type locals))]
    [(Call id-e es) (type-check-call id-e es locals)]
    [(Assign id e)
     (let ([var-type (typeof-var id (append locals g-env))])
       (if (constant-type? var-type)
           (error "Type error: trying to assign to a constant")
           (type-check-expr e var-type locals)))]
    [(or (Increment id) (Decrement id) (ZeroOut id))
     (if (eq? (int-or-type (typeof-var id (append locals g-env))) 'int)
         #t
         (error "Type error: operation not on an integer variable" id))]
    [(Local bs ss) (type-check-stat* ss type (append (reverse bs) locals))]
    [(While p ss)
     (type-check-pred p locals)
     (type-check-stat* ss type locals)]
    [(ArraySet a-e i e)
     ; assert `a` is an array
     ; at this point, accept `a` can be an array of any type, only care that it
     ; is an array
     (type-check-expr a-e '(array any) locals)
     ; check the indexing is an integral expression
     (type-check-expr i 'int locals)
     ; check the type matches the array declaration
     ; (note: not the other way around, the type of the array is assumed to
     ; be the expected type which the expression must match)
     (type-check-expr
      e
      (extract-array-type (typeof-expr a-e (append locals g-env)))
      locals)]
    [_ #t]))

(define (type-check-expr expr type locals)
  ; first, do type checking of any subexpressions
  (match expr
    [(Call id-e es) (type-check-call id-e es locals)]
    [(IntOp1 _ e) (type-check-expr e 'int locals)]
    [(IntOp2 _ e1 e2)
     (type-check-expr e1 'int locals)
     (type-check-expr e2 'int locals)]
    [(Ternary p e1 e2)
     (type-check-pred p locals)
     (type-check-expr e1 type locals)
     (type-check-expr e2 type locals)]
    [(ArrayGet a ei)
     ; assert `a` is an array
     ; at this point, accept `a` can be an array of any type, only care that it
     ; is an array
     (type-check-expr a '(array any) locals)
     ; check `ei` is an integral expression (for indexing)
     (type-check-expr ei 'int locals)]
    [_ #t])
  ; second, compare actual type of expression with expected
  (if (types-match? type (typeof-expr expr (append locals g-env)))
      #t
      (error (string-append
              "Type mismatch: expected "
              (~v type)
              " but got "
              (~v (int-or-type (typeof-expr expr (append locals g-env))))
              ". Expression in question:"
              (~v expr)))))

(define (types-match? exp act)
  ; ignore if the type is const
  ; const really matters for assignment/compiler optimization
  (let ([act (extract-const act)])
    (match exp
      ['any #t]
      [(or 'byte 'word 'int)
       (case act
         [(byte word int) #t]
         [else #f])]
      ['long
       (match act
         ; okay here, will cast to const long (underlying pointer)
         [(list 'array _) #t]
         [(cons 'func _) #t]
         ['long #t]
         [_ #f])]
      [(list 'array t)
       (match act
         [(list 'array ta) (types-match? t ta)]
         [_ #f])]
      [(list 'func re pe)
       (match act
         [(list 'func ra pa) (and (types-match? re ra) (types-match? pe pa))]
         [_ #f])]
      [(cons t ts)
       (match act
         [(cons a as) (and (types-match? t a) (types-match? ts as))]
         [_ #f])]
      [exp (equal? exp act)])))

(define (type-check-pred pred locals)
  (match pred
    [(BoolOp1 _ p) (type-check-pred p locals)]
    [(BoolOp2 _ p1 p2)
     (type-check-pred p1 locals)
     (type-check-pred p2 locals)]
    [(CompOp1 _ e) (type-check-expr e 'int locals)]
    [(CompOp2 _ e1 e2)
     (type-check-expr e1 'int locals)
     (type-check-expr e2 'int locals)]
    [_ #t]))

(define (type-check-call id es locals)
  (type-check-expr id '(func any any) locals)
  (let ([t-args (extract-func-arg-types
                 (typeof-expr id (append locals g-env)))])
    (if (= (length t-args) (length es))
        (for ([a t-args] [e es])
          (type-check-expr e a locals))
        (error "Arity mismatch"))))

(define (int-or-type t)
  (match t
    [(or 'byte 'word) 'int]
    [(cons t ts) (cons (int-or-type t) (int-or-type ts))]
    [_ t]))
