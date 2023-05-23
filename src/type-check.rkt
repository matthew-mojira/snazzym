#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt"
         "types.rkt"
         "func.rkt"
         "global.rkt"
         "const.rkt")

(define globs '())
(define funcs '())
(define consts '())

(define (type-check prog)
  (set! globs (extract-globs prog))
  (set! funcs (extract-funcs prog))
  (set! consts (extract-consts prog))
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
    [(Call id es) (type-check-call id es locals)]
    [(Assign id e) (type-check-expr e (typeof-var-mut id locals) locals)]
    [(or (Increment id) (Decrement id) (ZeroOut id))
     (if (eq? (typeof-var-mut id locals) 'int)
         #t
         (error "Type error: operation not on an integer variable"))]
    [(Local bs ss) (type-check-stat* ss type (append (reverse bs) locals))]
    [(While p ss)
     (type-check-pred p locals)
     (type-check-stat* ss type locals)]
    [_ #t]))

(define (type-check-expr expr type locals)
  ; first, do type checking of any subexpressions
  (match expr
    [(Call id es) (type-check-call id es locals)]
    [(IntOp1 _ e) (type-check-expr e 'int locals)]
    [(IntOp2 _ e1 e2)
     (type-check-expr e1 'int locals)
     (type-check-expr e2 'int locals)]
    [(Ternary p e1 e2)
     (type-check-pred p locals)
     (type-check-expr e1 type locals)
     (type-check-expr e2 type locals)]
    [_ #t])
  ; second, compare actual type of expression with expected
  (if (eq? (typeof-expr expr locals) type)
      #t
      (error (string-append "Type error: expected "
                            (~a type)
                            " but got "
                            (~a (typeof-expr expr locals))))))

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

(define (typeof-expr expr locals)
  (match expr
    [(Int _) 'int]
    [(IntOp1 _ _) 'int]
    [(IntOp2 _ _ _) 'int]
    [(Call id es) (match-let ([(Func _ t _ _) (lookup-func id funcs)]) t)]
    [(Var id) (typeof-var id locals)]
    [(Void) 'void]
    [(Ternary _ e _) (typeof-expr e locals)]))
; assumption: both types of ternary operator are the same! (checked above)

(define (type-check-call id es locals)
  (match (lookup-func id funcs)
    [(Func _ _ as ss)
     (if (= (length as) (length es))
         (for ([a as] [e es])
           (type-check-expr e (cdr a) locals))
         (error "Arity mismatch: expected" (length as) "but got" (length es)))]
    [_ (error "Unrecognized function:" id)]))

(define (typeof-var id locals)
  (cond
    [(lookup-type id locals)]
    [(lookup-type id globs)]
    [(lookup-type id consts)]
    [else (error "Unrecognized identifier:" id)]))

(define (typeof-var-mut id locals)
  (cond
    [(lookup-type id locals)]
    [(lookup-type id globs)]
    [else (error "Unrecognized identifier:" id)]))
