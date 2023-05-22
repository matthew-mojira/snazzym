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
    [(Global _ 'void) (error "Variable defined of type void")]
    ; hackfix!!
    [_ #t]))

(define (type-check-stat* ss type locals)
  (for ([s ss])
    (type-check-stat s type locals)))

(define (type-check-stat stat type locals)
  (match stat
    [(Return e) (type-check-expr e type locals)]
    [(If e ss)
     (type-check-expr e 'bool locals)
     (type-check-stat* ss type locals)]
    [(IfElse e s1 s2)
     (type-check-expr e 'bool locals)
     (type-check-stat* s1 type locals)
     (type-check-stat* s2 type locals)]
    [(Call id es) (type-check-call id es locals)]
    [(Assign id e) (type-check-expr e (typeof-var id locals) locals)]
    [(Local bs ss) (type-check-stat* ss type (append (reverse bs) locals))]
    ; bug: can define variables of type void locally
    [(While e ss)
     (type-check-expr e 'bool locals)
     (type-check-stat* ss type locals)]
    [_ #t]))

(define (type-check-expr expr type locals)
  (begin
    ; first, do type checking of any subexpressions
    (match expr
      [(Call id es) (type-check-call id es locals)]
      [(BoolOp1 _ e) (type-check-expr e 'bool locals)]
      [(BoolOp2 _ e1 e2)
       (type-check-expr e1 'bool locals)
       (type-check-expr e2 'bool locals)]
      [(CompOp1 _ e) (type-check-expr e 'int locals)]
      [(CompOp2 _ e1 e2)
       (type-check-expr e1 'int locals)
       (type-check-expr e2 'int locals)]
      [(IntOp1 _ e) (type-check-expr e 'int locals)]
      [(IntOp2 _ e1 e2)
       (type-check-expr e1 'int locals)
       (type-check-expr e2 'int locals)]
      [_ #t])
    ; second, compare actual type of expression with expected
    (if (eq? (typeof-expr expr locals) type)
        #t
        (error (string-append "Type error: expected "
                              (~a type)
                              " but got "
                              (~a (typeof-expr expr locals)))))))

(define (typeof-expr expr locals)
  (match expr
    [(Int _) 'int]
    [(Bool _) 'bool]
    [(BoolOp1 _ _) 'bool]
    [(BoolOp2 _ _ _) 'bool]
    [(CompOp1 _ _) 'bool]
    [(CompOp2 _ _ _) 'bool]
    [(IntOp1 _ _) 'int]
    [(IntOp2 _ _ _) 'int]
    [(Call id es) (match-let ([(Func _ t _ _) (lookup-func id funcs)]) t)]
    [(Var id) (typeof-var id locals)]
    [(Void) 'void]))

(define (type-check-call id es locals)
  (match (lookup-func id funcs)
    [(Func _ _ as ss)
     (if (= (length as) (length es))
         (for ([a as] [e es])
           (type-check-expr e (cdr a) locals))
         (error "Arity mismatch"))]
    [_ (error "Unrecognized function:" id)]))

(define (typeof-var id locals)
  (cond
    [(lookup-type id locals)]
    [(lookup-type id globs)]
    [(lookup-type id consts)]
    [else (error "Failed lookup:" id)]))
