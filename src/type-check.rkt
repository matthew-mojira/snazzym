#lang racket

(provide type-check)
(require "ast.rkt"
         "65816.rkt"
         "func.rkt"
         "global.rkt")

(define (type-check prog)
  (let ([funcs (extract-funcs prog)] [globs (extract-globs prog)])
    (for ([p prog])
      (type-check-top-level p funcs globs))))

(define (type-check-top-level prog funcs globs)
  (match prog
    [(Func _ t bs ss) (type-check-stat* ss t funcs globs (reverse bs))]
    [(Global _ 'void) (error "Variable defined of type void")]
    ; hackfix!!
    [_ #t]))

(define (type-check-stat* ss type funcs globs locals)
  (for ([s ss])
    (type-check-stat s type funcs globs locals)))

(define (type-check-stat stat type funcs globs locals)
  (match stat
    [(Return e) (type-check-expr e type funcs globs locals)]
    [(If e ss)
     (begin
       (type-check-expr e 'bool funcs globs locals)
       (type-check-stat* ss type funcs globs locals))]
    [(IfElse e s1 s2)
     (begin
       (type-check-expr e 'bool funcs globs locals)
       (type-check-stat* s1 type funcs globs locals)
       (type-check-stat* s2 type funcs globs locals))]
    [(Call id es) (type-check-call id es funcs globs locals)]
    [(Assign id e)
     (type-check-expr e (typeof-var id globs locals) funcs globs locals)]
    [(Local bs ss)
     (type-check-stat* ss type funcs globs (append (reverse bs) locals))]
    [_ #t]))

(define (type-check-expr expr type funcs globs locals)
  (begin
    ; first, do type checking of any subexpressions
    (match expr
      [(Call id es) (type-check-call id es funcs globs locals)]
      [(BoolOp1 _ e) (type-check-expr e 'bool funcs globs locals)]
      [(BoolOp2 _ e1 e2)
       (begin
         (type-check-expr e1 'bool funcs globs locals)
         (type-check-expr e2 'bool funcs globs locals))]
      [(CompOp1 _ e) (type-check-expr e 'int funcs globs locals)]
      [(CompOp2 _ e1 e2)
       (begin
         (type-check-expr e1 'int funcs globs locals)
         (type-check-expr e2 'int funcs globs locals))]
      [(IntOp1 _ e) (type-check-expr e 'int funcs globs locals)]
      [(IntOp2 _ e1 e2)
       (begin
         (type-check-expr e1 'int funcs globs locals)
         (type-check-expr e2 'int funcs globs locals))]
      [_ #t])
    ; second, compare actual type of expression with expected
    (if (eq? (typeof-expr expr funcs globs locals) type)
        #t
        (error "Type error: expected"
               type
               "but got"
               (typeof-expr expr funcs globs locals)))))

(define (typeof-expr expr funcs globs locals)
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
    [(Var id) (typeof-var id globs locals)]
    [(Void) 'void]))

(define (type-check-call id es funcs globs locals)
  (match-let ([(Func _ _ as ss) (lookup-func id funcs)])
    (if (= (length as) (length es))
        (for ([a as] [e es])
          (type-check-expr e (cdr a) funcs globs locals))
        (error "Arity mismatch"))))

(define (typeof-var id globs locals)
  ; first, look up local variables
  ; second, look at global variables
  (let ([local (findf (lambda (x) (eq? (car x) id)) locals)])
    (if local
        (cdr local)
        (match (findf (match-lambda
                        [(Global idg t) (if (eq? id idg) t #f)]
                        [_ #f])
                      globs)
          [(Global _ t) t]
          [_ (error "Failed lookup")]))))
